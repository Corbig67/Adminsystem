local UNARMED <const> = `WEAPON_UNARMED`
local USING_OX <const> = GetResourceState('ox_inventory'):find('start') ~= nil

local groups, weapons, ignored = {}, {}, {}
for _, h in ipairs(Config.WeaponGroups) do groups[h] = true end
for _, h in ipairs(Config.Weapons) do weapons[h] = true end
for _, h in ipairs(Config.IgnoredWeapons) do ignored[h] = true end

local function isAnimated(hash)
    if not hash or hash == UNARMED or ignored[hash] then return false end
    return weapons[hash] or groups[GetWeapontypeGroup(hash)] or false
end

local function canAnimate(ped)
    return not IsPedInAnyVehicle(ped, false) and not IsEntityDead(ped) and not IsPedRagdoll(ped)
        and not IsPedSwimming(ped) and not IsPedFalling(ped) and GetPedParachuteState(ped) <= 0
end

-- Sound ----------------------------------------------------------------------------
local function playSound(kind, volume)
    local file = (kind == 'holster' or kind == 'unholster') and Config.Sound[kind]
    if file then SendNUIMessage({ action = 'play', file = file, volume = volume }) end
end

local function holsterSound(kind)
    if not Config.Sound.enabled then return end
    playSound(kind, Config.Sound.volume)
    if Config.Sound.range > 0 then TriggerServerEvent('pulse_holster:sound', kind) end
end

RegisterNetEvent('pulse_holster:sound', function(src, kind)
    if not Config.Sound.enabled or src == cache.serverId then return end
    local player = GetPlayerFromServerId(src)
    if player == -1 then return end
    local ped = GetPlayerPed(player)
    if ped == 0 then return end

    local range = Config.Sound.range
    local dist = #(GetEntityCoords(cache.ped) - GetEntityCoords(ped))
    if dist > range then return end
    playSound(kind, Config.Sound.volume * (1.0 - dist / range))
end)

-- Holster-Kleidung -------------------------------------------------------------------
local function getGender(ped)
    local model = GetEntityModel(ped)
    if model == `mp_m_freemode_01` then return 'male' end
    if model == `mp_f_freemode_01` then return 'female' end
end

-- drawn = true: Waffe gezogen (leeres Holster), false: Waffe steckt im Holster
local function swapHolster(ped, hash, drawn)
    local gender = getGender(ped)
    if not gender then return end

    for _, holster in ipairs(Config.Holsters) do
        local drawables = holster[gender]
        if drawables and lib.table.contains(holster.weapons, hash) then
            local from, to = drawables[1], drawables[2]
            if not drawn then from, to = to, from end
            if GetPedDrawableVariation(ped, holster.variation) == from then
                SetPedComponentVariation(ped, holster.variation, to, GetPedTextureVariation(ped, holster.variation), 0)
                return
            end
        end
    end
end

-- Animation --------------------------------------------------------------------------
local function blockControls()
    DisablePlayerFiring(cache.playerId, true)
    for _, control in ipairs({ 14, 15, 16, 17, 24, 25, 37, 68, 69, 70, 91, 92, 140, 141, 142, 157, 158, 159, 160, 161, 162, 163, 164, 165, 257, 263, 264 }) do
        DisableControlAction(0, control, true)
    end
end

local function playAnim(ped, info)
    lib.requestAnimDict(info.dict)
    local coords = GetEntityCoords(ped)
    TaskPlayAnimAdvanced(ped, info.dict, info.clip, coords.x, coords.y, coords.z, 0, 0, GetEntityHeading(ped), 8.0, 3.0, info.duration * 2, 50, 0.1)
    RemoveAnimDict(info.dict)
end

-- Waffe wegstecken. keepInHand() == true: die alte Waffe bleibt bis zum Einrasten sichtbar in der Hand,
-- sonst wird die (bereits neue) Waffe versteckt.
local function holster(hash, keepInHand)
    local ped, info = cache.ped, Config.Animation.holster
    local done, hidden, regiven = false, false, false

    CreateThread(function()
        while not done do
            blockControls()
            if keepInHand() and not hidden then
                if not HasPedGotWeapon(ped, hash, false) then
                    GiveWeaponToPed(ped, hash, 0, false, true)
                    regiven = true
                end
                if GetSelectedPedWeapon(ped) ~= hash then SetCurrentPedWeapon(ped, hash, true) end
            else
                SetPedCurrentWeaponVisible(ped, false, false, false, false)
            end
            Wait(0)
        end
    end)

    playAnim(ped, info)
    Wait(info.swap)
    hidden = true
    SetPedCurrentWeaponVisible(ped, false, false, false, false)
    swapHolster(ped, hash, false)
    holsterSound('holster')
    Wait(math.max(0, info.duration - info.swap))
    done = true
    return regiven
