local config = {}

local function load_env_file()
  local env_file = require("core.global").home .. "/.env"
  local env_contents = {}
  if vim.fn.filereadable(env_file) ~= 1 then
    print(".env file does not exist")
    return
  end
  local contents = vim.fn.readfile(env_file)
  for _, item in pairs(contents) do
    local line_content = vim.fn.split(item, "=")
    env_contents[line_content[1]] = line_content[2]
  end

  return env_contents
end

function config.session()
  local opts = {
    log_level = "info",
    auto_session_enable_last_session = false,
    auto_session_root_dir = vim.fn.stdpath("data") .. "/sessions/",
    auto_session_enabled = true,
    auto_save_enabled = nil,
    auto_restore_enabled = nil,
    auto_session_suppress_dirs = nil,
  }
  require("auto-session").setup(opts)
end

local function load_dbs()
  local env_contents = load_env_file()
  local dbs = {}
  for key, value in pairs(env_contents) do
    if vim.fn.stridx(key, "DB_CONNECTION_") >= 0 then
      local db_name = vim.fn.split(key, "_")[3]:lower()
      dbs[db_name] = value
    end
  end
  return dbs
end

function config.worktree()
  local function git_worktree(arg)
    if arg == "create" then
      require("telescope").extensions.git_worktree.create_git_worktree()
    else
      require("telescope").extensions.git_worktree.git_worktrees()
    end
  end

  require("git-worktree").setup({})
  vim.api.nvim_create_user_command("Worktree", "lua require'modules.tools.config'.worktree()(<f-args>)", {
    nargs = "*",
    complete = function()
      return { "create" }
    end,
  })

  local Worktree = require("git-worktree")
  Worktree.on_tree_change(function(op, metadata)
    if op == Worktree.Operations.Switch then
      print("Switched from " .. metadata.prev_path .. " to " .. metadata.path)
    end

    if op == Worktree.Operations.Create then
      print("Create worktree " .. metadata.path)
    end

    if op == Worktree.Operations.Delete then
      print("Delete worktree " .. metadata.path)
    end
  end)
  return { git_worktree = git_worktree }
end

function config.diffview()
  local cb = require("diffview.config").diffview_callback
  require("diffview").setup({
    diff_binaries = false, -- Show diffs for binaries
    use_icons = true, -- Requires nvim-web-devicons
    enhanced_diff_hl = true, -- See ':h diffview-config-enhanced_diff_hl'
    signs = { fold_closed = "", fold_open = "" },
    file_panel = {
      win_config = {
        position = "left", -- One of 'left', 'right', 'top', 'bottom'
        width = 35, -- Only applies when position is 'left' or 'right'
      },
    },
    key_bindings = {
      -- The `view` bindings are active in the diff buffers, only when the current
      -- tabpage is a Diffview.
      view = {
        ["<tab>"] = cb("select_next_entry"), -- Open the diff for the next file
        ["<s-tab>"] = cb("select_prev_entry"), -- Open the diff for the previous file
        ["<leader>e"] = cb("focus_files"), -- Bring focus to the files panel
        ["<leader>b"] = cb("toggle_files"), -- Toggle the files panel.
      },
      file_panel = {
        ["j"] = cb("next_entry"), -- Bring the cursor to the next file entry
        ["<down>"] = cb("next_entry"),
        ["k"] = cb("prev_entry"), -- Bring the cursor to the previous file entry.
        ["<up>"] = cb("prev_entry"),
        ["<cr>"] = cb("select_entry"), -- Open the diff for the selected entry.
        ["o"] = cb("select_entry"),
        ["R"] = cb("refresh_files"), -- Update stats and entries in the file list.
        ["<tab>"] = cb("select_next_entry"),
        ["<s-tab>"] = cb("select_prev_entry"),
        ["<leader>e"] = cb("focus_files"),
        ["<leader>b"] = cb("toggle_files"),
      },
    },
  })
end

function config.vim_dadbod_ui()
  if packer_plugins["vim-dadbod"] and not packer_plugins["vim-dadbod"].loaded then
    require("packer").loader("vim-dadbod")
  end
  vim.g.db_ui_show_help = 0
  vim.g.db_ui_win_position = "left"
  vim.g.db_ui_use_nerd_fonts = 1
  vim.g.db_ui_winwidth = 35
  vim.g.db_ui_save_location = require("core.global").home .. "/.cache/vim/db_ui_queries"
  vim.g.dbs = load_dbs()
end

