-- Builds every app's hax0r theme files from palettes.lua. Run it after changing a color:
--   hax0r build    (or: nvim -l ~/.config/hax0r/generate.lua)
-- nvim needs nothing built: its colors/hax0r.lua reads palettes.lua directly.
-- Every file it writes says so at the top, so edit palettes.lua or a template instead.

local home = vim.env.HOME
local config = vim.env.XDG_CONFIG_HOME or (home .. '/.config')
local vscode = config .. '/vscode/hax0r-theme'
local P = dofile(config .. '/hax0r/palettes.lua')

local function read(path)
  local f = assert(io.open(path))
  local text = f:read('a')
  f:close()
  return text
end

local changed = 0
local function write(path, text)
  local f = io.open(path)
  if f then
    local old = f:read('a')
    f:close()
    if old == text then
      return
    end
  end
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  f = assert(io.open(path, 'w'))
  f:write(text)
  f:close()
  changed = changed + 1
  print('wrote ' .. path:gsub('^' .. vim.pesc(home), '~'))
end

-- A role's color: a name in palettes.lua, a dotted path into one of its tables (syntax.keyword,
-- brackets.1), or ansiN for palette slot N
local function role_color(c, role)
  local slot = role:match('^ansi(%d+)$')
  if slot then
    return c.ansi[tonumber(slot)]
  end
  local value = c
  for key in role:gmatch('[^.]+') do
    value = type(value) == 'table' and value[tonumber(key) or key] or nil
  end
  return value
end

-- Fills each {{role}} in a template with that role's color
local function fill(template, c, extra)
  return (template:gsub('{{([%w_.]+)}}', function(role)
    return assert(extra[role] or role_color(c, role), 'unknown role {{' .. role .. '}}')
  end))
end

-- Drops // comments from JSONC, leaving // inside strings (like "vscode://...") alone
local function strip_comments(text)
  local out = {}
  for line in (text .. '\n'):gmatch('(.-)\n') do
    local in_string, i, cut = false, 1, nil
    while i <= #line do
      local ch = line:sub(i, i)
      if in_string and ch == '\\' then
        i = i + 1
      elseif ch == '"' then
        in_string = not in_string
      elseif not in_string and line:sub(i, i + 1) == '//' then
        cut = i
        break
      end
      i = i + 1
    end
    if cut then
      local code = line:sub(1, cut - 1):gsub('%s+$', '')
      if code:match('%S') then
        table.insert(out, code)
      end
    else
      table.insert(out, line)
    end
  end
  return table.concat(out, '\n')
end

local function generated_by(comment, sources)
  sources = sources:gsub('palettes%.lua', '~/.config/hax0r/palettes.lua')
  return ('%s Built by `hax0r build` from %s: edit %s, not this file.'):format(
    comment, sources, sources:find(' and ') and 'those' or 'that')
end

-- Ghostty: one theme file per theme, chosen by the `theme =` line hax0r writes
local function ghostty(name, c)
  local lines = {
    ('# hax0r %s for Ghostty: %s.'):format(name, c.title),
    generated_by('#', 'palettes.lua'),
    'background = ' .. c.bg,
    'foreground = ' .. c.fg,
    'cursor-color = ' .. c.cursor,
    'cursor-text = ' .. c.cursor_text,
    '# Selections tint the background and let each character keep its own color',
    'selection-background = ' .. c.selection_tint,
    'selection-foreground = cell-foreground',
    '# The 16 colors, with ansi 7, 8 and 12 changed for Claude Code (see palettes.lua)',
  }
  for i = 0, 15 do
    table.insert(lines, ('palette = %d=%s'):format(i, c.ansi[i]))
  end
  vim.list_extend(lines, {
    "# Claude Code's diff backgrounds: its theme points at these slots",
    'palette = 22=' .. c.diff_add,
    'palette = 28=' .. c.diff_add_word,
    'palette = 52=' .. c.diff_del,
    'palette = 88=' .. c.diff_del_word,
    "# Errors, for Starship's prompt after a failed command",
    'palette = 196=' .. c.error,
  })
  write(('%s/ghostty/themes/hax0r-%s'):format(config, name), table.concat(lines, '\n') .. '\n')
