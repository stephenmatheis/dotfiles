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

-- Fills each {{role}} in a template with that role's color (ansiN is palette slot N)
local function fill(template, c, extra)
  return (template:gsub('{{([%w_]+)}}', function(role)
    local slot = role:match('^ansi(%d+)$')
    local value = extra[role] or (slot and c.ansi[tonumber(slot)]) or c[role]
    return assert(value, 'unknown role {{' .. role .. '}}')
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
    { 'promptBorderShimmer', 'normal' },
    { 'userMessageBackground', 'prompt_band' }, -- dark was too faint to find prompts by
    { 'userMessageBackgroundHover', 'dark' }, -- also colors expanded blocks, where cursor_line looked bright
    { 'composerSidebarBackground', 'dark' },
    { 'bashMessageBackgroundColor', 'bash_band' }, -- tinted toward bashBorder, like the built-in themes
    { 'memoryBackgroundColor', 'dark' },
    { 'selectionBg', 'selection_tint' },
  },
  {
    { 'claude', 'bright' },
    { 'claudeShimmer', 'selection' },
    { 'claudeBlue_FOR_SYSTEM_SPINNER', 'normal' },
    { 'claudeBlueShimmer_FOR_SYSTEM_SPINNER', 'bright' },
    { 'clawd_body', 'bright' },
    { 'clawd_background', 'bg' },
    { 'briefLabelClaude', 'bright' },
    { 'briefLabelYou', 'selection' },
  },
  {
    { 'permission', 'selection' },
    { 'permissionShimmer', 'bright_white' },
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
    { 'success', 'normal' },
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

-- VS Code: a color theme and a file icon theme per theme, filled in from templates
local color_template = read(vscode .. '/themes/color-theme.template.jsonc')
local icon_template = read(vscode .. '/icons/icon-theme.template.json')

local function vscode_themes(name, c)
  local label = 'hax0r ' .. name
  local colors = strip_comments(fill(color_template, c, { label = label, type = c.light and 'light' or 'dark' }))
  colors = ('// %s for VS Code: %s.\n%s\n%s'):format(label, c.title,
    generated_by('//', 'themes/color-theme.template.jsonc and palettes.lua'), colors)
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
    "# `hax0r <theme>` reaches terminals that are already open.",
    '_hax0r_palette() {',
    '    local theme',
    '    read -r theme < ${XDG_STATE_HOME:-$HOME/.local/state}/hax0r/theme 2>/dev/null',
    '    case $theme in',
    table.concat(cases, '\n'),
    '    esac',
    '}',
    'precmd_functions+=(_hax0r_palette)',
  }, '\n') .. '\n')
end

-- The list `hax0r` shows: name, title, background and foreground, in palettes.lua's order
local function theme_list()
  local lines = {}
  for _, name in ipairs(P.order) do
    local c = P[name]
    table.insert(lines, table.concat({ name, c.title, c.bg, c.fg }, '\t'))
  end
  write(config .. '/hax0r/themes', table.concat(lines, '\n') .. '\n')
end

for _, name in ipairs(P.order) do
  local c = P[name]
  ghostty(name, c)
  tmux(name, c)
  claude_theme(name, c)
  vscode_themes(name, c)
end
vscode_package()
vscode_terminal()
theme_list()
print(changed == 0 and 'Everything was up to date.' or ('Built %d file%s.'):format(changed, changed == 1 and '' or 's'))
