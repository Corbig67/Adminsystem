# pulse_bossmenu

Bossmenü für ESX mit Mitgliederverwaltung, Fraktionseinladung, Firmenkasse, Gehältern, Einstellungen und Protokoll.
Alles außer den Tabellennamen wird in der `config.lua` eingestellt.

## Abhängigkeiten

- `es_extended` (ESX Legacy)
- `esx_addonaccount` (Firmenkasse `society_<job>`)
- `oxmysql`
- OneSync für „Spieler in der Nähe“ und die Entfernungsprüfung

## Installation

1. Ordner `pulse_bossmenu` in `resources` legen.
2. `server.cfg`: `ensure pulse_bossmenu` (nach ESX, esx_addonaccount, oxmysql).
3. Tabellen werden beim Start automatisch angelegt (`sql/install.sql` gibt es zusätzlich).
4. In `config.lua` unter `Config.Jobs` die Fraktionen und Bossmenü-Punkte eintragen.
5. Optional: Logo als `html/img/logo.png`.

## Funktionen

| Bereich | Was passiert |
|---|---|
| Mitglieder | Liste aus `users` (auch offline), online/im Dienst, „Dabei seit“; befördern, degradieren, entlassen |
| Einstellen | Spieler in der Nähe einladen, Einladung mit Y/N annehmen oder ablehnen (ohne Maus), läuft nach Zeit ab |
| Firmenkasse | Ein- und Auszahlen über esx_addonaccount, Buchungsliste, Wochenbilanz |
| Einstellungen | Gehälter pro Rang (schreibt `job_grades`, wirkt sofort), Schalter aus `Config.DefaultSettings` |
| Protokoll | Alle Aktionen mit Name und Zeit, optional Discord-Webhook |
| Zahltag | Optional eigener Zahltag mit „Gehalt aus der Firmenkasse“ / „Gehalt außer Dienst“ |

Mehrere Chefs gleichzeitig: Änderungen erscheinen sofort in allen offenen Bossmenüs derselben Fraktion.

## Sicherheit

Der Server prüft bei jeder Aktion Job, Rechte, Entfernung zum Bossmenü-Punkt, Ränge (nur niedrigere Ränge bearbeiten,
höchster vergebbarer Rang), Beträge und Kassenstand. Die UI zeigt nur an.

## Konfiguration (Auszug)

| Einstellung | Bedeutung |
|---|---|
| `Config.Jobs` | Fraktionen, Bossmenü-Punkte, eigene Rechte / Kontoname / Webhook pro Job |
| `Config.Permissions` | `'boss'`, ab Rang `3`, genaue Ränge `{3, 5}` oder `false` – je Bereich |
| `Config.Rules` | Nur niedrigere Ränge bearbeiten, höchster vergebbarer Rang, Job nach Entlassung, max. Gehalt, Cooldown |
| `Config.Funds` | Konto für Ein-/Auszahlung (Bargeld/Bank), Mindest- und Höchstbetrag |
| `Config.Invite` | Radius, Zeit, Tasten, Text |
| `Config.DutyMode` | „Im Dienst“ = online oder ESX-Dienststatus |
| `Config.Payday` | Eigener Zahltag an/aus, Intervall, Konto |
| `Config.History` | Anzahl angezeigter Einträge, automatische Löschung nach Tagen |
| `Config.UI` | Servername, Währung, Schnellbeträge, Rangfarben, Wochenbilanz |
| `Config.Command` / `Config.AllowAnywhere` | Öffnen per Befehl oder aus anderen Scripts |
| `Config.Notify` | Eigene Benachrichtigung (z. B. ox_lib) |
| `Config.Locale` | Alle Texte |

## Aus anderen Scripts öffnen (z. B. ox_target)

```lua
exports.pulse_bossmenu:OpenBossMenu(1)   -- Index des Punkts aus Config.Jobs.<job>.locations
exports.pulse_bossmenu:OpenBossMenu()    -- ohne Punkt, nur mit Config.AllowAnywhere = true
```

## Tabellen (fest)

`pulse_bossmenu_logs`, `pulse_bossmenu_transactions`, `pulse_bossmenu_settings`, `pulse_bossmenu_members`
