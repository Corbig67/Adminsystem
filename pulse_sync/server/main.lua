-- Server-Prüfung aller Treffer (weaponDamageEvent, OneSync)

local held = {}       -- [source] = { current, previous, changedAt }
local hits = {}       -- [source] = { second, count }
local flags = {}      -- [source] = { list of timestamps }
local lastLog = {}    -- [source .. reason] = time

local function playerName(src) return GetPlayerName(src) or ('ID ' .. src) end

local function identifiers(src)
    local list = {}
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:find('^license:') or id:find('^discord:') or id:find('^fivem:') then list[#list + 1] = id end
    end
    return table.concat(list, ', ')
end

local function webhook(text)
    local url = Config.Punish.webhook
    if not url or url == '' then return end
    PerformHttpRequest(url, function() end, 'POST', json.encode({
        username = 'Pulse Sync',
        embeds = { { title = 'Auffälliger Treffer', description = text, color = 15548997, timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ') } }
    }), { ['Content-Type'] = 'application/json' })
end

-- Meldung + ggf. Kick
local function flag(src, reason, details)
    local now = os.time()
    local key = src .. reason
    if not lastLog[key] or now - lastLog[key] >= Config.Punish.logCooldown then
        lastLog[key] = now
        local text = ('%s (%d) – %s – %s\n%s'):format(playerName(src), src, reason, details, identifiers(src))
        print('^3[pulse_sync] ' .. text .. '^7')
        webhook(text)
    end

    flags[src] = flags[src] or {}
    local list = flags[src]
    list[#list + 1] = now
    while list[1] and now - list[1] > 300 do table.remove(list, 1) end

    local limit = Config.Punish.kickAfter
    if limit > 0 and #list >= limit and not IsPlayerAceAllowed(src, Config.AdminAce) then
        print(('^1[pulse_sync] %s (%d) gekickt nach %d Meldungen^7'):format(playerName(src), src, #list))
        webhook(('**Gekickt:** %s (%d) nach %d Meldungen in 5 Minuten'):format(playerName(src), src, #list))
        DropPlayer(src, Config.Punish.kickMessage)
    end
end

-- 'cancel' verwirft den Treffer, 'log' meldet nur
local function handle(mode, src, reason, details)
    if not mode then return false end
    flag(src, reason, details)
    if mode == 'cancel' then
        CancelEvent()
        return true
    end
    return false
end

-- Welche Waffe hat der Spieler in der Hand? (mit Toleranz nach einem Wechsel)
CreateThread(function()
    while true do
        local now = GetGameTimer()
        for _, src in ipairs(GetPlayers()) do
            src = tonumber(src)
            local ped = GetPlayerPed(src)
            if ped and ped ~= 0 then
                local weapon = Sync.norm(GetSelectedPedWeapon(ped))
                local h = held[src]
                if not h then
                    held[src] = { current = weapon, previous = weapon, changedAt = now }
                elseif h.current ~= weapon then
                    h.previous, h.current, h.changedAt = h.current, weapon, now
                end
            end
        end
        Wait(200)
    end
end)

local function isHolding(src, weapon)
    local h = held[src]
    if not h then return true end -- noch keine Daten -> nicht bestrafen
    -- aktuelle Waffe direkt am Ped prüfen (genauer als die 200-ms-Abfrage)
    local ped = GetPlayerPed(src)
    if ped and ped ~= 0 and Sync.norm(GetSelectedPedWeapon(ped)) == weapon then return true end
    if h.current == weapon then return true end
    return h.previous == weapon and GetGameTimer() - h.changedAt <= Config.Validation.heldGrace
end

AddEventHandler('weaponDamageEvent', function(sender, data)
    sender = tonumber(sender)
    local weapon = Sync.norm(data.weaponType)
    local info = weapon and Sync.get(weapon)
    if not info then return end -- Fahrzeug, Sturz, Explosion, Addon-Waffen usw.

    local v = Config.Validation

    if not info.allowed then
        if handle(v.disallowedWeapon, sender, 'gesperrte Waffe', info.name) then return end
    end

    -- aus Fahrzeugen nicht prüfen (Drive-by meldet die Waffe dem Server nicht immer zuverlässig)
    local shooterPed = GetPlayerPed(sender)
    local inVehicle = shooterPed and shooterPed ~= 0 and GetVehiclePedIsIn(shooterPed, false) ~= 0
    if info.checkHeld and not inVehicle and not isHolding(sender, weapon) then
        if handle(v.notHeld, sender, 'Waffe nicht in der Hand', info.name) then return end
    end

    -- Grenze wächst mit dem eingestellten Schadens-Multiplikator mit
    local cap = info.maxDamage and info.maxDamage * math.max(1.0, info.damage)
    if cap and (data.weaponDamage or 0) > cap then
        if handle(v.damage, sender, 'zu hoher Schaden', ('%s: %d (max %d)'):format(info.name, data.weaponDamage, cap)) then return end
    end

    -- Entfernung zum Getroffenen
    if v.distance then
        local netId = data.hitGlobalId or (data.hitGlobalIds and data.hitGlobalIds[1])
        local target = netId and NetworkGetEntityFromNetworkId(netId) or 0
        local shooter = GetPlayerPed(sender)
        if target ~= 0 and DoesEntityExist(target) and shooter and shooter ~= 0 then
            local a, b = GetEntityCoords(shooter), GetEntityCoords(target)
            local valid = not (a.x == 0.0 and a.y == 0.0 and a.z == 0.0)
            local dist = #(a - b)
            if valid and dist > info.range then
                if handle(v.distance, sender, 'Treffer zu weit entfernt', ('%s: %.0f m (max %d m)'):format(info.name, dist, info.range)) then return end
            end
        end
    end

    -- Treffer pro Sekunde
    if v.fireRate then
        local second = os.time()
        local h = hits[sender]
        if not h or h.second ~= second then
            h = { second = second, count = 0 }
            hits[sender] = h
        end
        h.count = h.count + 1
        if h.count > info.maxHitsPerSecond then
            if handle(v.fireRate, sender, 'zu viele Treffer pro Sekunde', ('%s: %d (max %d)'):format(info.name, h.count, info.maxHitsPerSecond)) then return end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    held[src], hits[src], flags[src] = nil, nil, nil
end)

-- /syncstatus <id> – Meldungen eines Spielers in den letzten 5 Minuten (Konsole oder Admin mit ACE)
RegisterCommand('syncstatus', function(source, args)
    if source ~= 0 and not IsPlayerAceAllowed(source, 'command.syncstatus') then return end
    local target = tonumber(args[1])
    local msg
    if target then
        msg = ('%s: %d Meldungen in den letzten 5 Minuten'):format(playerName(target), flags[target] and #flags[target] or 0)
    else
        local n = 0
        for _, list in pairs(flags) do n = n + #list end
        msg = ('%d Meldungen in den letzten 5 Minuten (alle Spieler)'):format(n)
    end
    if source == 0 then print(msg) else TriggerClientEvent('chat:addMessage', source, { args = { 'Pulse Sync', msg } }) end
end, true)
