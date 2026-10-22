# pulse_holster

Polizei-Holster-Animation für Pistolen und Taser. Überarbeitete und abgespeckte Fassung von
[ND_GunAnims](https://github.com/ND-Framework/ND_GunAnims) (Andyyy7666, GPL-3.0). Aim-Stile, Gang- und Melee-Animationen sind entfernt.

## Funktionen

- Polizei-Animation beim Ziehen und Wegstecken
- **Sound** beim Ziehen (Druckknopf auf + Herausziehen) und Wegstecken (Reiben + Einrasten), andere Spieler in der Nähe hören ihn leiser
- **Sauberer Waffenwechsel**: Pistole → Taser steckt erst die Pistole weg, dann wird der Taser gezogen
- Holster-Kleidung wechselt mit (Waffe im Holster ↔ leeres Holster)
- Während der Animation kein Schießen, Zielen oder erneuter Waffenwechsel
- Im Fahrzeug, beim Fallen, Schwimmen oder im Ragdoll keine Animation, nur Sound und Kleidung

## Installation

1. Ordner `pulse_holster` in `resources` legen.
2. `server.cfg`:
   ```
   ensure ox_lib
   ensure pulse_holster
   ```
3. Mit **ox_inventory** zusätzlich die eingebauten Animationen von ox ausschalten, sonst laufen zwei Animationen gleichzeitig:
   ```
   setr inventory:weaponanims 0
   ```
   Ohne ox_inventory (GTA-Waffenrad) ist nichts weiter nötig.

## Konfiguration (`config.lua`)

| Einstellung | Bedeutung |
|---|---|
| `Config.Animation` | Animation, Länge, Zeitpunkt für Sound/Holster-Wechsel und wann die Waffe sichtbar wird |
| `Config.WeaponGroups` / `Config.Weapons` | Welche Waffen animiert werden (Standard: alle Pistolen + Taser) |
| `Config.IgnoredWeapons` | Ausnahmen |
| `Config.SwitchDelay` | Pause zwischen Wegstecken und Ziehen beim Wechsel |
| `Config.Sound` | An/aus, Lautstärke, Hörweite für andere, Dateinamen |
| `Config.Holsters` | Holster-Kleidung (Komponente, Drawable mit Waffe / leer) |

Eigene Sounds: einfach `html/sounds/holster.ogg` und `html/sounds/unholster.ogg` ersetzen.
