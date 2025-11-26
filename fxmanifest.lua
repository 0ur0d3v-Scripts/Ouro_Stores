fx_version "adamant"
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

game "rdr3"
lua54 'yes'

author 'Ouro Development'
description 'Ouro Stores - Multi-type Store System'
version '1.0.0'

shared_scripts {
    'config/config.lua',
    'config/npc_stores.lua',
    'config/language.lua',
}

client_scripts {
    'config/npc_creator.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'html/store_overlay.html'

files {
    'html/store_overlay.html'
}

dependencies {
    'vorp_core',
    'vorp_inventory',
    'oxmysql',
    'Ouro_Society'
}

