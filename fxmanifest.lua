fx_version 'adamant'
game 'gta5'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    '@oxmysql/lib/MySQL.lua',
    '@es_extended/imports.lua'
}

server_scripts {
    'server/server.lua'
}

client_scripts {
    'client/client.lua'
}