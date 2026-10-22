fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pulse_damage'
description 'Realistischer Schaden: Kopfschuss tödlich, Beinschuss lässt fallen und humpeln, Armschuss nur noch einhändig'
version '1.0.0'

files {
    'data/weaponanimations.meta'
}

-- schaltet die Einhand-Haltung (Gang1H) für Pistolen frei
data_file 'WEAPON_ANIMATIONS_FILE' 'data/weaponanimations.meta'

shared_script 'config.lua'
client_script 'client/main.lua'
