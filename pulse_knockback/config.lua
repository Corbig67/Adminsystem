Config = {}

-- Waffen, die einen umwerfen ---------------------------------------------------------------
-- force    = Wucht nach hinten (mehr = weiter; ca. 20 = 1 m, 35 = 2 m – mit /knocktest ausprobieren)
-- up       = leicht nach oben, damit man nicht am Boden hängen bleibt
-- chance   = Wahrscheinlichkeit pro Treffer (1.0 = immer)
-- ragdoll  = ms am Boden
Config.Weapons = {
    [`WEAPON_PISTOL50`]       = { force = 30, up = 4, chance = 1.0, ragdoll = 2500 },
    [`WEAPON_HEAVYPISTOL`]    = { force = 22, up = 3, chance = 0.6, ragdoll = 2000 },
    [`WEAPON_REVOLVER`]       = { force = 32, up = 4, chance = 1.0, ragdoll = 2500 },
    [`WEAPON_REVOLVER_MK2`]   = { force = 32, up = 4, chance = 1.0, ragdoll = 2500 },
    [`WEAPON_DOUBLEACTION`]   = { force = 26, up = 3, chance = 0.8, ragdoll = 2200 },
    [`WEAPON_PUMPSHOTGUN`]    = { force = 35, up = 4, chance = 1.0, ragdoll = 3000 },
    [`WEAPON_PUMPSHOTGUN_MK2`]= { force = 35, up = 4, chance = 1.0, ragdoll = 3000 },
    [`WEAPON_SAWNOFFSHOTGUN`] = { force = 38, up = 4, chance = 1.0, ragdoll = 3000 },
    [`WEAPON_DBSHOTGUN`]      = { force = 40, up = 5, chance = 1.0, ragdoll = 3000 },
    [`WEAPON_HEAVYSHOTGUN`]   = { force = 38, up = 4, chance = 1.0, ragdoll = 3000 },
    [`WEAPON_SNIPERRIFLE`]    = { force = 35, up = 4, chance = 1.0, ragdoll = 3000 },
    [`WEAPON_HEAVYSNIPER`]    = { force = 45, up = 5, chance = 1.0, ragdoll = 3500 },
    [`WEAPON_HEAVYSNIPER_MK2`]= { force = 45, up = 5, chance = 1.0, ragdoll = 3500 }
}

Config.Cooldown       = 800    -- ms, damit Schrotkugeln (viele Treffer auf einmal) nur einmal schleudern
Config.InVehicle      = false  -- auch im Fahrzeug umwerfen (zieht aus dem Fahrzeug, meist nicht gewollt)
Config.WhenDead       = true   -- tödliche Treffer schleudern den Körper auch nach hinten
Config.CameraShake    = 0.35   -- Kamerawackeln beim Getroffenen (0 = aus)

-- Testbefehl ohne zweiten Spieler: /knocktest [wucht] [hoch]
-- Auf dem Live-Server ausschalten (enabled = false) oder per ACE beschränken (restricted = true,
-- in der server.cfg: add_ace group.admin command.knocktest allow)
Config.TestCommand = { enabled = true, name = 'knocktest', restricted = false, force = 30, up = 4, ragdoll = 2500 }
