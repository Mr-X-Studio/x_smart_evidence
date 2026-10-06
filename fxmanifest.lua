fx_version 'cerulean'
game 'gta5'

author 'MR X / X Studio'
description 'X Smart Evidence - commercial-ready police evidence and case management system'
version '1.0.0'
lua54 'yes'

shared_scripts {
    'config.lua',
    'shared/utils.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
    'web/assets/mr-x-logo.png'
}

dependencies {
    '/onesync'
}

escrow_ignore {
    'config.lua',
    'shared/utils.lua',
    'docs/**',
    'README.md',
    'LICENSE.md',
    'CHANGELOG.md'
}