end

-- tmux: tmux.conf's status formats read the @hax0r_* colors, but style options can't, so set those too
local function tmux(name, c)
  local lines = {
    ('# hax0r %s for tmux: %s.'):format(name, c.title),
    generated_by('#', 'palettes.lua'),
    ("set -g @hax0r_fg '%s'"):format(c.fg),
    ("set -g @hax0r_dim '%s'"):format(c.dim),
    ("set -g @hax0r_bright '%s'"):format(c.bright),
    ("set -g @hax0r_white '%s'"):format(c.white),
    ("set -g status-style 'bg=default,fg=%s'"):format(c.fg),
    ("set -g pane-border-style 'fg=%s'"):format(c.border),
    ("set -g pane-active-border-style 'fg=%s'"):format(c.dim),
  }
  write(('%s/tmux/themes/hax0r-%s.conf'):format(config, name), table.concat(lines, '\n') .. '\n')
end

-- fzf: one options file per theme, copied to where FZF_DEFAULT_OPTS_FILE points. Its text and
-- background stay the terminal's (-1), so the switch fade and the shader still apply.
-- The band only reaches the end of the line with --highlight-line, and a blank --gutter drops the
-- stripe fzf otherwise draws down the left, which gutter:-1 only recolors to the text color
local function fzf(name, c)
  local lines = {
    ('# hax0r %s for fzf: %s.'):format(name, c.title),
    generated_by('#', 'palettes.lua'),
    "--highlight-line --gutter=' '",
    ('--color=%s,fg:-1,bg:-1,gutter:-1,query:-1:bold'):format(c.light and 'light' or 'dark'),
    ('--color=hl:%s:bold,hl+:%s:bold,fg+:-1:regular,bg+:%s'):format(c.match, c.match, c.list_row),
    ('--color=pointer:%s,marker:%s,prompt:%s'):format(c.bright, c.bright, c.bright),
    ('--color=info:%s,spinner:%s,header:%s,label:%s,ghost:%s'):format(c.dim, c.dim, c.dim, c.dim, c.dim),
    ('--color=separator:%s,border:%s,scrollbar:%s'):format(c.faint, c.faint, c.faint),
  }
  write(('%s/hax0r/fzf/%s'):format(config, name), table.concat(lines, '\n') .. '\n')
end

-- lazygit: a config file per theme, copied to where LG_CONFIG_FILE points. Its text stays the
-- terminal's, so the switch fade and the shader still apply. It hard-codes ANSI slots for hashes and
-- staged files, and those can't be set here. A copied commit's hash keeps its text color when the
-- selected line's band replaces its own, so that color has to read on both. lazygit 0.66.2 doesn't
-- use the markedBaseCommit colors, so they aren't set
local function lazygit(name, c)
  local function set(key, ...)
    local values = {}
    for _, value in ipairs({ ... }) do
      table.insert(values, value:match('^#') and ("'%s'"):format(value) or value)
    end
    return ('    %s: [%s]'):format(key, table.concat(values, ', '))
  end
  write(('%s/hax0r/lazygit/%s.yml'):format(config, name), table.concat({
    ('# hax0r %s for lazygit: %s.'):format(name, c.title),
    generated_by('#', 'palettes.lua'),
    'gui:',
    '  theme:',
    set('activeBorderColor', c.focus, 'bold'),
    set('inactiveBorderColor', c.dim),
    set('searchingActiveBorderColor', c.link, 'bold'),
    set('optionsTextColor', c.dim),
    set('selectedLineBgColor', c.list_row),
    set('inactiveViewSelectedLineBgColor', c.list_row_inactive),
    set('cherryPickedCommitFgColor', c.link),
    set('cherryPickedCommitBgColor', c.prompt_band),
    set('unstagedChangesColor', c.changed),
    '    authorColors:',
    ("      '*': '%s'"):format(c.dim),
  }, '\n') .. '\n')
