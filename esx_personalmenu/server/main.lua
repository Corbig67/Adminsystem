ESX = nil
PM = {}

local ok, obj = pcall(function() return exports['es_extended']:getSharedObject() end)
if ok and obj then
    ESX = obj
else
    TriggerEvent('esx:getSharedObject', function(o) ESX = o end)
end

function PM.Notify(source, msg, notifyType)
    TriggerClientEvent('esx:showNotification', source, msg, notifyType)
end

function PM.Log(title, description)
    if not Config.Webhook or Config.Webhook == '' then return end

    PerformHttpRequest(Config.Webhook, function() end, 'POST', json.encode({
        username = 'Personalmenü',
        embeds = { {
            title       = title,
            description = description,
            color       = 3447003,
            timestamp   = os.date('!%Y-%m-%dT%H:%M:%SZ')
        } }
    }), { ['Content-Type'] = 'application/json' })
end

function PM.IsNear(a, b, maxDistance)
    if not Config.ServerDistanceCheck then return true end

    local pedA, pedB = GetPlayerPed(a), GetPlayerPed(b)
    if pedA == 0 or pedB == 0 then return false end

    -- etwas Toleranz für Positions-Sync
    return #(GetEntityCoords(pedA) - GetEntityCoords(pedB)) <= maxDistance + 2.0
end

function PM.IsAdmin(xPlayer)
    if not Config.Admin.Enabled then return false end

    local group = xPlayer.getGroup()
    for _, allowed in ipairs(Config.Admin.Groups) do
        if group == allowed then return true end
    end
    return false
end

function PM.GetOnlinePlayers()
    if ESX.GetExtendedPlayers then
        return ESX.GetExtendedPlayers()
    end

    local players = {}
    for _, id in ipairs(ESX.GetPlayers()) do
        local xPlayer = ESX.GetPlayerFromId(id)
        if xPlayer then players[#players + 1] = xPlayer end
    end
    return players
end

local function accountMoney(xPlayer, name)
    local account = xPlayer.getAccount(name)
    return account and account.money or 0
end

ESX.RegisterServerCallback('esx_personalmenu:getMenuData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(nil) end

    cb({
        name     = xPlayer.getName(),
        jobLabel = xPlayer.getJob().label,
        isAdmin  = PM.IsAdmin(xPlayer)
    })
end)

ESX.RegisterServerCallback('esx_personalmenu:isAdmin', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    cb(xPlayer ~= nil and PM.IsAdmin(xPlayer))
end)

ESX.RegisterServerCallback('esx_personalmenu:getAccounts', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(nil) end

    local job = xPlayer.getJob()
    cb({
        cash       = xPlayer.getMoney(),
        bank       = accountMoney(xPlayer, 'bank'),
        black      = Config.ShowBlackMoney and accountMoney(xPlayer, 'black_money') or nil,
        jobLabel   = job.label,
        gradeLabel = job.grade_label,
        salary     = job.grade_salary
    })
end)

ESX.RegisterServerCallback('esx_personalmenu:getLicenses', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({}) end

    MySQL.query([[
        SELECT ul.type, COALESCE(l.label, ul.type) AS label
        FROM user_licenses ul
        LEFT JOIN licenses l ON l.type = ul.type
        WHERE ul.owner = ?
    ]], { xPlayer.identifier }, function(rows)
        cb(rows or {})
    end)
end)
