Config = {}

--[[
    PULSE SYNC
    ----------
    Werte pro Waffengruppe, einzelne Waffen können alles überschreiben (siehe Config.Weapons).

    damage            Schadens-Multiplikator (1.0 = GTA-Standard)
    recoil            Rückstoß nach oben pro Schuss in Grad (0 = aus)
    horizontal        zufälliger Rückstoß zur Seite in Grad
    range             max. Entfernung in Metern, auf die ein Treffer gültig ist (Server-Prüfung)
    maxDamage         max. Schaden pro Treffer (Server-Prüfung, nil = keine Grenze)
    maxHitsPerSecond  max. Treffer pro Sekunde (Server-Prüfung)
    checkHeld         Server prüft, ob der Schütze die Waffe wirklich in der Hand hat
]]

Config.Groups = {
    pistol  = { damage = 1.0, recoil = 0.55, horizontal = 0.12, range = 120,  maxDamage = 300,  maxHitsPerSecond = 8,  checkHeld = true },
    smg     = { damage = 1.0, recoil = 0.30, horizontal = 0.15, range = 150,  maxDamage = 250,  maxHitsPerSecond = 20, checkHeld = true },
    rifle   = { damage = 1.0, recoil = 0.38, horizontal = 0.12, range = 300,  maxDamage = 300,  maxHitsPerSecond = 16, checkHeld = true },
    mg      = { damage = 1.0, recoil = 0.45, horizontal = 0.20, range = 300,  maxDamage = 300,  maxHitsPerSecond = 25, checkHeld = true },
    shotgun = { damage = 1.0, recoil = 2.20, horizontal = 0.30, range = 60,   maxDamage = 400,  maxHitsPerSecond = 40, checkHeld = true },
    sniper  = { damage = 1.0, recoil = 2.80, horizontal = 0.20, range = 1500, maxDamage = 1000, maxHitsPerSecond = 4,  checkHeld = true },
    heavy   = { damage = 1.0, recoil = 1.50, horizontal = 0.20, range = 1000, maxDamage = nil,  maxHitsPerSecond = 60, checkHeld = false },
    melee   = { damage = 1.0, recoil = 0.0,  horizontal = 0.0,  range = 8,    maxDamage = 300,  maxHitsPerSecond = 6,  checkHeld = true },
    thrown  = { damage = 1.0, recoil = 0.0,  horizontal = 0.0,  range = 200,  maxDamage = nil,  maxHitsPerSecond = 60, checkHeld = false },
    misc    = { damage = 1.0, recoil = 0.0,  horizontal = 0.0,  range = 30,   maxDamage = nil,  maxHitsPerSecond = 30, checkHeld = false }
}