end

-- Chrome: a theme extension's manifest per theme, that `hax0r <theme>` copies into the one folder
-- Chrome has loaded, where `hax0r chrome on` was run. Chrome wants colors as [r, g, b], and the name
-- stays hax0r whichever theme is on. Keys are from kOverwritableColorTable in Chromium's
-- browser_theme_pack.cc. The active tab is always the toolbar's color, and the strip and tabs behind
-- it don't change when the window loses focus, like the terminal
local CHROME_ROLES = {
  { 'frame', 'bg' },
  { 'frame_inactive', 'bg' },
  { 'background_tab', 'bg' },
  { 'background_tab_inactive', 'bg' },
  { 'toolbar', 'bg' },
  { 'tab_text', 'tab_bright' },
  { 'tab_background_text', 'tab_dim' },
  { 'tab_background_text_inactive', 'tab_dim' },
  { 'toolbar_button_icon', 'normal' },
  { 'toolbar_text', 'fg' },
  { 'bookmark_text', 'fg' },
  { 'omnibox_background', 'bg' },
  { 'omnibox_text', 'fg' },
  { 'ntp_background', 'bg' },
  { 'ntp_text', 'fg' },
  { 'ntp_link', 'link' },
}

local function chrome(name, c)
  local lines = {}
  for _, role in ipairs(CHROME_ROLES) do
    local hex = assert(c[role[2]], role[2])
    table.insert(lines, ('      "%s": [%d, %d, %d]'):format(role[1],
      tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)))
  end
  write(('%s/hax0r/chrome/%s.json'):format(config, name), table.concat({
    '{',
    '  "manifest_version": 3,',
    '  "name": "hax0r",',
    '  "version": "1.0",',
    ('  "description": "hax0r %s. Built by hax0r build from palettes.lua: edit that, not this file.",'):format(name),
    '  "theme": {',
    '    "colors": {',
    table.concat(lines, ',\n'),
    '    }',
    '  }',
    '}',
    '',
  }, '\n'))
end

-- delta: a git config per theme that `hax0r <theme>` copies to ~/.local/state/hax0r/delta.gitconfig on
-- a machine with `hax0r delta on`, which ~/.config/git/config includes if it's there. The pager setting
-- lives here too, so git on a machine without delta never asks for it. Syntax highlighting is off in
-- a one-color theme, whose ANSI colors are nearly one hue. A full-color theme highlights every line,
-- added and removed too, as VS Code's diffs do: with its delta_syntax theme if it names one of delta's
-- (`delta --list-syntax-themes`), or else delta's ansi theme, which uses the terminal's 16 colors
local function delta(name, c)
  local function style(...)
    return '"' .. table.concat({ ... }, ' ') .. '"'
  end
  local plus, minus = c.fg, c.removed
  if c.full_color then
    plus, minus = 'syntax', 'syntax'
  end
  local settings = {
    { 'syntax-theme', c.full_color and (c.delta_syntax or 'ansi') or 'none' },
    { 'true-color', 'always' },
    { c.light and 'light' or 'dark', 'true' },
    { 'minus-style', style(minus, c.diff_del) },
    { 'minus-emph-style', style(minus, c.diff_del_word) },
    { 'plus-style', style(plus, c.diff_add) },
    { 'plus-emph-style', style(plus, c.diff_add_word) },
    { 'zero-style', c.full_color and style('syntax') or style(c.fg) },
    { 'file-style', style(c.fg, 'bold') },
    { 'file-decoration-style', style(c.border, 'ul') },
    { 'hunk-header-style', style('line-number', c.dim) },
    { 'hunk-header-line-number-style', style(c.dim) },
    { 'hunk-header-decoration-style', 'none' },
  }
  local lines = {
    ('# hax0r %s for delta: %s.'):format(name, c.title),
    '# Built by `hax0r build` from ~/.config/hax0r/palettes.lua: edit that, not this file.',
    '[core]',
    '\tpager = delta',
    '[interactive]',
    '\tdiffFilter = delta --color-only',
    '[delta]',
  }
  for _, s in ipairs(settings) do
    table.insert(lines, ('\t%s = %s'):format(s[1], s[2]))
  end
  table.insert(lines, '')
  write(('%s/hax0r/delta/%s.gitconfig'):format(config, name), table.concat(lines, '\n'))
