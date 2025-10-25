fx_version 'cerulean'
game 'gta5'

name 'olrp-mdt'
description 'Advanced Mobile Data Terminal System for QBCore/QBox/ESX'
author 'OLRP Development'
version '2.0.0'

shared_scripts {
    'config/shared.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/*.css',
    'html/js/*.js',
    'html/assets/*',
    'html/fonts/*'
}

dependencies {
    'oxmysql'
}

lua54 'yes'
