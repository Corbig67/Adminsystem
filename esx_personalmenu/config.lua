Config = {}

-- Allgemein --------------------------------------------------------------
Config.OpenKey   = 'F5'               -- Standardtaste (Spieler können sie in den GTA-Einstellungen ändern)
Config.Command   = 'personalmenu'     -- Befehl, an den die Taste gebunden ist
Config.MenuTitle = 'Persönliches Menü'
Config.MenuAlign = 'top-left'         -- top-left, top-right, bottom-left, bottom-right, center ...

-- Prüft Entfernungen zusätzlich serverseitig (benötigt OneSync)
Config.ServerDistanceCheck = true

-- Discord-Webhook für Fraktionsaktionen (leer = aus)
Config.Webhook = ''

-- Brieftasche / jsfour-idcard -------------------------------------------
Config.IdCard = {
    Enabled        = true,
    Resource       = 'jsfour-idcard',
    ShowDistance   = 3.0,             -- max. Entfernung zum Zeigen der Karten
    RequireLicense = true,            -- Führerschein/Waffenschein nur, wenn die Lizenz vorhanden ist
    DriverLicenses = { 'drive', 'drive_bike', 'drive_truck' },
    WeaponLicenses = { 'weapon' }
}

-- Konto -------------------------------------------------------------------
Config.ShowBlackMoney = true

-- Rechnungen (esx_billing) ------------------------------------------------
Config.EnableBilling = true

-- Fahrzeugmenü (nur als Fahrer sichtbar) -----------------------------------
Config.EnableVehicleMenu = true

-- Fraktionsverwaltung -----------------------------------------------------
-- Verwalten darf nur, wer den HÖCHSTEN Rang seines Jobs hat.
Config.Faction = {
    Enabled               = true,
    UnemployedJob         = 'unemployed',
    BlacklistedJobs       = { 'unemployed' }, -- Jobs ohne Verwaltung
    NearbyDistance        = 5.0,              -- Radius für "Personen in der Nähe"
    AllowRemoteManagement = true,             -- Mitarbeiterliste (auch offline) verwalten
    AllowPromoteToBoss    = false,            -- darf bis auf den höchsten Rang befördert werden?
    RequireAcceptance     = true,             -- Eingestellte Person muss das Jobangebot annehmen
    OfferTimeout          = 30,               -- Sekunden bis ein Jobangebot verfällt
    ShowSocietyMoney      = true,             -- Firmenkonto anzeigen (esx_addonaccount)
    AllowResign           = true              -- Spieler können selbst kündigen
}

-- Admin-Bereich -----------------------------------------------------------
-- Wird nur angezeigt, wenn der Spieler eine der Gruppen hat.
Config.Admin = {
    Enabled           = true,
    Groups            = { 'superadmin', 'admin', 'mod' },
    CloseMenuOnAction = true,
    Actions = {
        { label = 'Admin-Dienst (/aduty)', command = 'aduty' },
        { label = 'Noclip (/noclip)',      command = 'noclip' }
    }
}