end

-- Raycast: a link per theme that `hax0r raycast` opens, and Raycast asks before installing it. The
-- link holds 12 colors in this order, read from Raycast 2.10's code: background, backgroundSecondary,
-- foreground, selection, loader, red, orange, yellow, green, blue, purple, magenta. It can't set the
-- accent color. Using link for the last three lets a dual theme's second hue show. A full-color
-- theme has a color for each, in its hues table
local RAYCAST_ROLES = { 'bg', 'bg', 'fg', 'bright', 'bright', 'error', 'warning', 'warning', 'bright', 'link', 'link', 'link' }
local RAYCAST_HUES = { 'bg', 'bg', 'fg', 'focus', 'focus', 'hues.red', 'hues.orange', 'hues.yellow', 'hues.green',
  'hues.blue', 'hues.purple', 'hues.magenta' }

local function raycast(name, c)
  local colors = {}
  for _, role in ipairs(c.full_color and RAYCAST_HUES or RAYCAST_ROLES) do
    table.insert(colors, '%23' .. assert(role_color(c, role), role):sub(2))
  end
  write(('%s/hax0r/raycast/%s'):format(config, name), table.concat({
    ('# hax0r %s for Raycast: %s.'):format(name, c.title),
    '# Built by `hax0r build` from ~/.config/hax0r/palettes.lua: edit that, not this file.',
    ('raycast://theme?version=1&name=hax0r%%20%s&appearance=%s&colors=%s'):format(name, c.light and 'light' or 'dark', table.concat(colors, ',')),
    '',
  }, '\n'))
end

-- Xcode: its own theme format, one file per theme, that `hax0r <theme>` copies over the theme Xcode
-- has selected (see the comment above xcode_apply in the hax0r script). Colors are OKLCH. The syntax
-- roles match nvim's and VS Code's. Fonts aren't in here: Xcode keeps them separately.
-- A one-color theme's syntax colors are its shades, as in XCODE_ROLES; a full-color theme's are the
-- kinds in its syntax table, as in XCODE_KINDS, which fills in the rest from XCODE_ROLES
local XCODE_ROLES = {
  plainText = 'fg',
  comment = 'comment',
  commentEmphasized = 'comment',
  markdown = 'comment',
  keyword = 'bold',
  ['keyword.attribute'] = 'bright',
  preprocessor = 'bright',
  ['preprocessor.macro'] = 'normal',
  ['preprocessor.macroSystem'] = 'normal',
  string = 'normal',
  ['string.regex'] = 'normal',
  number = 'normal',
  ['number.character'] = 'normal',
  link = 'link',
  typeDeclaration = 'bright',
  memberDeclaration = 'normal',
  otherType = 'bright',
  ['otherType.class'] = 'bright',
  ['otherType.type'] = 'bright',
  projectType = 'bright',
  ['projectType.class'] = 'bright',
  ['projectType.type'] = 'bright',
  otherMember = 'normal',
  ['otherMember.constant'] = 'normal',
  ['otherMember.function'] = 'normal',
  ['otherMember.variable'] = 'fg',
  projectMember = 'normal',
  ['projectMember.constant'] = 'normal',
  ['projectMember.function'] = 'normal',
  ['projectMember.variable'] = 'fg',
  debugger = 'bright',
  insertionPointColor = 'cursor',
  invisibles = 'faint',
  currentLineHighlight = 'cursor_line',
  selectedTextBackgroundColor = 'selection_tint',
}

