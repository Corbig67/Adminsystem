Config = {}

-- Welche Waffen zählen als Schuss? (Faustschläge, Stürze, Fahrzeuge usw. lösen keine Verletzung aus)
-- Gruppen: https://docs.fivem.net/natives/?_0xC3287EE3050FB74C
Config.WeaponGroups = {
    `GROUP_PISTOL`, `GROUP_SMG`, `GROUP_RIFLE`, `GROUP_MG`, `GROUP_SHOTGUN`, `GROUP_SNIPER`, `GROUP_HEAVY`
}
Config.IgnoredWeapons = {
    `WEAPON_STUNGUN`, `WEAPON_STUNGUN_MP`
}

-- Kopf ------------------------------------------------------------------------------------------
Config.Head = {
    enabled    = true,
    killChance = 1.0,           -- 1.0 = jeder Kopfschuss tötet sofort, 0.5 = jeder zweite
    -- Helme, die vor dem Sofort-Tod schützen (Prop-Index 0 = Kopf). Leer = kein Schutz.
    -- Beispiel: male = { 150, 151 }, female = { 149 }
    helmets    = { male = {}, female = {} }
}

-- Beine -------------------------------------------------------------------------------------------
Config.Leg = {
    enabled     = true,
    fallChance  = 1.0,          -- Wahrscheinlichkeit hinzufallen
    ragdollTime = 3000,         -- ms am Boden
    duration    = 300,          -- Sekunden humpeln (0 = bis zur Behandlung)
    moveRate    = 0.80,         -- Gehgeschwindigkeit (1.0 = normal)
    bothLegsMoveRate = 0.60,    -- wenn beide Beine getroffen sind
    noSprint    = true,         -- nicht rennen
    noJump      = true,         -- nicht springen
    clipset     = { male = 'move_m@injured', female = 'move_f@injured' }
}

-- Arme --------------------------------------------------------------------------------------------
-- "Schusshand" ist der rechte Arm. Mit verletztem Arm sind nur noch einhändige Waffen möglich.
Config.Arm = {
    enabled         = true,
    duration        = 300,      -- Sekunden (0 = bis zur Behandlung)
    disarmChance    = 0.5,      -- Treffer in den rechten Arm: Waffe wird aus der Hand gerissen (bleibt im Inventar)
    shake           = 1.2,      -- Wackeln beim Zielen, ein Arm verletzt
    shakeShootHand  = 2.5,      -- Wackeln beim Zielen, rechter Arm verletzt
    noTwoHanded     = true,     -- keine Langwaffen mehr (Gruppen unten)
    bothArmsNoShoot = true,     -- beide Arme verletzt: gar nicht mehr schießen
    twoHandedGroups = { `GROUP_RIFLE`, `GROUP_MG`, `GROUP_SHOTGUN`, `GROUP_SNIPER`, `GROUP_HEAVY`, `GROUP_SMG` }
}

-- Oberkörper / Blutung ------------------------------------------------------------------------------
Config.Bleeding = {
    enabled  = true,
    zones    = { torso = true, leftLeg = true, rightLeg = true, leftArm = true, rightArm = true },
    interval = 10,              -- Sekunden zwischen zwei Blutverlusten
    damage   = 2,               -- HP pro Treffer und Intervall (mehrere Treffer bluten stärker)
    maxStack = 3,               -- höchstens so viele Treffer zählen für die Blutung
    stopAt   = 120,             -- Blutung tötet nicht unter diesen HP-Wert (100 = tot, 0 = Blutung kann töten)
    duration = 180              -- Sekunden bis die Blutung von selbst aufhört (0 = bis zur Behandlung)
}

-- Treffer-Effekt --------------------------------------------------------------------------------------
Config.HitShake = 0.15          -- kurzes Kamerawackeln bei jedem Treffer (0 = aus)

-- Heilung ---------------------------------------------------------------------------------------------
-- Verletzungen verschwinden bei: Wiederbelebung/Respawn, voller Gesundheit nach einer Verletzung (z. B. Medikit),
-- den Events unten oder exports.pulse_damage:Heal()
Config.HealOnFullHealth = true
Config.HealEvents = {
    'esx_ambulancejob:revive',
    'esx_ambulancejob:heal',
    'esx_basicneeds:healPlayer',
    'hospital:client:Revive',
    'hospital:client:HealInjuries'
}

-- Befehl, der die eigenen Verletzungen anzeigt (false = aus)
Config.Command = 'verletzungen'

-- Benachrichtigung ---------------------------------------------------------------------------------------
Config.Notify = function(text)
    if GetResourceState('es_extended') == 'started' then
        local ok, ESX = pcall(function() return exports['es_extended']:getSharedObject() end)
        if ok and ESX then return ESX.ShowNotification(text) end
    end
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandThefeedPostTicker(false, false)
end

Config.Locale = {
    leg         = 'Du wurdest ins Bein getroffen',
    arm         = 'Du wurdest in den Arm getroffen',
    shootArm    = 'Deine Schusshand ist verletzt',
    disarmed    = 'Dir wurde die Waffe aus der Hand gerissen',
    noTwoHanded = 'Mit verletztem Arm kannst du keine Langwaffe halten',
    torso       = 'Du wurdest am Oberkörper getroffen und blutest',
    healed      = 'Deine Verletzungen wurden behandelt',
    none        = 'Du bist nicht verletzt',
    list        = 'Verletzungen: %s',
    zones       = { leftLeg = 'linkes Bein', rightLeg = 'rechtes Bein', leftArm = 'linker Arm', rightArm = 'rechter Arm', torso = 'Oberkörper', bleeding = 'Blutung' }
}
