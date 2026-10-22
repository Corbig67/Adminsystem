# pulse_sync

Waffen-Sync für alle GTA-Standardwaffen (Nahkampf, Pistolen, MPs, Schrotflinten, Gewehre, MGs, Sniper, schwere Waffen, Wurfwaffen).
Eigenständig, keine Abhängigkeiten, braucht **OneSync** für die Server-Prüfung.

## Was die Sync macht

**Für alle Spieler gleich**
- Schaden pro Waffe (Multiplikator, Standard 1.0 = GTA)
- Rückstoß und Fadenkreuz bleiben GTA-Standard (optional: eigener Rückstoß mit `Config.Recoil.enabled = true`)
- Kein Rückstoß bei allen Schusswaffen (`Config.NoRecoil`, pro Gruppe oder einzelne Waffe abschaltbar)
- Keine Kampfrolle, kein Pistolenschlag (einstellbar)
- Kopfschüsse an/aus, Faustschlag-Schaden, NPCs lassen keine Waffen fallen
- Gesperrte Waffen (`allowed = false`) werden sofort entfernt

**Treffer, die ankommen**
- Kopfschuss tötet sofort (beim Getroffenen über den Kopf-Knochen erkannt, nicht über GTA-Schaden). Taser ausgenommen, Helme optional
- „Stirbt nicht“-Fix: wer kurz nach einem Treffer bei 1 HP hängen bleibt, stirbt richtig
- Hitmarker für den Schützen: weiß = Treffer, rot = Kopfschuss/Kill, mit Ton

**Server-Prüfung jedes Treffers (gegen Cheater)**
| Prüfung | Erkennt |
|---|---|
| Waffe nicht in der Hand | Treffer mit einer Waffe, die der Schütze nicht hält (Waffen-Spoofer) |
| Entfernung | Treffer weiter als die Reichweite der Waffe (Magic Bullet / Teleport-Kills) |
| Schaden | Schaden über der Grenze (Damage-Modifier-Cheats) |
| Treffer pro Sekunde | Rapid-Fire-Cheats |
| Gesperrte Waffe | Treffer mit verbotenen Waffen |

Jede Prüfung: `'cancel'` (Treffer verwerfen + melden), `'log'` (nur melden) oder `false`.
Standard: verworfen werden nur gesperrte Waffen und unmögliche Entfernungen – alles, was durch Lag oder hohen Kopfschuss-Schaden
auch bei ehrlichen Spielern vorkommt, wird nur gemeldet. So geht kein echter Treffer verloren.
Meldungen: Server-Konsole und optional Discord-Webhook (Name, ID, License, Discord).

## Empfohlene Einführung (großer Server)

1. Erst mit `Config.Punish.kickAfter = 0` laufen lassen und die Meldungen ein paar Tage beobachten.
2. Grenzwerte (`range`, `maxDamage`, `maxHitsPerSecond`) anpassen, falls legitime Spieler auftauchen.
3. Danach `kickAfter` z. B. auf `10` setzen.

Admins mit `add_ace group.admin pulse_sync.bypass allow` werden nie gekickt.
`/syncstatus [id]` zeigt Meldungen der letzten 5 Minuten (Konsole oder `add_ace group.admin command.syncstatus allow`).

## Werte anpassen

Gruppen-Standards in `Config.Groups`, einzelne Waffen in `Config.Weapons` überschreiben jeden Wert:

```lua
WEAPON_PISTOL50 = { group = 'pistol', recoil = 1.10, damage = 1.2 },
WEAPON_RAILGUN  = { group = 'heavy', allowed = false },
```

## Hinweis

Streuung, Feuerrate, Magazingröße und Reichweite der Kugeln selbst stehen in GTAs `weapons.meta` und lassen sich nicht per Script ändern.
Dafür bräuchte es eine angepasste `weapons.meta` (aus den Spieldateien), die man zusätzlich als `WEAPONINFO_FILE_PATCH` laden kann.

## Installation

1. Ordner `pulse_sync` in `resources` legen.
2. `server.cfg`: `ensure pulse_sync` (OneSync muss an sein).
