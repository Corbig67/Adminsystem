ESX = nil

CreateThread(function()
    local ok, obj = pcall(function() return exports['es_extended']:getSharedObject() end)
    if ok and obj then
        ESX = obj
    else
        while not ESX do
            TriggerEvent('esx:getSharedObject', function(o) ESX = o end)
            Wait(100)
        end
    end
end)

local isOpen, isOpening = false, false
local inviteActive = false

local function await(name, ...)
    local p = promise.new()
    ESX.TriggerServerCallback(name, function(res) p:resolve(res) end, ...)
    return Citizen.Await(p)
end

-- Öffnen / Schließen -----------------------------------------------------------------------------
local function closeMenu(notifyServer)
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    if notifyServer then TriggerServerEvent('pulse_bossmenu:close') end
end

local function openMenu(locationIndex)
    if isOpen or isOpening or not ESX then return end
    if IsEntityDead(PlayerPedId()) or IsPauseMenuActive() then return end

    isOpening = true
    local res = await('pulse_bossmenu:open', locationIndex)
    isOpening = false
    if not res or not res.ok then
        ESX.ShowNotification(res and res.error or Config.Locale.error, 'error')
        return
    end

    local data = res.data
    data.action = 'open'
    SendNUIMessage(data)
    SetNuiFocus(true, true)
    isOpen = true
end

exports('OpenBossMenu', openMenu)
RegisterNetEvent('pulse_bossmenu:open', function(locationIndex) openMenu(locationIndex) end)

if Config.Command then
    RegisterCommand(Config.Command, function() openMenu() end, false)
end

RegisterNetEvent('pulse_bossmenu:close', function() closeMenu(false) end)

RegisterNetEvent('pulse_bossmenu:update', function(data)
    if not isOpen then return end
    data.action = 'update'
    SendNUIMessage(data)
end)

RegisterNetEvent('pulse_bossmenu:notify', function(text, notifyType)
    if isOpen then
        SendNUIMessage({ action = 'notify', text = text, type = notifyType })
    else
        ESX.ShowNotification(text, notifyType)
    end
end)

-- NUI-Callbacks: alles wird vom Server geprüft ------------------------------------------------------
for _, name in ipairs({ 'promote', 'demote', 'fire', 'getNearbyPlayers', 'hire', 'deposit', 'withdraw', 'saveSettings' }) do
    RegisterNUICallback(name, function(data, cb)
        if not isOpen then return cb({ ok = false, error = Config.Locale.notOpen }) end
        cb(await('pulse_bossmenu:action', name, data) or { ok = false, error = Config.Locale.error })
    end)
end

RegisterNUICallback('close', function(_, cb)
    cb({ ok = true })
    closeMenu(true)
end)

-- Einladung -------------------------------------------------------------------------------------------
RegisterNetEvent('pulse_bossmenu:invite', function(data)
    data.action = 'invite'
    data.ui = { brand = Config.UI.brand, currency = Config.UI.currency }
    SendNUIMessage(data)
    if inviteActive then return end
    inviteActive = true

    -- Ohne NUI-Fokus: Y / N im Spiel abfragen, damit man sich weiter bewegen kann
    CreateThread(function()
        local endTime = GetGameTimer() + (data.timeout or Config.Invite.timeout) * 1000 + 1000
        while inviteActive and GetGameTimer() < endTime do
            if not isOpen then
                if IsControlJustReleased(0, Config.Invite.acceptKey) then
                    SendNUIMessage({ action = 'inviteKey', accept = true })
                    TriggerServerEvent('pulse_bossmenu:inviteAnswer', true, false)
                    break
                elseif IsControlJustReleased(0, Config.Invite.declineKey) then
                    SendNUIMessage({ action = 'inviteKey', accept = false })
                    TriggerServerEvent('pulse_bossmenu:inviteAnswer', false, false)
                    break
                end
            end
            Wait(0)
        end
        inviteActive = false
    end)
end)

-- Antwort aus der UI (Klick mit Fokus oder abgelaufene Zeit)
RegisterNUICallback('inviteAnswer', function(data, cb)
    cb({ ok = true })
    if not inviteActive then return end
    inviteActive = false
    TriggerServerEvent('pulse_bossmenu:inviteAnswer', data.accept == true, data.timeout == true)
end)

-- Bossmenü-Punkte ---------------------------------------------------------------------------------------
CreateThread(function()
    local m = Config.Marker
    while true do
        local sleep = 1000
        if not isOpen and ESX and ESX.PlayerData and ESX.PlayerData.job then
            local jobConfig = Config.Jobs[ESX.PlayerData.job.name]
            if jobConfig and jobConfig.locations then
                local pos = GetEntityCoords(PlayerPedId())
                for i, loc in ipairs(jobConfig.locations) do
                    local dist = #(pos - loc)
                    if dist < m.drawDistance then
                        sleep = 0
                        DrawMarker(m.type, loc.x, loc.y, loc.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, m.size.x, m.size.y, m.size.z,
                            m.color.r, m.color.g, m.color.b, m.color.a, m.bob, true, 2, m.rotate, nil, nil, false)
                        if dist < Config.InteractRange then
                            ESX.ShowHelpNotification(Config.HelpText)
                            if IsControlJustReleased(0, Config.OpenKey) then openMenu(i) end
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

RegisterNetEvent('esx:setJob', function(job)
    if ESX and ESX.PlayerData then ESX.PlayerData.job = job end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and isOpen then SetNuiFocus(false, false) end
end)
