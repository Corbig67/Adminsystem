# pulse_knockback

Treffer mit starken Waffen schleudern den Getroffenen 1–2 Meter nach hinten (vom Schützen weg) und werfen ihn um.
Eigenständig, keine Abhängigkeiten, läuft zusammen mit `pulse_damage`.

## Standard-Waffen

Pistol .50, Heavy Pistol (60 %), Revolver / Revolver MK2, Double-Action, alle Schrotflinten, Sniper / Heavy Sniper.
Weitere Waffen einfach in `Config.Weapons` eintragen.

## Stärke einstellen

Mit `/knocktest [wucht] [hoch]` wirst du selbst nach hinten geschleudert, z. B.:

```
/knocktest          Standardwerte (30 / 4)
/knocktest 20       schwächer, ca. 1 m
/knocktest 40 5     stärker, ca. 2 m+
```

Den passenden Wert dann bei der Waffe in `Config.Weapons` als `force` eintragen.
Auf dem Live-Server `Config.TestCommand.enabled = false` setzen oder per ACE beschränken.

## Installation

1. Ordner `pulse_knockback` in `resources` legen.
2. `server.cfg`: `ensure pulse_knockback`

Aus anderen Scripts: `exports.pulse_knockback:Knockback(vonKoordinaten, wucht, hoch, ragdollMs)`
