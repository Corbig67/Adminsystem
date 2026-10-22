local L = Config.Locale
local UNARMED <const> = `WEAPON_UNARMED`

-- Hashes immer als vorzeichenlose Zahl vergleichen (Events liefern sie teils anders als `WEAPON_X`)
local function norm(hash) return hash and (hash % 4294967296) end

local function toSet(list)
    local set = {}
    for _, v in ipairs(list or {}) do set[norm(v)] = true end
    return set
end

local gunGroups = toSet(Config.WeaponGroups)
local ignoredWeapons = toSet(Config.IgnoredWeapons)
local twoHanded = toSet(Config.Arm.twoHandedGroups)

-- Knochen -> Körperzone (Ped-Bone-IDs)
local BONES = {
    head = { 31086, 39317, 12844, 65068 },  -- SKEL_Head, SKEL_Neck_1, IK_Head, FACIAL_facialRoot
    leftArm = { 64729, 45509, 61163, 18905, 60309, 36029, 61007, 5232, 22711, 26610, 26611, 26612, 26613, 26614, 4089, 4090, 4137, 4138, 4153, 4154, 4169, 4170, 4185, 4186 },
    rightArm = { 10706, 40269, 28252, 57005, 28422, 6286, 43810, 37119, 2992, 58866, 58867, 58868, 58869, 58870, 64016, 64017, 64064, 64065, 64080, 64081, 64096, 64097, 64112, 64113 },
    leftLeg = { 58271, 63931, 14201, 2108, 65245, 57717, 46078, 23639 },
    rightLeg = { 51826, 36864, 52301, 20781, 35502, 24806, 16335, 6442 }
}
local boneZone = {}
for zone, list in pairs(BONES) do
    for _, bone in ipairs(list) do boneZone[bone] = zone end
end

-- Verletzungen: [zone] = Ablaufzeit (GetGameTimer) oder math.huge = bis zur Behandlung
local injuries = {}
local bleeding = { stacks = 0, untilTime = 0 }
local lastHealth = 0

local function untilTime(seconds)
    if not seconds or seconds <= 0 then return math.huge end
    return GetGameTimer() + seconds * 1000
end

local function isInjured(zone)
    local t = injuries[zone]
    return t ~= nil and t > GetGameTimer()
end

local function isFemale(ped) return GetEntityModel(ped) == `mp_f_freemode_01` end

-- Heilung -------------------------------------------------------------------------------------------
local function heal(silent)
    local hadAny = next(injuries) ~= nil or bleeding.stacks > 0
    injuries = {}
    bleeding.stacks, bleeding.untilTime = 0, 0
    local ped = PlayerPedId()
    ResetPedMovementClipset(ped, 0.5)
    SetPedMoveRateOverride(ped, 1.0)
    StopGameplayCamShaking(true)
    if hadAny and not silent then Config.Notify(L.healed) end
end