function config.vim_vista()
  vim.g["vista#renderer#enable_icon"] = 1
  vim.g.vista_disable_statusline = 1

  vim.g.vista_default_executive = "nvim_lsp" -- ctag
  vim.g.vista_echo_cursor_strategy = "floating_win"
  vim.g.vista_vimwiki_executive = "markdown"
  vim.g.vista_executive_for = {
    vimwiki = "markdown",
    pandoc = "markdown",
    markdown = "toc",
    typescript = "nvim_lsp",
    typescriptreact = "nvim_lsp",
    go = "nvim_lsp",
    lua = "nvim_lsp",
  }

  -- vim.g['vista#renderer#icons'] = {['function'] = "", ['method'] = "ℱ", variable = "כֿ"}
end

function config.clap()
  vim.g.clap_preview_size = 10
  vim.g.airline_powerline_fonts = 1
  vim.g.clap_layout = { width = "80%", row = "8%", col = "10%", height = "34%" } -- height = "40%", row = "17%", relative = "editor",
  -- vim.g.clap_popup_border = "rounded"
  vim.g.clap_selected_sign = { text = "", texthl = "ClapSelectedSign", linehl = "ClapSelected" }
  vim.g.clap_current_selection_sign = {
    text = "",
    texthl = "ClapCurrentSelectionSign",
    linehl = "ClapCurrentSelection",
  }
  -- vim.g.clap_always_open_preview = true
  vim.g.clap_preview_direction = "UD"
  -- if vim.g.colors_name == 'zephyr' then
  vim.g.clap_theme = "material_design_dark"
  vim.api.nvim_command(
    "autocmd FileType clap_input lua require'cmp'.setup.buffer { completion = {autocomplete = false} }"
  )
  -- end
  -- vim.api.nvim_command("autocmd FileType clap_input call compe#setup({ 'enabled': v:false }, 0)")
end

function config.clap_after()
  if not packer_plugins["nvim-cmp"].loaded then
    require("packer").loader("nvim-cmp")
  end
end

function config.project()
  require("project_nvim").setup({
    datapath = vim.fn.stdpath("data"),
    ignore_lsp = { "efm" },
    exclude_dirs = { "~/.cargo/*" },
    silent_chdir = true,
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
  })
  require("utils.telescope")
  require("telescope").load_extension("projects")
end

function config.neogit()
  local loader = require("packer").loader
  loader("diffview.nvim")
  require("neogit").setup({
    signs = {
      section = { "", "" },
      item = { "", "" },
      hunk = { "", "" },
    },
    integrations = {
      diffview = true,
    },
  })
end

function config.gitsigns()
  if not packer_plugins["plenary.nvim"].loaded then
    require("packer").loader("plenary.nvim")
  end
  require("gitsigns").setup({
    signs = {
      add = { hl = "GitGutterAdd", text = "│", numhl = "GitSignsAddNr" },
      change = { hl = "GitGutterChange", text = "│", numhl = "GitSignsChangeNr" },
      delete = { hl = "GitGutterDelete", text = "ﬠ", numhl = "GitSignsDeleteNr" },
      topdelete = { hl = "GitGutterDelete", text = "ﬢ", numhl = "GitSignsDeleteNr" },
      changedelete = { hl = "GitGutterChangeDelete", text = "┊", numhl = "GitSignsChangeNr" },
    },
    numhl = false,
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Navigation
      map("n", "]c", function()
        if vim.wo.diff then
          return "]c"
        end
        vim.schedule(function()
          gs.next_hunk()
        end)
        return "<Ignore>"
      end, { expr = true })

      map("n", "[c", function()
        if vim.wo.diff then
          return "[c"
        end
        vim.schedule(function()
          gs.prev_hunk()
        end)
        return "<Ignore>"
      end, { expr = true })

      -- Actions
      map({ "n", "v" }, "<leader>hs", ":Gitsigns stage_hunk<CR>")
      map({ "n", "v" }, "<leader>hr", ":Gitsigns reset_hunk<CR>")
      -- map("n", "<leader>hS", gs.stage_buffer) -- hydra
      -- map("n", "<leader>hu", gs.undo_stage_hunk)
      -- map("n", "<leader>hR", gs.reset_buffer)
      -- map("n", "<leader>hp", gs.preview_hunk)
      map("n", "<leader>hb", function()
        gs.blame_line({ full = true })
      end)
      map("n", "<leader>tb", gs.toggle_current_line_blame)
      map("n", "<leader>hd", gs.diffthis)
      map("n", "<leader>hD", function()
        gs.diffthis("~")
      end)
      -- map("n", "<leader>td", gs.toggle_deleted)

      -- Text object
      map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>")
    end,

    watch_gitdir = { interval = 1000, follow_files = true },
    sign_priority = 6,
    status_formatter = nil, -- Use default
    debug_mode = false,
    current_line_blame = true,
    current_line_blame_opts = { delay = 1500 },
    update_debounce = 300,
    word_diff = true,
    diff_opts = { internal = true },
  })
  vim.api.nvim_create_user_command("Stage", "'<,'>Gitsigns stage_hunk", { range = true })
