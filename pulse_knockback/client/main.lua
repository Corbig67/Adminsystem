-- Hashes immer als vorzeichenlose Zahl vergleichen (Events liefern sie teils anders als `WEAPON_X`)
local function norm(hash) return hash and (hash % 4294967296) end

local weapons = {}
for hash, data in pairs(Config.Weapons) do weapons[norm(hash)] = data end

local lastKnock = 0

-- Schleudert den eigenen Ped vom Punkt "from" weg (oder nach hinten, wenn kein Schütze bekannt ist)
local function knockback(ped, from, data)
    local now = GetGameTimer()
    if now - lastKnock < Config.Cooldown then return end
    lastKnock = now

    local pos = GetEntityCoords(ped)
    local dx, dy
    if from then
        dx, dy = pos.x - from.x, pos.y - from.y
    else
        local fwd = GetEntityForwardVector(ped)
        dx, dy = -fwd.x, -fwd.y
    end
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.001 then
        local fwd = GetEntityForwardVector(ped)
        dx, dy, len = -fwd.x, -fwd.y, 1.0
    end
    dx, dy = dx / len, dy / len

    if Config.CameraShake > 0 then ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', Config.CameraShake) end

    SetPedToRagdoll(ped, data.ragdoll, data.ragdoll, 0, false, false, false)
    -- kurz warten, bis die Ragdoll-Physik aktiv ist, dann Impuls auf den Körper
    CreateThread(function()
        Wait(0)
        ApplyForceToEntity(ped, 1, dx * data.force, dy * data.force, data.up, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
    end)
end

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end
    local ped = PlayerPedId()
    local victim, attacker, weapon = args[1], args[2], norm(args[7])
    if victim ~= ped then return end

    local data = weapon and weapons[weapon]
    if not data or math.random() > data.chance then return end
    if not Config.InVehicle and IsPedInAnyVehicle(ped, false) then return end
    if not Config.WhenDead and IsEntityDead(ped) then return end

    local from = attacker and attacker ~= 0 and DoesEntityExist(attacker) and GetEntityCoords(attacker) or nil
    knockback(ped, from, data)
end)

exports('Knockback', function(fromCoords, force, up, ragdoll)
    knockback(PlayerPedId(), fromCoords, { force = force or 30, up = up or 4, ragdoll = ragdoll or 2500 })
end)

-- Testbefehl: schleudert dich so, als hätte dich jemand von vorne getroffen
if Config.TestCommand.enabled then
    local t = Config.TestCommand
    RegisterCommand(t.name, function(_, args)
        local ped = PlayerPedId()
        local front = GetOffsetFromEntityInWorldCoords(ped, 0.0, 5.0, 0.0)
        lastKnock = 0
        knockback(ped, front, {
            force = tonumber(args[1]) or t.force,
            up = tonumber(args[2]) or t.up,
            ragdoll = t.ragdoll
        })
    end, t.restricted)

    TriggerEvent('chat:addSuggestion', '/' .. t.name, 'Rückstoß testen', {
        { name = 'wucht', help = 'z. B. 30 (mehr = weiter)' },
        { name = 'hoch', help = 'z. B. 4' }
    })
end
