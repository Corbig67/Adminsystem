fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pulse_holster'
description 'Polizei-Holster-Animation mit Sound und sauberem Waffenwechsel (basiert auf ND_GunAnims von Andyyy7666)'
version '2.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_script 'client/main.lua'
server_script 'server/main.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/sounds/*.ogg'
}

dependency 'ox_lib'