end

local function round(x)
  return x >= 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)
end

function config.bqf()
  require("bqf").setup({
    auto_enable = true,
    preview = {
      win_height = 12,
      win_vheight = 12,
      delay_syntax = 80,
      border_chars = { "┃", "┃", "━", "━", "┏", "┓", "┗", "┛", "█" },
    },
    func_map = { vsplit = "", ptogglemode = "z,", stoggleup = "" },
    filter = {
      fzf = {
        action_for = { ["ctrl-s"] = "split" },
        extra_opts = { "--bind", "ctrl-o:toggle-all", "--prompt", "> " },
      },
    },
  })
end

function config.dapui()
  vim.cmd([[let g:dbs = {
  \ 'eraser': 'postgres://postgres:password@localhost:5432/eraser_local',
  \ 'staging': 'postgres://postgres:password@localhost:5432/my-staging-db',
  \ 'wp': 'mysql://root@localhost/wp_awesome' }]])
  require("dapui").setup({
    icons = { expanded = "⯆", collapsed = "⯈", circular = "↺" },

    mappings = {
      -- Use a table to apply multiple mappings
      expand = { "<CR>", "<2-LeftMouse>" },
      open = "o",
      remove = "d",
      edit = "e",
    },
    sidebar = {
      elements = {
        -- You can change the order of elements in the sidebar
        "scopes",
        "stacks",
        "watches",
      },
      width = 40,
      position = "left", -- Can be "left" or "right"
    },
    tray = {
      elements = { "repl" },
      height = 10,
      position = "bottom", -- Can be "bottom" or "top"
    },
    floating = {
      max_height = nil, -- These can be integers or a float between 0 and 1.
      max_width = nil, -- Floats will be treated as percentage of your screen.
    },
  })
end

function config.markdown()
  vim.g.vim_markdown_frontmatter = 1
  vim.g.vim_markdown_strikethrough = 1
  vim.g.vim_markdown_folding_level = 6
  vim.g.vim_markdown_override_foldtext = 1
  vim.g.vim_markdown_folding_style_pythonic = 1
  vim.g.vim_markdown_conceal = 1
  vim.g.vim_markdown_conceal_code_blocks = 1
  vim.g.vim_markdown_new_list_item_indent = 0
  vim.g.vim_markdown_toc_autofit = 0
  vim.g.vim_markdown_edit_url_in = "vsplit"
  vim.g.vim_markdown_strikethrough = 1
  vim.g.vim_markdown_fenced_languages = {
    "c++=javascript",
    "js=javascript",
    "json=javascript",
    "jsx=javascript",
    "tsx=javascript",
  }
end

--[[
Use `git ls-files` for git files, use `find ./ *` for all files under work directory.
]]
--

function config.floaterm()
  -- Set floaterm window's background to black
  -- Set floating window border line color to cyan, and background to orange
  require("toggleterm").setup({
    -- size can be a number or function which is passed the current terminal
    size = function(term)
      if term.direction == "horizontal" then
        return 15
      elseif term.direction == "vertical" then
        return vim.o.columns * 0.4
      end
    end,
    open_mapping = [[<c-\>]],
    -- on_open = fun(t: Terminal), -- function to run when the terminal opens
    -- on_close = fun(t: Terminal), -- function to run when the terminal closes
    hide_numbers = true, -- hide the number column in toggleterm buffers
    shade_filetypes = {},
    shade_terminals = true,
    -- shading_factor = "<number>", -- the degree by which to darken to terminal colour, default: 1 for dark backgrounds, 3 for light
    start_in_insert = true,
    insert_mappings = true, -- whether or not the open mapping applies in insert mode
    persist_size = true,
    direction = "float",
    close_on_exit = true, -- close the terminal window when the process exits
    shell = vim.o.shell, -- change the default shell
    -- This field is only relevant if direction is set to 'float'
    float_opts = {
      -- The border key is *almost* the same as 'nvim_open_win'
      -- see :h nvim_open_win for details on borders however
      -- the 'curved' border is a custom border type
      -- not natively supported but implemented in this plugin.
      border = "curved",
      -- width = <value>,
      -- height = <value>,
      winblend = 3,
    },
  })
  local Terminal = require("toggleterm.terminal").Terminal
  local lazygit = Terminal:new({ cmd = "lazygit", hidden = true })
  local lazydocker = Terminal:new({ cmd = "lazydocker", hidden = true })

  function _lazygit_toggle()
    lazygit:toggle()
  end
  function _lazydocker_toggle()
    lazydocker:toggle()
  end
  function _gd_toggle(...)
    local args = { ... }
    local ver
    if #args > 0 then
      ver = args[1]
    else
      ver = ""
    end
    local cmd = "gd" .. " " .. ver
    if ver == "a" then
      cmd = "git diff"
    end
    local gd = Terminal:new({ cmd = cmd, hidden = true })
    gd:toggle()
    vim.cmd("normal! a")
  end
  vim.cmd("command! LG lua _lazygit_toggle()")
  vim.cmd("command! -nargs=* GD lua _gd_toggle(<f-args>)")
  vim.cmd("command! LD lua _lazydocker_toggle()")

  local fzf = Terminal:new({ cmd = "fzf", hidden = true })

  function _fzf_toggle()
    fzf:toggle()
  end
  vim.cmd("command! FZF lua _fzf_toggle()")
  -- vim.cmd("command! NNN FloatermNew --autoclose=1 --height=0.96 --width=0.96 nnn")
  -- vim.cmd("command! FN FloatermNew --autoclose=1 --height=0.96 --width=0.96")
  -- vim.cmd("command! LG FloatermNew --autoclose=1 --height=0.96 --width=0.96 lazygit")
  -- vim.cmd("command! Ranger FloatermNew --autoclose=1 --height=0.96 --width=0.96 ranger")

  -- vim.g.floaterm_gitcommit = "split"
  -- vim.g.floaterm_keymap_new = "<F19>" -- S-f7
  -- vim.g.floaterm_keymap_prev = "<F20>"
  -- vim.g.floaterm_keymap_next = "<F21>"
  -- vim.g.floaterm_keymap_toggle = "<F24>"
  -- Use `git ls-files` for git files, use `find ./ *` for all files under work directory.
  -- grep -rli 'old-word' * | xargs -i@ sed -i 's/old-word/new-word/g' @
  --  rg -l 'old-word' * | xargs -i@ sed -i 's/old-word/new-word/g' @
