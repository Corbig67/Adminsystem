# pulse_holster

Polizei-Holster-Animation für Pistolen und Taser. Überarbeitete und abgespeckte Fassung von
[ND_GunAnims](https://github.com/ND-Framework/ND_GunAnims) (Andyyy7666, GPL-3.0). Aim-Stile, Gang- und Melee-Animationen sind entfernt.

## Funktionen

- Polizei-Animation beim Ziehen und Wegstecken
- **Sound** beim Ziehen und Wegstecken: standardmäßig echte GTA-Waffensounds (scharf, 3D, andere Spieler hören sie), alternativ eigene `.ogg`-Dateien
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
| `Config.Sound` | An/aus, `mode = 'game'` (GTA-Sounds) oder `'file'` (eigene Dateien), welche GTA-Sounds, Lautstärke/Hörweite für Dateien |
| `Config.Holsters` | Holster-Kleidung (Komponente, Drawable mit Waffe / leer) |

Eigene Sounds: `Config.Sound.mode = 'file'` setzen und `html/sounds/holster.ogg` / `html/sounds/unholster.ogg` ersetzen.
Andere GTA-Sounds: in `Config.Sound.game` Name und Soundset tauschen, z. B. `{ name = 'PICK_UP', set = 'HUD_FRONTEND_DEFAULT_SOUNDSET' }`.