exports('Heal', heal)
exports('GetInjuries', function()
    local list = {}
    for zone in pairs(injuries) do if isInjured(zone) then list[#list + 1] = zone end end
    if bleeding.stacks > 0 then list[#list + 1] = 'bleeding' end
    return list
end)

RegisterNetEvent('pulse_damage:heal', function() heal(false) end)
for _, name in ipairs(Config.HealEvents) do
    RegisterNetEvent(name)
    AddEventHandler(name, function() heal(false) end)
end
AddEventHandler('playerSpawned', function() heal(true) end)
AddEventHandler('esx:onPlayerSpawn', function() heal(true) end)

-- Treffer ---------------------------------------------------------------------------------------------
local function hasHelmet(ped)
    local list = Config.Head.helmets[isFemale(ped) and 'female' or 'male'] or {}
    if #list == 0 then return false end
    local prop = GetPedPropIndex(ped, 0)
    for _, id in ipairs(list) do if id == prop then return true end end
    return false
end

local function addBleeding(zone)
    local b = Config.Bleeding
    if not b.enabled or not b.zones[zone] then return end
    bleeding.stacks = math.min(b.maxStack, bleeding.stacks + 1)
    bleeding.untilTime = untilTime(b.duration)
end

local function onLegHit(ped, zone)
    local c = Config.Leg
    injuries[zone] = untilTime(c.duration)
    if not IsPedInAnyVehicle(ped, false) and math.random() < c.fallChance then
        SetPedToRagdoll(ped, c.ragdollTime, c.ragdollTime, 0, false, false, false)
    end
    Config.Notify(L.leg)
end

local function onArmHit(ped, zone)
    local c = Config.Arm
    injuries[zone] = untilTime(c.duration)
    if zone == 'rightArm' then
        Config.Notify(L.shootArm)
        local _, weapon = GetCurrentPedWeapon(ped, true)
        if weapon ~= UNARMED and math.random() < c.disarmChance then
            SetCurrentPedWeapon(ped, UNARMED, true)
            Config.Notify(L.disarmed)
        end
    else
        Config.Notify(L.arm)
    end
end

local function onHit(ped, zone)
    if Config.HitShake > 0 then ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', Config.HitShake) end

    if zone == 'head' then
        if Config.Head.enabled and not hasHelmet(ped) and math.random() < Config.Head.killChance then
            SetEntityHealth(ped, 0)
        end
        return
    end

    if (zone == 'leftLeg' or zone == 'rightLeg') and Config.Leg.enabled then
        onLegHit(ped, zone)
    elseif (zone == 'leftArm' or zone == 'rightArm') and Config.Arm.enabled then
        onArmHit(ped, zone)
    elseif zone == 'torso' and Config.Bleeding.enabled then
        Config.Notify(L.torso)
    end
    addBleeding(zone)
end

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end
    local ped = PlayerPedId()
    local victim, weapon = args[1], args[7]
    if victim ~= ped or IsEntityDead(ped) then return end

    weapon = norm(weapon)
    if not weapon or ignoredWeapons[weapon] or not gunGroups[norm(GetWeapontypeGroup(weapon))] then return end

    local found, bone = GetPedLastDamageBone(ped)
    if not found then return end
    onHit(ped, boneZone[bone] or 'torso')
end)

-- Dauerhafte Effekte ----------------------------------------------------------------------------------------
-- Beine: humpeln, langsamer, nicht rennen/springen
CreateThread(function()
    local limping = false
    local nextStumbleCheck, stumbleBlockedUntil = 0, 0
    while true do
        local sleep = 500
        local ped = PlayerPedId()
        local left, right = isInjured('leftLeg'), isInjured('rightLeg')

        if (left or right) and not IsEntityDead(ped) then
            sleep = 0
            local c = Config.Leg
            if not limping then
                local set = c.clipset[isFemale(ped) and 'female' or 'male']
                RequestAnimSet(set)
                local timeout = GetGameTimer() + 1000
                while not HasAnimSetLoaded(set) and GetGameTimer() < timeout do Wait(0) end
                SetPedMovementClipset(ped, set, 1.0)
                limping = true
            end
            SetPedMoveRateOverride(ped, (left and right) and c.bothLegsMoveRate or c.moveRate)
            if c.noSprint then DisableControlAction(0, 21, true) end

            -- einmal pro Sekunde würfeln, ob man beim Laufen hinfällt
            local now = GetGameTimer()
            if now >= nextStumbleCheck then
                nextStumbleCheck = now + 1000
                if now >= stumbleBlockedUntil and not IsPedInAnyVehicle(ped, false) and not IsPedRagdoll(ped) then
                    local st = c.stumble
                    local chance = IsPedSprinting(ped) and st.sprint or IsPedRunning(ped) and st.run or IsPedWalking(ped) and st.walk or 0
                    if left and right then chance = chance * st.bothLegs end
                    if chance > 0 and math.random() < chance then
                        SetPedToRagdoll(ped, st.time, st.time, 0, false, false, false)
                        stumbleBlockedUntil = now + st.time + st.cooldown * 1000
                    end
                end
            end
            if c.noJump then DisableControlAction(0, 22, true) end
        elseif limping then
            limping = false
            ResetPedMovementClipset(ped, 0.5)
            SetPedMoveRateOverride(ped, 1.0)
        end
        Wait(sleep)
    end
end)

-- Einhand-Animation: über einen State Bag synchronisiert, damit andere Spieler sie auch sehen
local ONE_HAND <const> = joaat(Config.Arm.oneHandedAnim)

local function applyOneHand(ped, on)
    SetWeaponAnimationOverride(ped, on and ONE_HAND or `Default`)
end

AddStateBagChangeHandler('pulseOneHand', nil, function(bagName, _, value)
    local player = GetPlayerFromStateBagName(bagName)
    if player == 0 then return end
    applyOneHand(GetPlayerPed(player), value == true)
end)

-- Spieler, die neu in Reichweite kommen, bekommen die Animation nachträglich
CreateThread(function()
    while true do
        for _, player in ipairs(GetActivePlayers()) do
            if player ~= PlayerId() and Player(GetPlayerServerId(player)).state.pulseOneHand then
                applyOneHand(GetPlayerPed(player), true)
            end
        end
        Wait(2000)
    end
end)

-- Arme: Einhand-Haltung, Wackeln beim Zielen, keine Langwaffen, mit beiden Armen gar nicht schießen
CreateThread(function()
    local shaking, oneHand, nextReapply = false, false, 0
    while true do
        local sleep = 500
        local ped = PlayerPedId()
        local left, right = isInjured('leftArm'), isInjured('rightArm')

        local wantOneHand = Config.Arm.oneHanded and (left or right) and not IsEntityDead(ped)
        if wantOneHand ~= oneHand then
            oneHand = wantOneHand
            applyOneHand(ped, oneHand)
            LocalPlayer.state:set('pulseOneHand', oneHand, true)
        elseif oneHand and GetGameTimer() >= nextReapply then
            nextReapply = GetGameTimer() + 2000
            applyOneHand(ped, true) -- nach Modell-/Ped-Wechsel erneut setzen
        end

        if (left or right) and not IsEntityDead(ped) then
            sleep = 0
            local c = Config.Arm
            local _, weapon = GetCurrentPedWeapon(ped, true)

            if c.noTwoHanded and weapon ~= UNARMED and twoHanded[norm(GetWeapontypeGroup(weapon))] then
                SetCurrentPedWeapon(ped, UNARMED, true)
                Config.Notify(L.noTwoHanded)
            end

            if c.bothArmsNoShoot and left and right then
                DisablePlayerFiring(PlayerId(), true)
                DisableControlAction(0, 24, true)
                DisableControlAction(0, 25, true)
                DisableControlAction(0, 257, true)
            end

            if IsPlayerFreeAiming(PlayerId()) then
                if not shaking then
                    ShakeGameplayCam('HAND_SHAKE', right and c.shakeShootHand or c.shake)
                    shaking = true
                end
            elseif shaking then
                StopGameplayCamShaking(true)
                shaking = false
            end
        elseif shaking then
            StopGameplayCamShaking(true)
            shaking = false
        end
        Wait(sleep)
    end
end)

-- Blutung und Heilung durch volle Gesundheit
CreateThread(function()
    local nextBleed = 0
    while true do
        local ped = PlayerPedId()
        local now = GetGameTimer()
        local health, maxHealth = GetEntityHealth(ped), GetEntityMaxHealth(ped)

        if bleeding.stacks > 0 then
            if bleeding.untilTime <= now then
                bleeding.stacks = 0
            elseif now >= nextBleed and not IsEntityDead(ped) then
                nextBleed = now + Config.Bleeding.interval * 1000
                local newHealth = math.max(health - Config.Bleeding.damage * bleeding.stacks, Config.Bleeding.stopAt)
                if newHealth < health then
                    SetEntityHealth(ped, newHealth)
                    health = newHealth
                end
            end
        end

        -- abgelaufene Verletzungen entfernen
        for zone, t in pairs(injuries) do if t <= now then injuries[zone] = nil end end

        if Config.HealOnFullHealth and lastHealth > 0 and lastHealth < maxHealth and health >= maxHealth
            and (next(injuries) ~= nil or bleeding.stacks > 0) then
            heal(false)
        end
        lastHealth = health
        Wait(1000)
    end
end)

-- Befehl ------------------------------------------------------------------------------------------------------
if Config.Command then
    RegisterCommand(Config.Command, function()
        local names = {}
        for zone in pairs(injuries) do if isInjured(zone) then names[#names + 1] = L.zones[zone] or zone end end
        if bleeding.stacks > 0 then names[#names + 1] = L.zones.bleeding end
        Config.Notify(#names > 0 and L.list:format(table.concat(names, ', ')) or L.none)
    end, false)
end

-- Testbefehl ---------------------------------------------------------------------------------------------------
if Config.TestCommand.enabled then
    local ZONES = {
        kopf = 'head', head = 'head',
        bein = 'leftLeg', lbein = 'leftLeg', rbein = 'rightLeg', leg = 'leftLeg',
        arm = 'rightArm', larm = 'leftArm', rarm = 'rightArm',
        ['körper'] = 'torso', koerper = 'torso', torso = 'torso'
    }
    local usage = '/' .. Config.TestCommand.name .. ' kopf | bein | lbein | rbein | arm | larm | rarm | körper | heilen'

    RegisterCommand(Config.TestCommand.name, function(_, args)
        local arg = (args[1] or ''):lower()
        if arg == 'heilen' or arg == 'heal' then return heal(false) end

        local zone = ZONES[arg]
        if not zone then return Config.Notify(usage) end

        local ped = PlayerPedId()
        if IsEntityDead(ped) then return end
        if zone ~= 'head' and Config.TestCommand.damage > 0 then
            SetEntityHealth(ped, math.max(101, GetEntityHealth(ped) - Config.TestCommand.damage))
        end
        onHit(ped, zone)
    end, Config.TestCommand.restricted)

    TriggerEvent('chat:addSuggestion', '/' .. Config.TestCommand.name, 'Verletzung testen', {
        { name = 'zone', help = 'kopf, bein, lbein, rbein, arm, larm, rarm, körper, heilen' }
    })
end
