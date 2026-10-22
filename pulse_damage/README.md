# pulse_damage

Realistischer Schaden nach Trefferzone. Eigenständig, keine Abhängigkeiten (nutzt ESX-Benachrichtigungen, wenn ESX läuft).

## Was passiert bei einem Treffer

| Zone | Wirkung |
|---|---|
| **Kopf / Hals** | Sofort tot (Chance einstellbar, optional Schutz durch bestimmte Helme) |
| **Bein** | Man fällt hin, humpelt danach, ist langsamer, kann nicht rennen/springen. Beide Beine: noch langsamer |
| **Linker Arm** | Keine Langwaffen mehr, Zielen wackelt leicht – mit Pistole kann man weiter zurückschießen |
| **Rechter Arm (Schusshand)** | Wie oben, Zielen wackelt stärker, Chance dass die Waffe aus der Hand gerissen wird |
| **Beide Arme** | Gar nicht mehr schießen |
| **Oberkörper** | Blutung: verliert alle paar Sekunden HP, mehrere Treffer bluten stärker |

Nur Schusswaffen lösen Verletzungen aus (Gruppen in `Config.WeaponGroups`). Taser, Faustschläge, Stürze und Fahrzeuge nicht.

## Heilung

Verletzungen verschwinden bei:
- Wiederbelebung / Respawn
- voller Gesundheit nach einer Verletzung (z. B. Medikit), abschaltbar mit `Config.HealOnFullHealth`
- den Events in `Config.HealEvents` (esx_ambulancejob und qb-ambulancejob sind eingetragen)
- `TriggerClientEvent('pulse_damage:heal', playerId)` oder `exports.pulse_damage:Heal()`
- nach Ablauf der Dauer (`duration`, 0 = erst nach Behandlung)

`exports.pulse_damage:GetInjuries()` liefert z. B. `{ 'leftLeg', 'bleeding' }` – praktisch für Sanitäter-Scripts.
`/verletzungen` zeigt die eigenen Verletzungen.

## Testen ohne zweiten Spieler

```
/dmgtest kopf      Kopfschuss (sofort tot)
/dmgtest bein      Beinschuss (lbein / rbein, beide nacheinander = beide Beine)
/dmgtest arm       Schusshand (rarm), larm = linker Arm, beide nacheinander = nicht mehr schießen
/dmgtest körper    Oberkörper / Blutung
/dmgtest heilen    alles heilen
```

Auf dem Live-Server in `Config.TestCommand` ausschalten oder per ACE beschränken.

## Installation

1. Ordner `pulse_damage` in `resources` legen.
2. `server.cfg`: `ensure pulse_damage`

Alle Werte (Chancen, Dauer, Geschwindigkeit, Wackeln, Blutung, Texte) stehen in der `config.lua`.
