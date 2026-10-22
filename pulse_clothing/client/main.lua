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
local restoreSkin       -- Skin, der beim Verlassen ohne Kauf wieder angezogen wird
local baseHeading = 0.0
local cam

local categoryById = {}
for _, cat in ipairs(Config.Categories) do categoryById[cat.id] = cat end

-- Helfer -----------------------------------------------------------------------
local function await(name, ...)
    local p = promise.new()
    ESX.TriggerServerCallback(name, function(res) p:resolve(res) end, ...)
    return Citizen.Await(p)
end

local function getSkin()
    local p = promise.new()
    TriggerEvent('skinchanger:getSkin', function(skin) p:resolve(skin) end)
    return Citizen.Await(p)
end

local function getMaxValues()
    local max = {}
    TriggerEvent('skinchanger:getData', function(_, maxVals) max = maxVals or {} end)
    return max
end

local function loadSkin(skin)
    TriggerEvent('skinchanger:loadSkin', skin)
end

-- Kamera -----------------------------------------------------------------------
local function camPosition(mode)
    local c = Config.Camera[mode] or Config.Camera.body
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local rad = math.rad(baseHeading)
    local fx, fy = -math.sin(rad), math.cos(rad)
    return vector3(pos.x + fx * c.dist, pos.y + fy * c.dist, pos.z + c.z), vector3(pos.x, pos.y, pos.z + c.point), c.fov
end

local function setCamera(mode)
    local pos, point, fov = camPosition(mode)
    local newCam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, fov, false, 2)
    PointCamAtCoord(newCam, point.x, point.y, point.z)

    if cam and DoesCamExist(cam) then
        local old = cam
        SetCamActiveWithInterp(newCam, old, 450, 1, 1)
        SetTimeout(500, function() if DoesCamExist(old) then DestroyCam(old, false) end end)
    else
        SetCamActive(newCam, true)
        RenderScriptCams(true, true, 500, true, true)
    end
    cam = newCam
end

local function destroyCamera()
    RenderScriptCams(false, true, 500, true, true)
    if cam and DoesCamExist(cam) then DestroyCam(cam, false) end
    cam = nil
end

-- Öffnen / Schließen -----------------------------------------------------------
local function closeShop(restore)
    if not isOpen then return end
    isOpen = false

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    if restore and restoreSkin then loadSkin(restoreSkin) end
    destroyCamera()

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetEntityHeading(ped, baseHeading)
    DisplayRadar(true)
    TriggerServerEvent('pulse_clothing:close')
end

local function openShop(shopIndex)
    if isOpen or isOpening or not ESX then return end
    local ped = PlayerPedId()
    if IsEntityDead(ped) or IsPedInAnyVehicle(ped, false) then return end

    isOpening = true
    local current = getSkin()
    local res = await('pulse_clothing:open', shopIndex, current)
    if not res or not res.ok then
        isOpening = false
        ESX.ShowNotification(res and res.error or 'Der Laden ist gerade nicht verfügbar', 'error')
        return
    end

    local data = res.data
    restoreSkin = current
    loadSkin(data.values)
    Wait(100)

    baseHeading = GetEntityHeading(ped)
    ClearPedTasks(ped)
    FreezeEntityPosition(ped, true)
    DisplayRadar(false)
    setCamera('body')

    data.action = 'open'
    data.values = getSkin()
    data.max = getMaxValues()
    SendNUIMessage(data)
    SetNuiFocus(true, true)

    isOpen, isOpening = true, false
end

exports('OpenShop', openShop)
RegisterNetEvent('pulse_clothing:openShop', function(shopIndex) openShop(shopIndex or 1) end)

-- NUI-Callbacks ----------------------------------------------------------------
RegisterNUICallback('change', function(data, cb)
    local cat = categoryById[data.component]
    local values = data.values or {}
    if not isOpen or not cat then return cb({ ok = false, error = 'Unbekanntes Teil' }) end

    local d, t = tonumber(values[cat.d]), tonumber(values[cat.t])
    if d then TriggerEvent('skinchanger:change', cat.d, math.floor(d)) end
    if t then TriggerEvent('skinchanger:change', cat.t, math.floor(t)) end

    local max = getMaxValues()
    cb({ ok = true, data = { max = { [cat.t] = max[cat.t] or 0 } } })
end)

