fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'handlingeditor'
description 'Live handling editor with telemetry, presets and handling.meta export'
version '1.0.0'
author 'IamZach'
discord 'https://discord.gg/agn'
repository 'https://github.com/1amZach/handlingeditor'

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/assets/*',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/fields.lua',
}

client_scripts {
    'client/handling.lua',
    'client/sync.lua',
    'client/editor.lua',
}

server_script 'server/main.lua'

dependency 'ox_lib'
