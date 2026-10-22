fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pulse_sync'
description 'Waffen-Sync für alle GTA-Standardwaffen: Schaden, Rückstoß, Kampfregeln und serverseitige Treffer-Prüfung'
version '1.0.0'

shared_scripts {
    'config.lua',
    'shared/weapons.lua'
}

client_script 'client/main.lua'
server_script 'server/main.lua'