RegisterNUICallback('camera', function(data, cb)
    if isOpen and Config.Camera[data.mode] then setCamera(data.mode) end
    cb({ ok = true })
end)

RegisterNUICallback('rotate', function(data, cb)
    if isOpen then
        local ped = PlayerPedId()
        local dir = tonumber(data.dir) == -1 and -1 or 1
        SetEntityHeading(ped, GetEntityHeading(ped) + dir * Config.RotateStep)
    end
    cb({ ok = true })
end)

RegisterNUICallback('buy', function(data, cb)
    if not isOpen then return cb({ ok = false, error = 'Der Laden ist nicht geöffnet' }) end
    local res = await('pulse_clothing:buy', data)
    if not res or not res.ok then return cb(res or { ok = false, error = 'Keine Antwort vom Server' }) end

    restoreSkin = res.data.skin
    loadSkin(res.data.skin)
    res.data.skin = nil
    cb(res)

    if Config.CloseAfterBuy then
        Wait(Config.CloseDelay)
        closeShop(false)
        local msg = ('Gekauft für $%s'):format(ESX.Math.GroupDigits(res.data.total or 0))
        if res.data.outfits and data.outfit then msg = msg .. (' · Outfit „%s“ gespeichert'):format(data.outfit) end
        ESX.ShowNotification(msg, 'success')
    end
end)

RegisterNUICallback('wearOutfit', function(data, cb)
    if not isOpen then return cb({ ok = false, error = 'Der Laden ist nicht geöffnet' }) end
    local res = await('pulse_clothing:wearOutfit', data.id)
    if not res or not res.ok then return cb(res or { ok = false, error = 'Keine Antwort vom Server' }) end

    restoreSkin = res.data.skin
    loadSkin(res.data.skin)
    Wait(100)
    cb({ ok = true, data = { values = getSkin(), max = getMaxValues() } })
end)

RegisterNUICallback('deleteOutfit', function(data, cb)
    if not isOpen then return cb({ ok = false, error = 'Der Laden ist nicht geöffnet' }) end
    cb(await('pulse_clothing:deleteOutfit', data.id) or { ok = false, error = 'Keine Antwort vom Server' })
end)

RegisterNUICallback('close', function(_, cb)
    cb({ ok = true })
    closeShop(true)
end)

-- Blips und Marker ---------------------------------------------------------------
CreateThread(function()
    for _, shop in ipairs(Config.Shops) do
        if shop.blip ~= false then
            local blip = AddBlipForCoord(shop.coords.x, shop.coords.y, shop.coords.z)
            SetBlipSprite(blip, Config.Blip.sprite)
            SetBlipColour(blip, Config.Blip.color)
            SetBlipScale(blip, Config.Blip.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(shop.blipLabel or Config.Blip.label)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

CreateThread(function()
    local m = Config.Marker
    while true do
        local sleep = 1000
        if not isOpen and ESX then
            local pos = GetEntityCoords(PlayerPedId())
            for i, shop in ipairs(Config.Shops) do
                local dist = #(pos - shop.coords)
                if dist < m.drawDistance then
                    sleep = 0
                    DrawMarker(m.type, shop.coords.x, shop.coords.y, shop.coords.z - 0.95, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        m.size.x, m.size.y, m.size.z, m.color.r, m.color.g, m.color.b, m.color.a, false, false, 2, false, nil, nil, false)
                    if dist < Config.InteractRange then
                        ESX.ShowHelpNotification('Drücke ~INPUT_CONTEXT~, um den Laden zu betreten')
                        if IsControlJustReleased(0, Config.OpenKey) then openShop(i) end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and isOpen then closeShop(true) end
end)
