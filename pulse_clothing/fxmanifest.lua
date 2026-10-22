fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pulse_clothing'
description 'Kleidungsladen mit NUI, serverseitiger Preisprüfung und Outfits in der Datenbank'
version '1.0.0'

shared_script 'config.lua'

client_script 'client/main.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/*.css',
    'html/js/*.js',
    'html/fonts/*.woff2',
    'html/img/*.png'
}

dependencies {
    'es_extended',
    'skinchanger',
    'oxmysql'
}