-- Swift's kinds, as Dark+ colors them in VS Code
local XCODE_KINDS = {
  plainText = 'fg',
  comment = 'syntax.comment',
  commentEmphasized = 'syntax.comment',
  markdown = 'syntax.comment',
  keyword = 'syntax.keyword',
  ['keyword.attribute'] = 'syntax.func',
  preprocessor = 'syntax.preproc',
  ['preprocessor.macro'] = 'syntax.func',
  ['preprocessor.macroSystem'] = 'syntax.func',
  string = 'syntax.string',
  ['string.regex'] = 'syntax.regex',
  number = 'syntax.number',
  ['number.character'] = 'syntax.string',
  typeDeclaration = 'syntax.type',
  memberDeclaration = 'syntax.func',
  otherType = 'syntax.type',
  ['otherType.class'] = 'syntax.type',
  ['otherType.type'] = 'syntax.type',
  projectType = 'syntax.type',
  ['projectType.class'] = 'syntax.type',
  ['projectType.type'] = 'syntax.type',
  otherMember = 'syntax.variable',
  ['otherMember.constant'] = 'syntax.constant',
  ['otherMember.function'] = 'syntax.func',
  ['otherMember.variable'] = 'syntax.variable',
  projectMember = 'syntax.variable',
  ['projectMember.constant'] = 'syntax.constant',
  ['projectMember.function'] = 'syntax.func',
  ['projectMember.variable'] = 'syntax.variable',
}

local function xcode(name, c)
  local function color(hex)
    local L, C, h = P.derive.oklch(hex)
    return ('{"chroma":{"exact":%.12f},"gamut":"P3","hue":{"radians":%.12f},"lightness":{"exact":%.12f},"opacity":1}'):format(C, h, L)
  end
  local roles = c.full_color and vim.tbl_extend('force', XCODE_ROLES, XCODE_KINDS) or XCODE_ROLES
  local keys = vim.tbl_keys(roles)
  table.sort(keys)
  local overrides = {}
  for _, key in ipairs(keys) do
    local kind = (key == 'currentLineHighlight' or key == 'selectedTextBackgroundColor') and 'colorWithOpacity' or 'color'
    table.insert(overrides, ('      "%s":{"%s":%s}'):format(key, kind, color(assert(role_color(c, roles[key]), roles[key]))))
  end
  write(('%s/hax0r/xcode/%s.xcworkspacecolortheme'):format(config, name), table.concat({
    '{',
    '  "fileVersion":1,',
    '  "recipe":{',
    ('    "background":{"customColor":%s},'):format(color(c.bg)),
    ('    "colorScheme":"%s",'):format(c.light and 'light' or 'dark'),
    '    "palette":{',
    '      "colorOverrides":{',
    table.concat(overrides, ',\n'),
    '      },',
    ('      "primary":{"custom":%s},'):format(color(c.bright)),
    ('      "secondary":{"custom":%s}'):format(color(c.bg)),
    '    }',
    '  },',
    '  "showsInAllColorSchemes":true',
    '}',
    '',
  }, '\n'))
end

