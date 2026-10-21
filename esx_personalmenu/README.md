# esx_personalmenu – Persönliches F5-Menü für ESX

Ein persönliches Menü auf Basis von **esx_menu_default** (`ESX.UI.Menu`).

## Funktionen

| Bereich | Inhalt |
|---|---|
| **Brieftasche & Lizenzen** | Ausweis, Führerschein und Waffenschein ansehen oder der nächsten Person zeigen (über **jsfour-idcard**). Außerdem gibt es eine Liste aller eigenen Lizenzen. |
| **Kontostand** | Bargeld, Bankkonto, Schwarzgeld (abschaltbar), Job, Rang und Gehalt |
| **Rechnungen** | Offene Rechnungen ansehen und bezahlen (**esx_billing**, wird nur angezeigt, wenn die Resource läuft) |
| **Fraktion** | Zeigt Job, Rang und Gehalt. Jeder kann selbst **kündigen**. |
| **Fraktion (höchster Rang)** | Firmenkonto anzeigen. Mitarbeiter in der Nähe **befördern, degradieren und feuern**. Personen in der Nähe **einstellen** (mit Jobangebot zum Annehmen oder Ablehnen). Mitarbeiterliste inklusive Offline-Mitarbeitern. |
| **Fahrzeug** | Motor an/aus, Türen, Motorhaube, Kofferraum und Fenster (nur als Fahrer sichtbar) |
| **Admin-Bereich** | Nur sichtbar mit passender Gruppe. Enthält nur `/aduty` und `/noclip` aus eurem Admin-System. |

## Voraussetzungen

- `es_extended` (ESX Legacy oder 1.2 mit `getSharedObject`)
- `esx_menu_default`
- `oxmysql`
- `jsfour-idcard` (für Ausweise)
- Optional: `esx_billing` und `esx_addonaccount`/`esx_society` (für das Firmenkonto)
- **OneSync** für die serverseitige Entfernungsprüfung. Ohne OneSync muss `Config.ServerDistanceCheck = false` gesetzt werden.

## Installation

1. Den Ordner `esx_personalmenu` in den `resources`-Ordner kopieren.
2. In die `server.cfg` **nach** ESX, esx_menu_default, oxmysql und jsfour-idcard eintragen:
   ```
   ensure esx_personalmenu
   ```
3. Die `config.lua` anpassen, vor allem `Config.Admin.Groups`.

Das Menü öffnet sich mit **F5**. Spieler können die Taste unter *Einstellungen → Tastenbelegung → FiveM* ändern.

## Fraktionsverwaltung

- Verwalten darf nur, wer den **höchsten Rang** (höchste `grade` in `job_grades`) seines Jobs hat.
- Personen mit dem höchsten Rang können nicht verwaltet werden. Bis auf den höchsten Rang befördern geht nur mit `AllowPromoteToBoss = true`.
- Jede Aktion wird **serverseitig geprüft**: Rang, gleicher Job, Entfernung und ein Cooldown.
- Beim Feuern und Kündigen wird der Job auf `Config.Faction.UnemployedJob` gesetzt.
- Mit `Config.Webhook` können alle Aktionen in einen Discord-Kanal geloggt werden.

## Admin-Bereich

Der Bereich führt nur die Befehle aus `Config.Admin.Actions` aus (Standard: `aduty` und `noclip`). Die Rechteprüfung der Befehle selbst bleibt bei eurem Admin-System. Weitere Befehle trägt man einfach in der Config ein.
