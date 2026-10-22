-- Kopfschuss, "stirbt nicht"-Fix und Hitmarker

local HEAD_BONES <const> = { [31086] = true, [39317] = true, [12844] = true, [65068] = true } -- Kopf, Hals, IK_Head, Gesicht
local lastHit = 0

local function hasProtectingHelmet(ped)
    local female = GetEntityModel(ped) == `mp_f_freemode_01`
    local list = Config.Headshot.helmets[female and 'female' or 'male'] or {}
    if #list == 0 then return false end
    local prop = GetPedPropIndex(ped, 0)
    for _, id in ipairs(list) do if id == prop then return true end end
    return false
end

local function isHeadHit(ped)
    local found, bone = GetPedLastDamageBone(ped)
    return found and HEAD_BONES[bone] == true
end

local function playSound(sound)
    if sound then PlaySoundFrontend(-1, sound.name, sound.set, true) end
end

-- Hitmarker ------------------------------------------------------------------------------------------
local marker = { untilTime = 0, color = Config.Hitmarker.color }

local function showHitmarker(color)
    marker.untilTime = GetGameTimer() + Config.Hitmarker.time
    marker.color = color
    if marker.drawing then return end
    marker.drawing = true
    CreateThread(function()
        local s = Config.Hitmarker.size
        local w, h = GetActiveScreenResolution()
        local aspect = w / h
        while GetGameTimer() < marker.untilTime do
            local c = marker.color
            local sx, sy = s / aspect, s
            local d = s * 1.2
            -- vier kleine Striche diagonal um die Bildschirmmitte
            for _, o in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do
                DrawRect(0.5 + o[1] * d / aspect, 0.5 + o[2] * d, sx * 0.9, sy * 0.25, c[1], c[2], c[3], c[4])
                DrawRect(0.5 + o[1] * d / aspect, 0.5 + o[2] * d, sx * 0.25, sy * 0.9, c[1], c[2], c[3], c[4])
            end
            Wait(0)
        end
        marker.drawing = false
    end)
end

-- Treffer-Ereignis --------------------------------------------------------------------------------------
AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end
    local ped = PlayerPedId()
    local victim, attacker = args[1], args[2]
    local data = Sync.get(args[7])
    if not data then return end

    -- Ich wurde getroffen
    if victim == ped then
        lastHit = GetGameTimer()
        local c = Config.Headshot
        if c.enabled and data.headshot and not IsEntityDead(ped) and isHeadHit(ped) and not hasProtectingHelmet(ped) then
            SetEntityHealth(ped, 0)
        end
        return
    end

    -- Ich habe getroffen
    local hm = Config.Hitmarker
    if attacker ~= ped or not hm.enabled or not DoesEntityExist(victim) or not IsEntityAPed(victim) then return end
    if not hm.npcs and not IsPedAPlayer(victim) then return end

    local headshot = data.headshot and isHeadHit(victim)
    showHitmarker((headshot) and hm.headshot or hm.color)
    if headshot then playSound(hm.headshotSound) else playSound(hm.hitSound) end

    -- Kill erst im nächsten Frame sicher erkennbar
    CreateThread(function()
        Wait(50)
        if IsEntityDead(victim) then
            showHitmarker(hm.headshot)
            if not headshot then playSound(hm.killSound) end
        end
    end)
end)

-- "Stirbt nicht"-Fix -------------------------------------------------------------------------------------
if Config.DeathFix.enabled then
    CreateThread(function()
        while true do
            local ped = PlayerPedId()
            if lastHit > 0 and GetGameTimer() - lastHit < Config.DeathFix.window and not IsEntityDead(ped) then
                local health = GetEntityHealth(ped)
                if health > 0 and health <= Config.DeathFix.threshold then SetEntityHealth(ped, 0) end
            end
            Wait(100)
        end
    end)
end
