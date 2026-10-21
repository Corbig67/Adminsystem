fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'esx_personalmenu'
description 'ESX Persönliches Menü (F5) auf Basis von esx_menu_default'
version '1.0.0'

shared_script 'config.lua'

client_scripts {
    'client/utils.lua',
    'client/wallet.lua',
    'client/faction.lua',
    'client/vehicle.lua',
    'client/admin.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/faction.lua'
}

dependencies {
    'es_extended',
    'esx_menu_default',
    'oxmysql'
}
