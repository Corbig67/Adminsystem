# pulse_clothing

Kleidungsladen für ESX mit eigener NUI. Kauf, Preise und Outfits laufen über den Server, Outfits werden in der Datenbank gespeichert.

## Abhängigkeiten

- `es_extended` (ESX Legacy)
- `skinchanger` (esx_skin)
- `oxmysql`

## Installation

1. Ordner `pulse_clothing` in `resources` legen.
2. `sql/install.sql` importieren (oder `Config.AutoCreateTable = true` lassen, dann wird die Tabelle beim Start angelegt).
3. In die `server.cfg` nach ESX, skinchanger und oxmysql:
   ```
   ensure pulse_clothing
   ```
4. Optional: Logo als `html/img/logo.png` ablegen (ohne Datei erscheint ein P).

## Bedienung

Maus oder Tastatur – beides geht gleichzeitig:

| Taste | Aktion |
|---|---|
| `←` `→` | Modell wechseln |
| `↑` `↓` | Variante wechseln |
| `Q` `E` | vorheriges / nächstes Teil (Kategorie) |
| `A` `D` | Spieler drehen |
| `ESC` | Laden ohne Kauf verlassen (alter Skin wird wiederhergestellt) |
| `Enter` im Namensfeld | Kaufen |

## Ablauf

- **Öffnen:** Server prüft die Entfernung zum Laden, lädt den gespeicherten Skin aus `users.skin`, Geld und Outfits.
- **Anprobieren:** läuft nur clientseitig über `skinchanger`.
- **Kaufen:** Der Server berechnet den Warenkorb selbst (Unterschied zwischen gespeichertem Skin und neuer Auswahl, nur erlaubte Kategorien des Ladens) und nimmt die Preise aus der `config.lua`. Geld wird abgezogen (`money` oder `bank`), der neue Skin in `users.skin` gespeichert. Ist „Als Outfit speichern“ aktiv, landet das Outfit in `pulse_outfits`.
- **Outfit anziehen:** kostenlos, nur Kleidung wird übernommen (Gesicht/Haare bleiben) und sofort als Skin gespeichert.
- **Outfit löschen:** nur eigene Outfits (Prüfung über `identifier`).

## Datenbank

Tabelle `pulse_outfits`:

| Spalte | Inhalt |
|---|---|
| `id` | fortlaufende ID |
| `identifier` | ESX-Identifier des Charakters |
| `name` | Name des Outfits (max. 24 Zeichen) |
| `skin` | JSON mit allen Kleidungs-Werten (`torso_1`, `torso_2`, …) |
| `icons` | JSON mit den Icons für die Liste |
| `created_at` | Datum |

## Konfiguration

Alles in `config.lua`: Läden (Koordinaten, Titel, eigene Preise, eingeschränkte Kategorien), Kategorien und Standardpreise, Kamera, Blip/Marker, maximale Outfits pro Spieler.

Läden aus anderen Resourcen öffnen:

```lua
exports.pulse_clothing:OpenShop(1)                 -- clientseitig, Index aus Config.Shops
TriggerClientEvent('pulse_clothing:openShop', id, 1) -- serverseitig
```