-- Claude Code: every key the base theme has (72 in 2.1.312), so no base color leaks through.
-- When Claude Code updates, check its base for new keys.
-- The base is dark-ansi (light-ansi for black on white): markdown inline code, code-block syntax
-- and diffs ignore overrides and read the base by name, and an -ansi base sends them to palette
-- slots, which each Ghostty theme sets: code text is ansi 7 (0 on light), comments 8, inline
-- code 12 (4 on light). Prose uses the terminal's foreground, not `text`.
-- Diffs render in 256 colors under an -ansi base, so hex values would be rounded; they point at
-- slots 22/28/52/88 instead, which Ghostty and VS Code's terminal set exactly. Dimmed diffs match,
-- like dark-ansi's own.
-- These files stay out of ~/.claude/themes: a running session reads its theme setting only at
-- startup, but it does reload ~/.claude/themes when a file there changes. So the setting stays
-- custom:hax0r, and `hax0r <theme>` copies the chosen file over ~/.claude/themes/hax0r.json.
local claude_keys = {
  {
    { 'text', 'fg' },
    { 'inverseText', 'bg' },
    { 'inactive', 'dim' },
    { 'inactiveShimmer', 'normal' },
    { 'subtle', 'dim' }, -- the pinned prompt draws it on prompt_band, where a neutral gray read as off-theme
    { 'promptBorder', 'dim' },
    { 'promptBorderShimmer', 'border_shimmer' },
    { 'userMessageBackground', 'prompt_band' }, -- dark was too faint to find prompts by
    { 'userMessageBackgroundHover', 'dark' }, -- also colors expanded blocks, where cursor_line looked bright
    { 'composerSidebarBackground', 'dark' },
    { 'bashMessageBackgroundColor', 'bash_band' }, -- tinted toward bashBorder, like the built-in themes
    { 'memoryBackgroundColor', 'dark' },
    { 'selectionBg', 'selection_tint' },
  },
  {
    { 'claude', 'brand' },
    { 'claudeShimmer', 'claude_shimmer' },
    { 'claudeBlue_FOR_SYSTEM_SPINNER', 'normal' },
    { 'claudeBlueShimmer_FOR_SYSTEM_SPINNER', 'bright' },
    { 'clawd_body', 'brand' },
    { 'clawd_background', 'bg' },
    { 'briefLabelClaude', 'brand' },
    { 'briefLabelYou', 'selection' },
  },
  {
    { 'permission', 'selection' },
    { 'permissionShimmer', 'permission_shimmer' },
    { 'suggestion', 'selection' },
    { 'remember', 'selection' },
  },
  {
    { 'autoAccept', 'white' },
    { 'autoAcceptShimmer', 'bright_white' },
    { 'bashBorder', 'white' },
    { 'planMode', 'link' },
    { 'professionalBlue', 'link' },
    { 'skill', 'link' },
    { 'ide', 'link' },
    { 'merged', 'link' },
    { 'background', 'link' },
    { 'effortUltra', 'link' },
    { 'fastMode', 'warning' },
    { 'fastModeShimmer', 'bright_white' },
  },
  {
    { 'success', 'success' },
    { 'error', 'error' },
    { 'warning', 'warning' },
    { 'warningShimmer', 'bright_white' },
    { 'rate_limit_fill', 'normal' },
    { 'rate_limit_empty', 'gray' },
  },
  {
    { 'diffAdded', 'ansi256(22)' },
    { 'diffAddedDimmed', 'ansi256(22)' },
    { 'diffAddedWord', 'ansi256(28)' },
    { 'diffRemoved', 'ansi256(52)' },
    { 'diffRemovedDimmed', 'ansi256(52)' },
    { 'diffRemovedWord', 'ansi256(88)' },
  },
  -- Pinned to Claude Code's own values (the same in its dark and light themes) so subagents stay
  -- distinguishable; an -ansi base would otherwise give them the theme's one color
  {
    { 'red_FOR_SUBAGENTS_ONLY', '#dc2626' },
    { 'blue_FOR_SUBAGENTS_ONLY', '#6a9bcc' },
    { 'green_FOR_SUBAGENTS_ONLY', '#16a34a' },
    { 'yellow_FOR_SUBAGENTS_ONLY', '#ca8a04' },
    { 'purple_FOR_SUBAGENTS_ONLY', '#827dbd' },
    { 'orange_FOR_SUBAGENTS_ONLY', '#d97757' },
    { 'pink_FOR_SUBAGENTS_ONLY', '#c46686' },
    { 'cyan_FOR_SUBAGENTS_ONLY', '#0891b2' },
    { 'chromeYellow', '#fbbc04' },
    { 'rainbow_red', '#eb5f57' },
    { 'rainbow_orange', '#f58b57' },
    { 'rainbow_yellow', '#fac35f' },
    { 'rainbow_green', '#91c882' },
    { 'rainbow_blue', '#82aadc' },
    { 'rainbow_indigo', '#9b82c8' },
    { 'rainbow_violet', '#c882b4' },
    { 'rainbow_red_shimmer', '#fa9b93' },
    { 'rainbow_orange_shimmer', '#ffb989' },
    { 'rainbow_yellow_shimmer', '#ffe19b' },
    { 'rainbow_green_shimmer', '#b9e6b4' },
    { 'rainbow_blue_shimmer', '#b4cdf0' },
    { 'rainbow_indigo_shimmer', '#c3b4e6' },
    { 'rainbow_violet_shimmer', '#e6b4d2' },
  },
}

