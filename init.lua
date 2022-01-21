~/.config/nvim/lua/knsh14

unction contextmenu()
    local funcs = {
        {
            name = 'hover',
            func = vim.lsp.buf.hover,
        },
        {
            name = 'rename',
            func = vim.lsp.buf.rename
        },
        {
            name = 'references',
            func = require("telescope.builtin").lsp_references
        },
        {
            name = 'declaration',
            func = vim.lsp.buf.declaration
        },
        {
            name = 'definition',
            func = vim.lsp.buf.definition
        },
        {
            name = 'signature',
            func = vim.lsp.buf.signature_help
        }
    }

    -- let l:selections = map(copy(l:options), { key, val -> printf('%d) %s', key + 1, val ) })
    local names = {}
    for i = 1, #funcs do
        names[#names+1] = string.format("%d) %s", i, funcs[i]['name'])
    end


    vim.fn.inputsave()
    local selection = vim.fn.inputlist(names)
    vim.fn.inputrestore()

    local f = funcs[selection].func
    if f == nil then
        return
    end
    vim.api.nvim_command([[silent! exe 'redraw']])
    f()
end

function plugin_setup()
    return require('packer').startup(function()
        -- Packer can manage itself
        use 'wbthomason/packer.nvim'
        use 'nvim-lua/popup.nvim'
        use 'nvim-lua/plenary.nvim'
        use 'PyGamer0/github-dimmed.vim'

        use {
            'hoob3rt/lualine.nvim',
            requires = {'kyazdani42/nvim-web-devicons', opt = true},
            config = function()
                require'lualine'.setup {
                    options = {
                        icons_enabled = true,
                        theme = 'solarized_dark',
                        component_separators = {'', ''},
                        section_separators  = {'', ''},
                        disabled_filetypes = {}
                    },
                    sections = {
                        lualine_a = {'mode'},
                        lualine_b = {'branch'},
                        lualine_c = {'filename'},
                        lualine_x = {'encoding', 'fileformat', 'filetype'},
                        lualine_y = {'progress'},
                        lualine_z = {'location'}
                    },
                    inactive_sections = {
                        lualine_a = {},
                        lualine_b = {},
                        lualine_c = {'filename'},
                        lualine_x = {'location'},
                        lualine_y = {},
                        lualine_z = {}
                    },
                    tabline = {},
                    extensions = {}
                }
            end
        }

        use {
            'knsh14/cprl.nvim',
            requires = {'rcarriga/nvim-notify'},
            cmd = {'CopyRemoteLink'},
            config = function()
                require'cprl'.setup {
                    mode = {
                        master = function()
                            return "master"
                        end
                    },
                    host = {
                        mercari = function(host, repo, ref, path, startline, endline)
                            local line = ""
                            if startline == endline then
                                line = string.format("?L%d", startline)
                            else
                                line = string.format("?L%d-%d", startline, endline)
                            end
                            return string.format("https://sourcegraph.mercari.in/%s/%s@%s/-/blob/%s%s", host, repo, ref, path, line)
                        end
                    },
                }
            end
        }

        use {
            'neovim/nvim-lspconfig',

            config = function()
                local nvim_lsp = require('lspconfig')
                local on_attach = function(client, bufnr)
                    local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
                    local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end
                    -- Mappings.
                    local opts = { noremap=true, silent=true }
                    buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
                    buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
                    buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
                    buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
                    buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
                    buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
                    buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
                    buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
                    buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
                    buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
                    buf_set_keymap('n', 'gr', '<cmd>Telescope lsp_references<CR>', opts)
                    buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
                    buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
                    buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
                    buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)

                    -- Set some keybinds conditional on server capabilities
                    if client.resolved_capabilities.document_formatting then
                        buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
                    elseif client.resolved_capabilities.document_range_formatting then
                        buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
                    end

                    -- Set autocommands conditional on server_capabilities
                    if client.resolved_capabilities.document_highlight then
                        vim.api.nvim_exec([[
                        hi LspReferenceRead cterm=bold ctermbg=red guibg=LightYellow
                        hi LspReferenceText cterm=bold ctermbg=red guibg=LightYellow
                        hi LspReferenceWrite cterm=bold ctermbg=red guibg=LightYellow
                        augroup lsp_document_highlight
                        autocmd! * <buffer>
                        autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
                        autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
                        augroup END
                        ]], false)
                    end
                end

                function goimports(timeout_ms)
                  local context = { only = { "source.organizeImports" } }
                  vim.validate { context = { context, "t", true } }
                  local params = vim.lsp.util.make_range_params()
                  params.context = context
                  local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, timeout_ms)
                  if not result or next(result) == nil then return end
                  local actions = result[1].result
                  if not actions then return end
                  local action = actions[1]
                  if action.edit or type(action.command) == "table" then
                    if action.edit then
                      vim.lsp.util.apply_workspace_edit(action.edit)
                    end
                    if type(action.command) == "table" then
                      vim.lsp.buf.execute_command(action.command)
                    end
                  else
                    vim.lsp.buf.execute_command(action)
                  end
                end
                nvim_lsp.gopls.setup {
                    on_attach = on_attach;
                    on_init = function(client)
                        client.config.settings.formattingProvider = "goimports"
                        return true
                    end
                }
                nvim_lsp.rust_analyzer.setup {
                    on_attach = on_attach;
                    settings = {
                        ["rust-analyzer"] = {
                            assist = {
                                importGranularity = "module",
                                importPrefix = "by_self",
                            },
                            cargo = {
                                loadOutDirsFromCheck = true
                            },
                            procMacro = {
                                enable = true
                            },
                        }
                    }
                }
                -- nvim_lsp.sumneko_lua.setup {
                --  on_attach = on_attach;
                -- }
                nvim_lsp.pyright.setup {
                    on_attach = on_attach;
                }
                vim.cmd[[autocmd BufWritePre *.go lua goimports(1000)]]
                vim.cmd[[autocmd FileType go setlocal omnifunc=v:lua.vim.lsp.omnifunc]]
                vim.cmd[[autocmd FileType rust setlocal omnifunc=v:lua.vim.lsp.omnifunc]]
                vim.cmd[[autocmd FileType lua setlocal omnifunc=v:lua.vim.lsp.omnifunc]]
                vim.cmd[[autocmd FileType python setlocal omnifunc=v:lua.vim.lsp.omnifunc]]
            end
        }
        use {
            'nvim-telescope/telescope.nvim',
            requires = { {'nvim-lua/plenary.nvim'} },
            config = function()
                -- local actions = require "telescope.actions"
                require('telescope').setup{
                    defaults = {
                        mappings = {
                            i = {
                                ["<Tab>"] = "select_tab",
                            },
                            n = {
                                ["<Tab>"] = "select_tab",
                            }
                        }
                    },
                    pickers = {
                        file_browser = {
                            hidden = true
                        }
                    },
                    extensions = {
                    }
                }
            end
        }
        use {
            'nvim-treesitter/nvim-treesitter',
            cmd = {'TSInstall'}
        }
        use {
          "folke/trouble.nvim",
          requires = "kyazdani42/nvim-web-devicons",
          config = function()
            require("trouble").setup {
              -- your configuration comes here
              -- or leave it empty to use the default settings
              -- refer to the configuration section below
            }
          end
        }
        use { "nvim-telescope/telescope-file-browser.nvim" }
    end
    )

