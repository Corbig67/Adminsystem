Config = {}

-- Anzeige ------------------------------------------------------------------------------
Config.UI = {
    brand         = 'PULSE ROLEPLAY',
    currency      = '$',
    quick         = { 1000, 5000, 10000, 50000 },   -- Schnellbeträge in der Firmenkasse
    rankColors    = { '#9AA6B8', '#8FD3FF', '#5FD3C6', '#7FE0A8', '#FFB85C', '#C9A6FF', '#FF8FB8', '#FFE38A' },
    showWeekChange = true                           -- "+ $38.200 diese Woche" unter dem Kontostand
}

-- Öffnen -------------------------------------------------------------------------------
Config.OpenKey       = 38          -- E (INPUT_CONTEXT)
Config.InteractRange = 1.5
Config.MaxDistance   = 5.0         -- serverseitig: so weit darf man sich vom Bossmenü-Punkt entfernen (OneSync)
Config.Command       = false       -- z. B. 'bossmenu' um das Menü per Befehl zu öffnen, false = aus
Config.AllowAnywhere = false       -- true = Öffnen ohne Bossmenü-Punkt erlaubt (für Config.Command oder exports/ox_target)
Config.Marker = { type = 22, size = vector3(0.5, 0.5, 0.4), color = { r = 47, g = 123, b = 255, a = 160 }, drawDistance = 10.0, bob = true, rotate = true }
Config.HelpText = 'Drücke ~INPUT_CONTEXT~, um das Bossmenü zu öffnen'

-- Bossmenü-Punkt per Befehl setzen ------------------------------------------------------
-- /setboss <job> setzt den Punkt an deiner Position (wird in der Datenbank gespeichert),
-- /delboss <job> löscht gesetzte Punkte wieder (dann gelten die Punkte aus Config.Jobs).
-- Gesetzte Punkte ersetzen die Punkte aus Config.Jobs für diesen Job.
-- Jobs, die nicht in Config.Jobs stehen, bekommen damit ebenfalls ein Bossmenü (mit Standardrechten).
Config.SetBoss = {
    command    = 'setboss',                     -- false = aus
    delCommand = 'delboss',                     -- false = aus
    groups     = { 'admin', 'superadmin' },     -- ESX-Gruppen, die die Befehle nutzen dürfen
    mode       = 'replace'                      -- 'replace' = alter Punkt wird ersetzt, 'add' = weiterer Punkt
}

-- Rechte -------------------------------------------------------------------------------
-- Wer darf welchen Bereich nutzen?
--   'boss'          = nur der höchste Rang
--   3               = ab Rang 3
--   { 3, 5 }        = nur genau diese Ränge
--   false           = niemand
Config.Permissions = {
    members  = 'boss',     -- einstellen, befördern, degradieren, entlassen
    funds    = 'boss',     -- Firmenkasse
    settings = 'boss',     -- Gehälter und Einstellungen
    logs     = 'boss'      -- Protokoll
}

Config.Rules = {
    onlyLowerGrades   = true,         -- nur Mitglieder mit niedrigerem Rang als man selbst bearbeiten
    maxAssignGrade    = 'below_own',  -- höchster vergebbarer Rang: 'below_own' | 'own' | 'any'
    unemployedJob     = 'unemployed', -- Job nach dem Entlassen
    unemployedGrade   = 0,
    maxSalary         = 50000,        -- höchstes Gehalt, das im Menü eingestellt werden kann
    actionCooldown    = 750           -- ms zwischen zwei Aktionen eines Spielers
}

-- Fraktionen ------------------------------------------------------------------------------
-- locations: Bossmenü-Punkte. permissions (optional): überschreibt Config.Permissions für diesen Job.
-- society (optional): anderer Kontoname als Config.Society.prefix .. job
Config.Jobs = {
    police = {
        locations = { vector3(461.4, -985.4, 30.7) }
    },
    ambulance = {
        locations = { vector3(335.5, -594.5, 43.3) }
    },
    mechanic = {
        locations = { vector3(-339.6, -156.1, 44.6) },
        permissions = { funds = 3 }
    }
}

-- Firmenkasse ------------------------------------------------------------------------------
Config.Society = {
    prefix = 'society_'            -- esx_addonaccount: Konto society_<job>
}

Config.Funds = {
    depositFrom = 'money',         -- Spielerkonto für Einzahlungen: 'money' (Bargeld) oder 'bank'
    withdrawTo  = 'money',         -- Spielerkonto für Auszahlungen
    min         = 1,
    max         = 10000000
}

-- Einladung ---------------------------------------------------------------------------------
Config.Invite = {
    distance   = 5.0,              -- "Spieler in der Nähe" (OneSync), Radius in Metern
    timeout    = 30,               -- Sekunden bis die Einladung abläuft
    acceptKey  = 246,              -- Y
    declineKey = 306,              -- N
    text       = 'Du wurdest eingeladen, der Fraktion beizutreten.'
}

-- Dienst-Status ("Im Dienst" in der Mitgliederliste) -------------------------------------------
--   'online' = online ist im Dienst
--   'duty'   = ESX-Dienststatus (xPlayer.job.onDuty, ESX Legacy 1.10+)
Config.DutyMode = 'online'

-- Einstellungen in der UI (Schalter) ------------------------------------------------------------
-- Nur Schalter, die hier stehen, erscheinen im Menü. Werte = Standard für neue Fraktionen.
-- payFromSociety / offDutyPay wirken nur mit Config.Payday.enabled = true.
Config.DefaultSettings = {
    notifyAll      = true,         -- alle Mitglieder online sehen Beförderungen, Einstellungen usw.
    payFromSociety = true,
    offDutyPay     = false
}