local function claude_theme(name, c)
  local q = vim.json.encode
  local groups = {}
  for _, group in ipairs(claude_keys) do
    local lines = {}
    for _, kv in ipairs(group) do
      local value = kv[2]:match('^[#a]') and kv[2] or c[kv[2]]
      table.insert(lines, ('    %s: %s'):format(q(kv[1]), q((assert(value, kv[2])))))
    end
    table.insert(groups, table.concat(lines, ',\n'))
  end
  local text = table.concat({
    '{',
    '  "name": ' .. q('hax0r-' .. name) .. ',',
    '  "base": ' .. q(c.light and 'light-ansi' or 'dark-ansi') .. ',',
    '  "_about": ' .. q(('hax0r %s: %s. %s'):format(name, c.title, generated_by('', 'palettes.lua'):sub(2))) .. ',',
    '  "overrides": {',
    table.concat(groups, ',\n\n'),
    '  }',
    '}',
  }, '\n')
  write(('%s/hax0r/claude-code/%s.json'):format(config, name), text .. '\n')
end

-- VS Code: a color theme and a file icon theme per theme, filled in from templates. A theme with
-- a template of its own, themes/<name>.template.jsonc or icons/<name>.template.json, uses that instead
-- (Dark Modern's is VS Code's own theme, so it comes out as a copy). A full-color theme's icons are
-- Seti's, in the colors of its icons table (icons/seti.template.json)
local function template(dir, own, shared)
  local path = ('%s/%s/%s'):format(vscode, dir, own)
  local file = io.open(path)
  if file then
    file:close()
    return read(path), ('%s/%s'):format(dir, own)
  end
  return read(('%s/%s/%s'):format(vscode, dir, shared)), ('%s/%s'):format(dir, shared)
end

local function vscode_themes(name, c)
  local label = 'hax0r ' .. name
  local color_template, source = template('themes', name .. '.template.jsonc', 'color-theme.template.jsonc')
  local icon_template = template('icons', name .. '.template.json',
    c.full_color and 'seti.template.json' or 'icon-theme.template.json')
  local colors = strip_comments(fill(color_template, c, { label = label, type = c.light and 'light' or 'dark' }))
  colors = ('// %s for VS Code: %s.\n%s\n%s'):format(label, c.title,
    generated_by('//', source .. ' and palettes.lua'), colors)
  write(('%s/themes/hax0r-%s-color-theme.json'):format(vscode, name), colors)
  write(('%s/icons/hax0r-%s-icon-theme.json'):format(vscode, name), fill(icon_template, c, {}))
end

local function vscode_package()
  local themes, icons = {}, {}
  for _, name in ipairs(P.order) do
    local c = P[name]
    table.insert(themes, ('\t\t\t{\n\t\t\t\t"label": "hax0r %s",\n\t\t\t\t"uiTheme": "%s",\n\t\t\t\t"path": "./themes/hax0r-%s-color-theme.json"\n\t\t\t}')
      :format(name, c.light and 'vs' or 'vs-dark', name))
    table.insert(icons, ('\t\t\t{\n\t\t\t\t"id": "hax0r-%s",\n\t\t\t\t"label": "hax0r %s",\n\t\t\t\t"path": "./icons/hax0r-%s-icon-theme.json"\n\t\t\t}')
      :format(name, name, name))
  end
  local titles = {}
  for _, name in ipairs(P.order) do
    table.insert(titles, P[name].title)
  end
  write(vscode .. '/package.json', table.concat({
    '{',
    '\t"name": "hax0r-theme",',
    '\t"displayName": "hax0r",',
    ('\t"description": "The hax0r themes (%s), matching nvim, Ghostty and Claude Code. Generated by ~/.config/hax0r/generate.lua.",')
      :format(table.concat(titles, ', ')),
    '\t"version": "1.0.0",',
    '\t"publisher": "stephenmatheis",',
    '\t"engines": {',
    '\t\t"vscode": "^1.80.0"',
    '\t},',
    '\t"categories": [',
    '\t\t"Themes"',
    '\t],',
    '\t"contributes": {',
    '\t\t"themes": [',
    table.concat(themes, ',\n'),
    '\t\t],',
    '\t\t"iconThemes": [',
    table.concat(icons, ',\n'),
    '\t\t]',
    '\t}',
    '}',
  }, '\n') .. '\n')
