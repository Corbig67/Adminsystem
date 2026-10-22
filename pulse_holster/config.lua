Config = {}

-- Polizei-Animation ---------------------------------------------------------------
-- duration = Länge in ms
-- swap     = Zeitpunkt in ms, an dem Holster-Kleidung und Sound wechseln (Waffe rastet ein / wird gelöst)
-- show     = (nur Ziehen) ab wann die Waffe in der Hand sichtbar ist
-- cancel   = Animation nach duration abbrechen
Config.Animation = {
    holster   = { dict = 'reaction@intimidation@cop@unarmed', clip = 'intro',             duration = 400, swap = 300 },
    unholster = { dict = 'rcmjosh4',                          clip = 'josh_leadout_cop2', duration = 300, swap = 0, show = 120, cancel = true }
}

-- Für welche Waffen die Animation läuft (Waffengruppen und/oder einzelne Waffen).
-- Gruppen: https://docs.fivem.net/natives/?_0xC3287EE3050FB74C
Config.WeaponGroups = {
    `GROUP_PISTOL`,
    `GROUP_STUNGUN`
}
Config.Weapons = {
    -- `WEAPON_FLASHLIGHT`,
}
-- Diese Waffen nie animieren (auch wenn ihre Gruppe oben steht)
Config.IgnoredWeapons = {
    -- `WEAPON_FLAREGUN`,
}

-- Pause in ms zwischen Wegstecken und Ziehen beim Waffenwechsel (z. B. Pistole -> Taser)
Config.SwitchDelay = 80

-- Sound --------------------------------------------------------------------------
Config.Sound = {
    enabled = true,
    -- 'game' = echte GTA-Waffensounds (scharf, kommen aus der Spielfigur, andere hören sie automatisch)
    -- 'file' = eigene .ogg-Dateien aus html/sounds/
    mode    = 'game',
    others  = true,            -- andere Spieler in der Nähe hören den Sound

    game = {
        holster   = { name = 'PICK_UP_WEAPON',  set = 'HUD_FRONTEND_CUSTOM_SOUNDSET' },
        unholster = { name = 'WEAPON_PURCHASE', set = 'HUD_AMMO_SHOP_SOUNDSET' }
    },

    file = {
        volume    = 0.5,           -- 0.0 - 1.0
        range     = 8.0,           -- Hörweite für andere Spieler
        holster   = 'holster.ogg',
        unholster = 'unholster.ogg'
    }
}

-- Holster-Kleidung -----------------------------------------------------------------
-- Wechselt die Holster-Kleidung beim Ziehen/Wegstecken (Waffe im Holster <-> leeres Holster).
-- variation: Komponente (7 = Hals/Accessoires), male/female = { mit Waffe, leer }
Config.Holsters = {
    { weapons = { `WEAPON_COMBATPISTOL` }, variation = 7, male = { 192, 193 } },
    { weapons = { `WEAPON_COMBATPISTOL` }, variation = 7, male = { 196, 197 }, female = { 148, 149 } },
    { weapons = { `WEAPON_COMBATPISTOL` }, variation = 7, male = { 194, 195 } },
    { weapons = { `WEAPON_COMBATPISTOL` }, variation = 7, male = { 203, 205 } },
    { weapons = { `WEAPON_COMBATPISTOL` }, variation = 7, male = { 206, 204 } }
}