-- Eigener Zahltag ---------------------------------------------------------------------------------
-- Zahlt Gehälter der Jobs aus Config.Jobs selbst aus und beachtet die Schalter oben.
-- Wenn aktiv, die Zahltage von ESX für diese Jobs abschalten (z. B. Gehälter in ESX auf 0 lassen
-- oder Config.PaycheckInterval in es_extended hochsetzen), sonst wird doppelt gezahlt.
Config.Payday = {
    enabled  = false,
    interval = 15,                 -- Minuten
    account  = 'bank'              -- Spielerkonto, auf das das Gehalt geht
}

-- Protokoll / Buchungen ---------------------------------------------------------------------------
Config.History = {
    transactions = 50,             -- so viele Buchungen werden angezeigt
    logs         = 100,            -- so viele Protokolleinträge werden angezeigt
    keepDays     = 30              -- ältere Einträge werden beim Start gelöscht (0 = nie)
}

-- Discord-Webhook für alle Aktionen (leer = aus), pro Job überschreibbar mit Config.Jobs.<job>.webhook
Config.Webhook = ''

-- Benachrichtigung (serverseitig) ------------------------------------------------------------------
Config.Notify = function(source, text, notifyType)
    TriggerClientEvent('pulse_bossmenu:notify', source, text, notifyType)
end

-- Texte ----------------------------------------------------------------------------------------------
Config.Locale = {
    noAccess         = 'Dafür fehlt dir die Berechtigung',
    notInJob         = 'Du gehörst nicht zu dieser Fraktion',
    tooFar           = 'Du bist zu weit entfernt',
    notOpen          = 'Das Bossmenü ist nicht geöffnet',
    wait             = 'Bitte warte kurz',
    memberNotFound   = 'Mitglied nicht gefunden',
    notYourself      = 'Das kannst du nicht bei dir selbst machen',
    gradeTooHigh     = 'Dieser Rang ist zu hoch für dich',
    gradeInvalid     = 'Ungültiger Rang',
    targetTooHigh    = 'Du kannst nur Mitglieder mit niedrigerem Rang bearbeiten',
    playerNotFound   = 'Spieler nicht gefunden',
    alreadyMember    = 'Diese Person ist bereits in der Fraktion',
    alreadyInvited   = 'Diese Person hat bereits eine offene Einladung',
    inviteExpired    = 'Die Einladung ist abgelaufen',
    amountInvalid    = 'Ungültiger Betrag',
    amountMin        = 'Der Betrag ist zu klein',
    amountMax        = 'Der Betrag ist zu groß',
    notEnoughMoney   = 'Du hast nicht genug Geld dabei',
    notEnoughSociety = 'So viel ist nicht in der Kasse',
    societyMissing   = 'Für diese Fraktion gibt es keine Firmenkasse',
    salaryTooHigh    = 'Das Gehalt ist zu hoch (max. %s)',
    setBossUsage     = 'Benutzung: /%s <job>',
    setBossDone      = 'Bossmenü-Punkt für %s gesetzt',
    delBossDone      = 'Gesetzte Bossmenü-Punkte für %s gelöscht',
    delBossNone      = 'Für %s sind keine Punkte per Befehl gesetzt',
    jobNotFound      = 'Den Job %s gibt es nicht',
    noOneSync        = 'Spieler in der Nähe können nur mit OneSync gesucht werden',
    error            = 'Es ist ein Fehler aufgetreten',

    inviteAccepted   = '%s hat die Einladung angenommen',
    inviteDeclined   = '%s hat die Einladung abgelehnt',
    inviteTimedOut   = '%s hat nicht auf die Einladung reagiert',
    welcome          = 'Willkommen bei %s',
    youWerePromoted  = 'Du wurdest zum %s befördert',
    youWereDemoted   = 'Du wurdest zum %s zurückgestuft',
    youWereFired     = 'Du wurdest aus %s entlassen',
    paydayPaid       = 'Zahltag: %s erhalten',
    paydayNoMoney    = 'Zahltag: Die Firmenkasse ist leer, kein Gehalt',

    -- Protokoll
    logHire          = '%s als %s eingestellt',
    logFire          = '%s entlassen',
    logPromote       = '%s zum %s befördert',
    logDemote        = '%s zum %s zurückgestuft',
    logDeposit       = '%s in die Firmenkasse eingezahlt',
    logWithdraw      = '%s ausgezahlt',
    logSalary        = 'Gehalt für %s auf %s geändert',
    logSetting       = '%s %s',
    settingOn        = 'eingeschaltet',
    settingOff       = 'ausgeschaltet',
    settingNames     = { notifyAll = 'Änderungen melden', payFromSociety = 'Gehalt aus der Firmenkasse', offDutyPay = 'Gehalt außer Dienst' },

    -- Buchungen
    txDeposit        = 'Einzahlung',
    txWithdraw       = 'Auszahlung',
    txPayday         = 'Gehälter Zahltag',
    system           = 'System',
    weekChange       = '%s %s diese Woche',

    -- Zeiten
    justNow          = 'gerade eben',
    minutesAgo       = 'vor %d Min',
    hoursAgo         = 'vor %d Std',
    yesterday        = 'Gestern',
    today            = 'Heute'
}