end

-- VS Code's terminal: a VS Code color theme can only set colors 0-15, so the slots Claude Code's
-- diffs (22/28/52/88) and Starship's errors (196) use are set with OSC 4 instead
local function vscode_terminal()
  local cases = {}
  for _, name in ipairs(P.order) do
    local c = P[name]
    local osc = ''
    for _, slot in ipairs({ { 22, c.diff_add }, { 28, c.diff_add_word }, { 52, c.diff_del }, { 88, c.diff_del_word }, { 196, c.error } }) do
      osc = osc .. ('\\e]4;%d;%s\\a'):format(slot[1], slot[2])
    end
    table.insert(cases, ("        %s) printf '%s' ;;"):format(name == 'green' and '*' or name, osc))
  end
  -- green last, as the fallback
  table.insert(cases, table.remove(cases, 1))
  write(vscode .. '/terminal-palette.zsh', table.concat({
    "# hax0r for VS Code's terminal. Sourced from ~/.zshrc when TERM_PROGRAM is vscode.",
    generated_by('#', 'palettes.lua'),
    '#',
    "# Claude Code draws diff backgrounds with 256-color slots 22/28/52/88, and Starship draws a failed",
    "# command's prompt in slot 196. Each Ghostty theme sets those slots, but a VS Code color theme can",
    "# only set colors 0-15, so set them here with OSC 4, which VS Code's terminal (xterm.js) supports.",
    "# nvim's terminal needs nothing: it passes these slots through to Ghostty.",
    "# Done at every prompt, because a VS Code theme change or window reload resets them, and so",
    "# `hax0r <theme>` reaches terminals that are already open. Only where `hax0r vscode on` was run,",
    "# since VS Code is on some other theme otherwise.",
    '_hax0r_palette() {',
    '    local state=${XDG_STATE_HOME:-$HOME/.local/state}/hax0r theme',
    '    [[ -f $state/vscode ]] || return 0',
    '    read -r theme < $state/theme 2>/dev/null',
    '    case $theme in',
    table.concat(cases, '\n'),
    '    esac',
    '}',
    'precmd_functions+=(_hax0r_palette)',
  }, '\n') .. '\n')
end

-- The list `hax0r` shows: name, title, background, foreground and light or dark, in palettes.lua's order
local function theme_list()
  local lines = {}
  for _, name in ipairs(P.order) do
    local c = P[name]
    table.insert(lines, table.concat({ name, c.title, c.bg, c.fg, c.light and 'light' or 'dark' }, '\t'))
  end
  write(config .. '/hax0r/themes', table.concat(lines, '\n') .. '\n')
end

for _, name in ipairs(P.order) do
  local c = P[name]
  ghostty(name, c)
  tmux(name, c)
  fzf(name, c)
  lazygit(name, c)
  chrome(name, c)
  raycast(name, c)
  delta(name, c)
  xcode(name, c)
  claude_theme(name, c)
  vscode_themes(name, c)
end
vscode_package()
vscode_terminal()
theme_list()
print(changed == 0 and 'Everything was up to date.' or ('Built %d file%s.'):format(changed, changed == 1 and '' or 's'))