-- Alle GTA-Standardwaffen. allowed = false sperrt eine Waffe komplett (wird entfernt, Treffer zählen nicht).
Config.Weapons = {
    -- Nahkampf
    WEAPON_UNARMED = { group = 'melee' },
    WEAPON_DAGGER = { group = 'melee' }, WEAPON_BAT = { group = 'melee' }, WEAPON_BOTTLE = { group = 'melee' },
    WEAPON_CROWBAR = { group = 'melee' }, WEAPON_FLASHLIGHT = { group = 'melee' }, WEAPON_GOLFCLUB = { group = 'melee' },
    WEAPON_HAMMER = { group = 'melee' }, WEAPON_HATCHET = { group = 'melee' }, WEAPON_KNUCKLE = { group = 'melee' },
    WEAPON_KNIFE = { group = 'melee' }, WEAPON_MACHETE = { group = 'melee' }, WEAPON_SWITCHBLADE = { group = 'melee' },
    WEAPON_NIGHTSTICK = { group = 'melee' }, WEAPON_WRENCH = { group = 'melee' }, WEAPON_BATTLEAXE = { group = 'melee' },
    WEAPON_POOLCUE = { group = 'melee' }, WEAPON_STONE_HATCHET = { group = 'melee' }, WEAPON_CANDYCANE = { group = 'melee' },

    -- Pistolen
    WEAPON_PISTOL = { group = 'pistol' },
    WEAPON_PISTOL_MK2 = { group = 'pistol' },
    WEAPON_COMBATPISTOL = { group = 'pistol' },
    WEAPON_APPISTOL = { group = 'pistol', recoil = 0.35, maxHitsPerSecond = 16 },
    WEAPON_STUNGUN = { group = 'pistol', recoil = 0.2, range = 15 },
    WEAPON_STUNGUN_MP = { group = 'pistol', recoil = 0.2, range = 15 },
    WEAPON_PISTOL50 = { group = 'pistol', recoil = 1.10 },
    WEAPON_SNSPISTOL = { group = 'pistol', recoil = 0.65 },
    WEAPON_SNSPISTOL_MK2 = { group = 'pistol', recoil = 0.65 },
    WEAPON_HEAVYPISTOL = { group = 'pistol', recoil = 0.80 },
    WEAPON_VINTAGEPISTOL = { group = 'pistol' },
    WEAPON_FLAREGUN = { group = 'pistol', recoil = 1.0, checkHeld = false },
    WEAPON_MARKSMANPISTOL = { group = 'pistol', recoil = 1.6, range = 200 },
    WEAPON_REVOLVER = { group = 'pistol', recoil = 1.8 },
    WEAPON_REVOLVER_MK2 = { group = 'pistol', recoil = 1.8 },
    WEAPON_DOUBLEACTION = { group = 'pistol', recoil = 1.4 },
    WEAPON_RAYPISTOL = { group = 'pistol', recoil = 0.3 },
    WEAPON_CERAMICPISTOL = { group = 'pistol' },
    WEAPON_NAVYREVOLVER = { group = 'pistol', recoil = 1.6 },
    WEAPON_GADGETPISTOL = { group = 'pistol', recoil = 1.2 },
    WEAPON_PISTOLXM3 = { group = 'pistol' },

    -- Maschinenpistolen
    WEAPON_MICROSMG = { group = 'smg', recoil = 0.40, horizontal = 0.22 },
    WEAPON_SMG = { group = 'smg' },
    WEAPON_SMG_MK2 = { group = 'smg' },
    WEAPON_ASSAULTSMG = { group = 'smg' },
    WEAPON_COMBATPDW = { group = 'smg' },
    WEAPON_MACHINEPISTOL = { group = 'smg', recoil = 0.42, horizontal = 0.22 },
    WEAPON_MINISMG = { group = 'smg', recoil = 0.40, horizontal = 0.20 },
    WEAPON_RAYCARBINE = { group = 'smg' },
    WEAPON_TECPISTOL = { group = 'smg', recoil = 0.40 },

    -- Schrotflinten
    WEAPON_PUMPSHOTGUN = { group = 'shotgun' },
    WEAPON_PUMPSHOTGUN_MK2 = { group = 'shotgun' },
    WEAPON_SAWNOFFSHOTGUN = { group = 'shotgun', recoil = 2.6, range = 40 },
    WEAPON_ASSAULTSHOTGUN = { group = 'shotgun', recoil = 1.2, maxHitsPerSecond = 60 },
    WEAPON_BULLPUPSHOTGUN = { group = 'shotgun' },
    WEAPON_MUSKET = { group = 'shotgun', recoil = 3.0, range = 150 },
    WEAPON_HEAVYSHOTGUN = { group = 'shotgun', recoil = 1.6, maxHitsPerSecond = 50 },
    WEAPON_DBSHOTGUN = { group = 'shotgun', recoil = 2.8, range = 40 },
    WEAPON_AUTOSHOTGUN = { group = 'shotgun', recoil = 1.0, maxHitsPerSecond = 70 },
    WEAPON_COMBATSHOTGUN = { group = 'shotgun', recoil = 1.4, maxHitsPerSecond = 50 },

    -- Sturmgewehre
    WEAPON_ASSAULTRIFLE = { group = 'rifle', recoil = 0.45, horizontal = 0.16 },
    WEAPON_ASSAULTRIFLE_MK2 = { group = 'rifle', recoil = 0.42, horizontal = 0.15 },
    WEAPON_CARBINERIFLE = { group = 'rifle' },
    WEAPON_CARBINERIFLE_MK2 = { group = 'rifle' },
    WEAPON_ADVANCEDRIFLE = { group = 'rifle', recoil = 0.32 },
    WEAPON_SPECIALCARBINE = { group = 'rifle' },
    WEAPON_SPECIALCARBINE_MK2 = { group = 'rifle' },
    WEAPON_BULLPUPRIFLE = { group = 'rifle' },
    WEAPON_BULLPUPRIFLE_MK2 = { group = 'rifle' },
    WEAPON_COMPACTRIFLE = { group = 'rifle', recoil = 0.50, horizontal = 0.20 },
    WEAPON_MILITARYRIFLE = { group = 'rifle' },
    WEAPON_HEAVYRIFLE = { group = 'rifle', recoil = 0.48 },
    WEAPON_TACTICALRIFLE = { group = 'rifle' },
    WEAPON_BATTLERIFLE = { group = 'rifle', recoil = 0.60 },

    -- Maschinengewehre
    WEAPON_MG = { group = 'mg' },
    WEAPON_COMBATMG = { group = 'mg' },
    WEAPON_COMBATMG_MK2 = { group = 'mg' },
    WEAPON_GUSENBERG = { group = 'mg', recoil = 0.40, range = 150 },

    -- Scharfschützengewehre
    WEAPON_SNIPERRIFLE = { group = 'sniper' },
    WEAPON_HEAVYSNIPER = { group = 'sniper', recoil = 3.4 },
    WEAPON_HEAVYSNIPER_MK2 = { group = 'sniper', recoil = 3.4 },
    WEAPON_MARKSMANRIFLE = { group = 'sniper', recoil = 1.4, maxHitsPerSecond = 8 },
    WEAPON_MARKSMANRIFLE_MK2 = { group = 'sniper', recoil = 1.4, maxHitsPerSecond = 8 },
    WEAPON_PRECISIONRIFLE = { group = 'sniper', recoil = 2.0 },

    -- Schwere Waffen
    WEAPON_RPG = { group = 'heavy' },
    WEAPON_GRENADELAUNCHER = { group = 'heavy' },
    WEAPON_GRENADELAUNCHER_SMOKE = { group = 'heavy' },
    WEAPON_MINIGUN = { group = 'heavy', recoil = 0.15, maxHitsPerSecond = 120 },
    WEAPON_FIREWORK = { group = 'heavy' },
    WEAPON_RAILGUN = { group = 'heavy' },
    WEAPON_HOMINGLAUNCHER = { group = 'heavy' },
    WEAPON_COMPACTLAUNCHER = { group = 'heavy' },
    WEAPON_RAYMINIGUN = { group = 'heavy', recoil = 0.15, maxHitsPerSecond = 120 },
    WEAPON_EMPLAUNCHER = { group = 'heavy' },
    WEAPON_RAILGUNXM3 = { group = 'heavy' },

    -- Wurfwaffen
    WEAPON_GRENADE = { group = 'thrown' }, WEAPON_BZGAS = { group = 'thrown' }, WEAPON_MOLOTOV = { group = 'thrown' },
    WEAPON_STICKYBOMB = { group = 'thrown' }, WEAPON_PROXMINE = { group = 'thrown' }, WEAPON_SNOWBALL = { group = 'thrown' },
    WEAPON_PIPEBOMB = { group = 'thrown' }, WEAPON_BALL = { group = 'thrown' }, WEAPON_SMOKEGRENADE = { group = 'thrown' },
    WEAPON_FLARE = { group = 'thrown' }, WEAPON_ACIDPACKAGE = { group = 'thrown' },

    -- Sonstiges
    WEAPON_PETROLCAN = { group = 'misc' }, WEAPON_FIREEXTINGUISHER = { group = 'misc' },
    WEAPON_HAZARDCAN = { group = 'misc' }, WEAPON_FERTILIZERCAN = { group = 'misc' }
}

