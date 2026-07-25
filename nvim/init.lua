require('config.options')
require('config.plugins')

-- plugin configs
require('config.plugins.snacks')
require('config.plugins.oil')
require('config.plugins.cmp')
require('config.plugins.mini')
require('config.plugins.lsp')
require('config.plugins.conform')
require('config.plugins.autotag')
require('config.plugins.autopairs')

-- load keymaps last as they include plugin configs
require('config.keymaps')