end

-- Waffe ziehen: Holster öffnen, Waffe erscheint erst bei "show" in der Hand
local function unholster(hash)
    local ped, info = cache.ped, Config.Animation.unholster
    local done, visible = false, false

    SetCurrentPedWeapon(ped, hash, true)
    CreateThread(function()
        while not done do
            blockControls()
            if GetSelectedPedWeapon(ped) ~= hash and HasPedGotWeapon(ped, hash, false) then SetCurrentPedWeapon(ped, hash, true) end
            SetPedCurrentWeaponVisible(ped, visible, false, false, false)
            Wait(0)
        end
        SetPedCurrentWeaponVisible(ped, true, false, false, false)
    end)

    playAnim(ped, info)
    Wait(info.swap)
    swapHolster(ped, hash, true)
    holsterSound('unholster')
    local show = info.show or info.swap
    Wait(math.max(0, show - info.swap))
    visible = true
    Wait(math.max(0, info.duration - show))
    if info.cancel then StopAnimTask(ped, info.dict, info.clip, 2.0) end
    done = true
end

-- Ablauf: Aufträge laufen nacheinander, so wird immer erst weggesteckt und dann gezogen
local queue, busy = {}, false

local function push(job) queue[#queue + 1] = job end

CreateThread(function()
    while true do
        local job = table.remove(queue, 1)
        if job then
            busy = true
            LocalPlayer.state.invBusy = true
            job()
            if #queue == 0 then
                LocalPlayer.state.invBusy = false
                busy = false
            end
        else
            Wait(0)
        end
    end
end)

-- Ohne Animation (z. B. im Fahrzeug): nur Kleidung und Sound
local function instant(hash, drawn)
    swapHolster(cache.ped, hash, drawn)
    holsterSound(drawn and 'unholster' or 'holster')
end

-- Erkennung ohne ox_inventory (GTA-Waffenrad / Tasten) -------------------------------------
if not USING_OX then
    CreateThread(function()
        local last = GetSelectedPedWeapon(cache.ped)
        while true do
            local ped = cache.ped
            local current = GetSelectedPedWeapon(ped)
            if not busy and #queue == 0 and current ~= last then
                local old, new = last, current
                last = current
                local animate = canAnimate(ped)

                if isAnimated(old) then
                    if animate then
                        push(function()
                            -- Alte Waffe nur in der Hand halten, wenn der Spieler sie noch besitzt
                            holster(old, function() return HasPedGotWeapon(ped, old, false) end)
                            SetCurrentPedWeapon(cache.ped, new, true)
                            if new ~= UNARMED then
                                SetPedCurrentWeaponVisible(cache.ped, not isAnimated(new), false, false, false)
                                Wait(Config.SwitchDelay)
                            end
                        end)
                    else
                        instant(old, false)
                    end
                end

                if isAnimated(new) then
                    if animate then push(function() unholster(new) end) else instant(new, true) end
                end
            end
            Wait(0)
        end
    end)
end

-- Erkennung mit ox_inventory ----------------------------------------------------------------
if USING_OX then
    if GetConvarInt('inventory:weaponanims', 1) == 1 then
        print('^3[pulse_holster] ox_inventory spielt eigene Waffen-Animationen. Setze "setr inventory:weaponanims 0" in der server.cfg.^7')
    end

    local current -- aktuelle Waffe laut ox_inventory

    AddEventHandler('ox_inventory:currentWeapon', function(weapon)
        local prev = current
        current = weapon
        if prev and weapon and prev.slot == weapon.slot and prev.hash == weapon.hash then return end

        local animate = canAnimate(cache.ped)

        if prev and isAnimated(prev.hash) then
            local hash = prev.hash
            if animate then
                push(function()
                    -- Solange keine neue Waffe ausgerüstet ist, bleibt die alte in der Hand
                    local regiven = holster(hash, function() return current == nil end)
                    local ped = cache.ped
                    if regiven and (not current or current.hash ~= hash) then RemoveWeaponFromPed(ped, hash) end
                    if current then
                        SetCurrentPedWeapon(ped, current.hash, true)
                        SetPedCurrentWeaponVisible(ped, not isAnimated(current.hash), false, false, false)
                        Wait(Config.SwitchDelay)
                    else
                        SetCurrentPedWeapon(ped, UNARMED, true)
                    end
                end)
            else
                instant(hash, false)
            end
        end

        if weapon and isAnimated(weapon.hash) then
            local hash = weapon.hash
            if animate then
                push(function()
                    if current and current.hash == hash then unholster(hash) end
                end)
            else
                instant(hash, true)
            end
        end
    end)
end
