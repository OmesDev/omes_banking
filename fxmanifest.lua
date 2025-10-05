fx_version 'cerulean'
game 'gta5'

author 'OMES'
description 'OMES Banking System - Advanced banking solution compatible with ESX Legacy and QB Core'
version '2.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/style.css',
    'nui/script.js',
    'nui/assets/**/*'
}

dependencies {
    'oxmysql'
}

lua54 'yes'
