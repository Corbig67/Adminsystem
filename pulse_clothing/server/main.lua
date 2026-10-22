ESX = nil

local ok, obj = pcall(function() return exports['es_extended']:getSharedObject() end)
if ok and obj then
    ESX = obj
else
    TriggerEvent('esx:getSharedObject', function(o) ESX = o end)
end

-- Offene Läden pro Spieler: { shop = Index, base = Skin, den der Spieler gerade besitzt, busy = bool }
local sessions = {}

local categoryById = {}
for _, cat in ipairs(Config.Categories) do categoryById[cat.id] = cat end

local function toInt(v)
    v = tonumber(v)
    if not v or v ~= v or v < -1 or v > 4096 then return nil end
    return math.floor(v)
end

local function copy(t)
    local out = {}
    for k, v in pairs(t or {}) do out[k] = v end
    return out
end

local function decode(str)
    if type(str) ~= 'string' or str == '' then return nil end
    local okDecode, data = pcall(json.decode, str)
    if okDecode and type(data) == 'table' then return data end
    return nil
end

local function shopCategories(shop)
    local list, allowed = {}, {}
    if shop.categories and #shop.categories > 0 then
        for _, id in ipairs(shop.categories) do
            if categoryById[id] then list[#list + 1] = id; allowed[id] = true end
        end
    else
        for _, cat in ipairs(Config.Categories) do list[#list + 1] = cat.id; allowed[cat.id] = true end
    end
    return list, allowed
end

local function priceOf(shop, cat)
    return (shop.prices and shop.prices[cat.id]) or cat.price
end

local function shopPrices(shop)
    local prices = {}
    for _, cat in ipairs(Config.Categories) do prices[cat.id] = priceOf(shop, cat) end
    return prices
end

local function getMoney(xPlayer)
    local cash, bank = xPlayer.getAccount('money'), xPlayer.getAccount('bank')
    return { cash = cash and cash.money or 0, bank = bank and bank.money or 0 }
end

local function isNearShop(source, shop)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return true end
    local coords = GetEntityCoords(ped)
    -- Ohne OneSync liefert der Server keine Position, dann wird nicht geprüft
    if coords.x == 0.0 and coords.y == 0.0 and coords.z == 0.0 then return true end
    return #(coords - shop.coords) <= Config.MaxDistance
end

-- Nur Kleidungs-Werte aus einem Skin (für Outfits)
local function clothesOf(skin)
    local clothes = {}
    for _, cat in ipairs(Config.Categories) do
        clothes[cat.d] = toInt(skin[cat.d]) or cat.min
        clothes[cat.t] = toInt(skin[cat.t]) or 0
    end
    return clothes
end

local function cleanName(name)
    if type(name) ~= 'string' then return nil end
    name = name:gsub('[%c<>]', ''):gsub('^%s+', ''):gsub('%s+$', '')
    if name == '' then return nil end
    if utf8.len(name) and utf8.len(name) > 24 then
        name = name:sub(1, utf8.offset(name, 25) - 1)
    elseif not utf8.len(name) then
        return nil
    end
    return name
end

-- Datenbank ----------------------------------------------------------------
local function loadSkin(identifier)
    return decode(MySQL.scalar.await('SELECT skin FROM users WHERE identifier = ?', { identifier }))
end

local function saveSkin(identifier, skin)
    MySQL.update.await('UPDATE users SET skin = ? WHERE identifier = ?', { json.encode(skin), identifier })
end

local function getOutfits(identifier)
    local rows = MySQL.query.await(
        "SELECT id, name, icons, DATE_FORMAT(created_at, '%d.%m.%Y') AS date FROM pulse_outfits WHERE identifier = ? ORDER BY id DESC",
        { identifier }
    ) or {}
    local list = {}
    for i, row in ipairs(rows) do
        list[i] = { id = row.id, name = row.name, date = row.date, icons = decode(row.icons) or {} }
    end
    return list
end

local function countOutfits(identifier)
    return MySQL.scalar.await('SELECT COUNT(*) FROM pulse_outfits WHERE identifier = ?', { identifier }) or 0
end

MySQL.ready(function()
    if not Config.AutoCreateTable then return end
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `pulse_outfits` (
            `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `identifier` VARCHAR(60)  NOT NULL,
            `name`       VARCHAR(24)  NOT NULL,
            `skin`       LONGTEXT     NOT NULL,
            `icons`      VARCHAR(255) NULL DEFAULT NULL,
            `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_identifier` (`identifier`)
        ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4
    ]])
end)

-- Callbacks ------------------------------------------------------------------
local function fail(cb, msg) cb({ ok = false, error = msg }) end

ESX.RegisterServerCallback('pulse_clothing:open', function(source, cb, shopIndex, clientSkin)
    local xPlayer = ESX.GetPlayerFromId(source)
    local shop = Config.Shops[tonumber(shopIndex) or 0]
    if not xPlayer or not shop then return fail(cb, 'Laden nicht gefunden') end
    if not isNearShop(source, shop) then return fail(cb, 'Du bist zu weit vom Laden entfernt') end

    -- Der gespeicherte Skin ist die Grundlage für die Preisberechnung
    local base = loadSkin(xPlayer.identifier)
    if not base then base = type(clientSkin) == 'table' and copy(clientSkin) or {} end

    sessions[source] = { shop = tonumber(shopIndex), base = base, busy = false }

    local categories = shopCategories(shop)
    cb({
        ok = true,
        data = {
            values     = base,
            money      = getMoney(xPlayer),
            outfits    = getOutfits(xPlayer.identifier),
            prices     = shopPrices(shop),
            categories = categories,
            title      = shop.title or Config.Title,
            pay        = Config.DefaultPay
        }
    })
end)

ESX.RegisterServerCallback('pulse_clothing:buy', function(source, cb, data)
    local xPlayer, session = ESX.GetPlayerFromId(source), sessions[source]
    if not xPlayer or not session then return fail(cb, 'Der Laden ist nicht geöffnet') end
    if session.busy then return fail(cb, 'Bitte warte kurz') end
    if type(data) ~= 'table' or type(data.values) ~= 'table' then return fail(cb, 'Ungültige Anfrage') end

    local shop = Config.Shops[session.shop]
    if not isNearShop(source, shop) then return fail(cb, 'Du bist zu weit vom Laden entfernt') end

    -- Warenkorb serverseitig aus der Differenz zum aktuellen Skin berechnen
    local _, allowed = shopCategories(shop)
    local newSkin, items, total = copy(session.base), {}, 0
    for _, cat in ipairs(Config.Categories) do
        if allowed[cat.id] then
            local d, t = toInt(data.values[cat.d]), toInt(data.values[cat.t])
            if d and t and d >= cat.min and t >= 0 then
                local bd, bt = toInt(session.base[cat.d]) or cat.min, toInt(session.base[cat.t]) or 0
                if d ~= bd or t ~= bt then
                    newSkin[cat.d], newSkin[cat.t] = d, t
                    items[#items + 1] = cat
                    total = total + priceOf(shop, cat)
                end
            end
        end
    end
    if #items == 0 then return fail(cb, 'Dein Warenkorb ist leer') end

    local outfitName
    if data.outfit ~= nil and data.outfit ~= false then
        outfitName = cleanName(data.outfit)
        if not outfitName then return fail(cb, 'Gib deinem Outfit einen Namen') end
    end

    session.busy = true
    local identifier = xPlayer.identifier

    if outfitName and countOutfits(identifier) >= Config.MaxOutfits then
        session.busy = false
        return fail(cb, ('Du kannst maximal %d Outfits speichern'):format(Config.MaxOutfits))
    end

    local account = data.method == 'bank' and 'bank' or 'money'
    local acc = xPlayer.getAccount(account)
    if not acc or acc.money < total then
        session.busy = false
        return fail(cb, account == 'bank' and 'Deine Karte wurde abgelehnt' or 'Du hast nicht genug Bargeld dabei')
    end

    xPlayer.removeAccountMoney(account, total, 'Kleidungsladen')
    saveSkin(identifier, newSkin)
    session.base = newSkin

    local result = { money = getMoney(xPlayer), skin = newSkin, total = total }

    if outfitName then
        local icons, seen = {}, {}
        for _, cat in ipairs(items) do
            if not seen[cat.icon] and #icons < 3 then icons[#icons + 1] = cat.icon; seen[cat.icon] = true end
        end
        for _, icon in ipairs({ 'jacket', 'pants', 'shoes' }) do
            if not seen[icon] and #icons < 3 then icons[#icons + 1] = icon; seen[icon] = true end
        end
        MySQL.insert.await('INSERT INTO pulse_outfits (identifier, name, skin, icons) VALUES (?, ?, ?, ?)', {
            identifier, outfitName, json.encode(clothesOf(newSkin)), json.encode(icons)
        })
        result.outfits = getOutfits(identifier)
    end

    session.busy = false
    cb({ ok = true, data = result })
end)

ESX.RegisterServerCallback('pulse_clothing:wearOutfit', function(source, cb, id)
    local xPlayer, session = ESX.GetPlayerFromId(source), sessions[source]
    if not xPlayer or not session then return fail(cb, 'Der Laden ist nicht geöffnet') end

    local row = MySQL.single.await('SELECT skin FROM pulse_outfits WHERE id = ? AND identifier = ?', { tonumber(id), xPlayer.identifier })
    local clothes = row and decode(row.skin)
    if not clothes then return fail(cb, 'Outfit nicht gefunden') end

    -- Nur Kleidung übernehmen, Gesicht/Haare bleiben
    local skin = copy(session.base)
    for _, cat in ipairs(Config.Categories) do
        local d, t = toInt(clothes[cat.d]), toInt(clothes[cat.t])
        if d and t then skin[cat.d], skin[cat.t] = d, t end
    end

    saveSkin(xPlayer.identifier, skin)
    session.base = skin
    cb({ ok = true, data = { skin = skin } })
end)

ESX.RegisterServerCallback('pulse_clothing:deleteOutfit', function(source, cb, id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not sessions[source] then return fail(cb, 'Der Laden ist nicht geöffnet') end

    local affected = MySQL.update.await('DELETE FROM pulse_outfits WHERE id = ? AND identifier = ?', { tonumber(id), xPlayer.identifier })
    if not affected or affected < 1 then return fail(cb, 'Outfit nicht gefunden') end
    cb({ ok = true, data = { outfits = getOutfits(xPlayer.identifier) } })
end)

RegisterNetEvent('pulse_clothing:close', function()
    sessions[source] = nil
end)

AddEventHandler('playerDropped', function()
    sessions[source] = nil
end)