end

function config.spelunker()
  -- vim.cmd("command! Spell call spelunker#check()")
  vim.g.enable_spelunker_vim_on_readonly = 0
  vim.g.spelunker_check_type = 2
  vim.g.spelunker_highlight_type = 2
  vim.g.spelunker_disable_uri_checking = 1
  vim.g.spelunker_disable_account_name_checking = 1
  vim.g.spelunker_disable_email_checking = 1
  -- vim.cmd("highlight SpelunkerSpellBad cterm=underline ctermfg=247 gui=undercurl guifg=#F3206e guisp=#EF3050")
  -- vim.cmd("highlight SpelunkerComplexOrCompoundWord cterm=underline gui=undercurl guisp=#EF3050")
  vim.cmd("highlight def link SpelunkerSpellBad SpellBad")
  vim.cmd("highlight def link SpelunkerComplexOrCompoundWord Rare")
end

function config.spellcheck()
  vim.cmd("highlight def link SpelunkerSpellBad SpellBad")
  vim.cmd("highlight def link SpelunkerComplexOrCompoundWord Rare")

  vim.fn["spelunker#check"]()
end

function config.grammcheck()
  -- body
  if not packer_plugins["rhysd/vim-grammarous"] or not packer_plugins["rhysd/vim-grammarous"].loaded then
    require("packer").loader("vim-grammarous")
  end
  vim.cmd([[GrammarousCheck]])
end
function config.vim_test()
  vim.g["test#strategy"] = { nearest = "neovim", file = "neovim", suite = "neovim" }
  vim.g["test#neovim#term_position"] = "vert botright 60"
  vim.g["test#go#runner"] = "ginkgo"
  -- nmap <silent> t<C-n> :TestNearest<CR>
  -- nmap <silent> t<C-f> :TestFile<CR>
  -- nmap <silent> t<C-s> :TestSuite<CR>
  -- nmap <silent> t<C-l> :TestLast<CR>
  -- nmap <silent> t<C-g> :TestVisit<CR>
end

function config.mkdp()
  -- print("mkdp")
  vim.g.mkdp_command_for_global = 1
  vim.cmd(
    [[let g:mkdp_preview_options = { 'mkit': {}, 'katex': {}, 'uml': {}, 'maid': {}, 'disable_sync_scroll': 0, 'sync_scroll_type': 'middle', 'hide_yaml_meta': 1, 'sequence_diagrams': {}, 'flowchart_diagrams': {}, 'content_editable': v:true, 'disable_filename': 0 }]]
  )
end

function config.git_conflict()
  require("git-conflict").setup()
end

vim.api.nvim_create_user_command("LspClients", function(opts)

  if opts.fargs ~= nil then
    for _, client in pairs(vim.lsp.get_active_clients()) do
      if client.name == opts.fargs[1] then
        lprint(client)
      end
    end
  else
    lprint(vim.lsp.get_active_clients())
  end
end, { nargs = "*" })
return config
