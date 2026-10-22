local UNARMED <const> = `WEAPON_UNARMED`
local SNIPER_GROUP <const> = Sync.norm(`GROUP_SNIPER`)

-- Schaden: auf allen Clients gleich setzen (der Schütze berechnet den Schaden)
local function applyDamageModifiers()
    for hash, data in pairs(Sync.weapons) do
        SetWeaponDamageModifier(hash, data.damage)
    end
    SetPlayerMeleeWeaponDamageModifier(PlayerId(), Config.Rules.meleeDamage)
end

CreateThread(function()
    while true do
        applyDamageModifiers()
        local ped = PlayerPedId()
        SetPedSuffersCriticalHits(ped, Config.Rules.headshots)
        Wait(10000) -- regelmäßig erneuern (Respawn, Ped-Wechsel, andere Scripts)
    end
end)

-- Rückstoß -------------------------------------------------------------------------------------------
local pendingPitch, pendingHeading = 0.0, 0.0

local function addRecoil(data, ped)
    local factor = 1.0
    if GetFollowPedCamViewMode() == 4 then factor = factor * Config.Recoil.firstPerson end
    if IsPedInAnyVehicle(ped, false) then factor = factor * Config.Recoil.vehicle end
    pendingPitch = pendingPitch + data.recoil * factor
    pendingHeading = pendingHeading + (math.random() * 2.0 - 1.0) * data.horizontal * factor
end

CreateThread(function()
    while true do
        local sleep = 250
        local ped = PlayerPedId()
        local weapon = GetSelectedPedWeapon(ped)

        if weapon ~= UNARMED then
            sleep = 0
            local data = Sync.get(weapon)

            -- gesperrte Waffe sofort entfernen
            if data and not data.allowed then
                RemoveWeaponFromPed(ped, weapon)
                SetCurrentPedWeapon(ped, UNARMED, true)
            elseif data and Config.Recoil.enabled and data.recoil > 0 and IsPedShooting(ped) then
                addRecoil(data, ped)
            end

            -- Rückstoß weich auf die Kamera übertragen
            if math.abs(pendingPitch) > 0.01 or math.abs(pendingHeading) > 0.01 then
                local s = Config.Recoil.smoothing
                local p, h = pendingPitch * s, pendingHeading * s
                SetGameplayCamRelativePitch(GetGameplayCamRelativePitch() + p, 1.0)
                SetGameplayCamRelativeHeading(GetGameplayCamRelativeHeading() + h)
                pendingPitch, pendingHeading = pendingPitch - p, pendingHeading - h
            end

            local rules = Config.Rules
            local armed = data and data.group ~= 'melee' and data.group ~= 'thrown' and data.group ~= 'misc'

            if rules.noCombatRoll and IsPlayerFreeAiming(PlayerId()) then
                DisableControlAction(0, 22, true)
            end
            if rules.noPistolWhip and armed then
                DisableControlAction(0, 140, true)
                DisableControlAction(0, 141, true)
                DisableControlAction(0, 142, true)
                DisableControlAction(0, 263, true)
                DisableControlAction(0, 264, true)
            end
            if rules.reticle == 'none' or (rules.reticle == 'snipers' and Sync.norm(GetWeapontypeGroup(weapon)) ~= SNIPER_GROUP) then
                HideHudComponentThisFrame(14)
            end
        else
            pendingPitch, pendingHeading = 0.0, 0.0
        end
        Wait(sleep)
    end
end)

-- NPCs lassen keine Waffen fallen
if Config.Rules.noNpcWeaponDrops then
    CreateThread(function()
        while true do
            for _, ped in ipairs(GetGamePool('CPed')) do
                if not IsPedAPlayer(ped) then SetPedDropsWeaponsWhenDead(ped, false) end
            end
            Wait(2000)
        end
    end)
end