end

local knsh14 = {}
knsh14.contextmenu = contextmenu
vim.api.nvim_set_keymap('n', '<space><space>', [[<Cmd>lua require('knsh14').contextmenu()<CR>]], { noremap = true, silent = true })

-- convert init.nvim

vim.o.enc = 'utf8'
vim.o.fileencoding = 'utf-8'
vim.o.number = true

vim.o.autoindent = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

vim.o.cursorline = true
vim.o.swapfile = false
vim.o.backup = false
vim.opt.completeopt = {'menuone'}
vim.opt.clipboard:append({'unnamed'})

vim.o.showtabline = 2

vim.o.wrapscan = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.hlsearch = true
vim.o.incsearch = true

vim.o.list = true
vim.opt.listchars = { tab = '»-', trail = '-', extends = '»', precedes = '«', nbsp = '%' }
vim.opt.backspace = { 'indent', 'eol', 'start' }

vim.api.nvim_set_keymap('n', '<S-Tab>', [[<<]], { noremap = true, silent = false})
vim.api.nvim_set_keymap('i', '<S-Tab>', [[<C-d>]], { noremap = true, silent = false})

-- begin install packer.nvim if not installed
local execute = vim.api.nvim_command
local fn = vim.fn

local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'

if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', 'https://github.com/wbthomason/packer.nvim', install_path})
    execute 'packadd packer.nvim'
end

plugin_setup()
require("telescope").load_extension "file_browser"

return knsh14