-- Rückstoß -----------------------------------------------------------------------------------------
-- Standard aus = normaler GTA-Rückstoß. Nur einschalten, wenn ein eigener Rückstoß gewünscht ist.
Config.Recoil = {
    enabled     = false,
    firstPerson = 0.7,      -- Faktor in der Ego-Perspektive
    vehicle     = 1.4,      -- Faktor beim Schießen aus Fahrzeugen
    smoothing   = 0.35      -- wie schnell der Rückstoß die Kamera bewegt (0.1 weich – 1.0 sofort)
}

-- Kein Rückstoß ----------------------------------------------------------------------------------------
-- Entfernt das Hochziehen/Wackeln der Kamera beim Schießen für ganze Gruppen.
-- Einzelne Waffen: noRecoil = true / false in Config.Weapons (überschreibt die Gruppe),
-- z. B. WEAPON_PISTOL50 = { group = 'pistol', noRecoil = false } für etwas Rückstoß bei der .50
Config.NoRecoil = {
    pistol = true
}

-- Kampfregeln (für alle Spieler gleich) --------------------------------------------------------------
Config.Rules = {
    noCombatRoll     = true,     -- keine Kampfrolle beim Zielen
    noPistolWhip     = true,     -- kein Nahkampfschlag mit Schusswaffe in der Hand
    reticle          = 'all',    -- Fadenkreuz: 'all' = immer (GTA-Standard), 'none' = nie, 'snipers' = nur Scharfschützengewehre
    noNpcWeaponDrops = true,     -- getötete NPCs lassen keine Waffen fallen
    headshots        = true,     -- kritische Treffer (Kopfschüsse) an
    meleeDamage      = 1.0       -- Faustschlag-Schaden (Multiplikator)
}

-- Server-Prüfung gegen Cheater -------------------------------------------------------------------------
-- Jede Prüfung: 'cancel' = Treffer verwerfen + melden, 'log' = nur melden, false = aus
Config.Validation = {
    disallowedWeapon = 'cancel',   -- Waffe mit allowed = false
    notHeld          = 'cancel',   -- Schütze hat die Waffe nicht in der Hand
    distance         = 'cancel',   -- Treffer weiter als range
    damage           = 'cancel',   -- Schaden größer als maxDamage
    fireRate         = 'log',      -- mehr Treffer pro Sekunde als maxHitsPerSecond
    heldGrace        = 1500        -- ms: kurz nach einem Waffenwechsel zählt auch die vorige Waffe noch
}

-- Was passiert mit auffälligen Spielern?
Config.Punish = {
    kickAfter = 0,                 -- nach so vielen Meldungen in 5 Minuten kicken (0 = nie, erst Logs beobachten!)
    kickMessage = 'Auffällige Treffer erkannt. Melde dich im Support, falls das ein Fehler ist.',
    webhook = '',                  -- Discord-Webhook für Meldungen (leer = nur Server-Konsole)
    logCooldown = 10               -- Sekunden zwischen zwei Meldungen derselben Art pro Spieler
}

-- Admins (ACE) werden nie gekickt, aber trotzdem geloggt
Config.AdminAce = 'pulse_sync.bypass'
