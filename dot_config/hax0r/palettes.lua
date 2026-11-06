-- The hax0r themes: one palette per theme, each color named for the job it does.
--
-- nvim's colors/hax0r.lua reads this file directly. Every other app's theme files are built
-- from it by generate.lua, so run `hax0r build` after changing a color here.
-- "X @ N%" means X composited over the background at N% (or over another color when named).
--
-- Two kinds of theme live here. A one-color theme (Gr33N and the rest, and the dual themes with a
-- second hue) sets a few shades of its color, and theme() below works out everything else from
-- them. A full-color theme (Dark Modern) sets a syntax table, a color for each kind of code, and
-- most of the colors theme() would otherwise work out: theme() only fills in what a theme leaves out.
--
-- Rules every one-color theme follows, chosen with Gr33N and carried over:
-- - git, diff, problem and link colors aren't set per theme: theme() below builds them from each
--   theme's own colors, the same way every time, so a theme stays one color
-- - ansi 7 is fg and ansi 8 is dim, so Claude Code's code text and comments match nvim's
--   (except a dual theme's comments, which only nvim and VS Code draw in the second hue)
-- - ansi 12 is the selection color, so Claude Code's inline code stands out from prose
--   (black on white uses ansi 4 for this, since Claude Code's light base reads that slot)

local M = {}

M.order = { 'green', 'red', 'blue', 'amber', 'white', 'black', 'pink', 'purple', 'electric', 'cyan-pink', 'pink-cyan', 'dark-modern', 'light-modern' }

-- top composited over base at p (0 to 1), as a hex color
local function mix(top, base, p)
  local out = '#'
  for i = 2, 6, 2 do
    local t, b = tonumber(top:sub(i, i + 1), 16), tonumber(base:sub(i, i + 1), 16)
    out = out .. ('%02x'):format(math.floor(b + (t - b) * p + 0.5))
  end
  return out
end

-- Git, diff, problem, link and hover colors, from the colors each theme sets below:
--   added (and untracked)  bright
--   modified               white (set in the apps' templates, not here)
--   removed                dim
--   ignored                fg @ 60%: a darker shade of the text, where faint's neutral gray read
--                          as off-theme in amber (VS Code's ignored files)
--   staged                 one step dimmer: added is dim, removed is faint
--   faint                  white @ 40%: a gray with the theme's background tone, as readable as the
--                          cyan-gray cursor guide it replaces (nvim's staged change and staged
--                          delete signs)
--   warning (and conflict) bright halfway to white
--   error                  bright_white
--   diff bands             added line and word are bright @ 20% and 33%, removed are white and dim
--                          mixed half and half @ 8% and 20%, so removes are a muted version of
--                          the theme's color, not gray, and fainter than adds: removed lines are
--                          already marked by their − and dim text (Ghostty palette slots 22/28/52/88)
--   link                   fg halfway to selection, so it stands apart from both the prose and
--                          the inline code it sits next to (also Claude Code's plan mode and skills)
--   cursor_line            bright @ 30%: the theme's own color, where Gr33N's cyan cursor guide
--                          read as gray over amber (nvim's cursor line, VS Code's selected rows)
--   hover                  bright @ 15%, half of cursor_line, so the selected row is the stronger
--                          of the two (VS Code's hovers)
--   unfocused_row          dark: VS Code's selected row while its list doesn't have focus
--   change marks           VS Code's gutter, overview ruler and minimap bars, and nvim's signs:
--                          added, white and removed (mark_changed, mark_removed)
--   staged signs           nvim's signs for staged hunks: added_dim, faint and removed_dim
--                          (staged_add, staged_change, staged_delete)
--
-- Black and white have no hue to tell these grays apart, and their white is their bright, so each
-- sets step, a percentage, and the grays are bright @ a multiple of it: hover 1 step, the selected
-- row 2 whether its list has focus or not (so hover never lands on it), removed marks 3, changed
-- marks 6. Staged signs are about half their unstaged one: added bright @ 50%, changed 3 steps,
-- removed 2. All picked by eye, and white on black needed twice black's mix every time: step is 5
-- in black and 10 in white.
--
-- A dual theme also sets accent, accent_bright and accent_dim: a second hue. It takes the jobs one
-- hue can only do with brightness: removed is accent_dim and error accent_bright, links are accent,
-- and the removed bands are accent_dim @ 25% and 42%, nearly as strong as the added ones since
-- their hue sets them apart (accent_dim, because the paler shades are too gray to tint a band).
-- Comments in nvim and VS Code are accent_dim too: the one syntax role that doesn't land on the
-- error or link color. Claude Code's shimmer goes from selection, normal and bright_white to
-- accent_bright and accent.
--
-- Every color here is only a default: a theme that sets one itself keeps its own.
local function theme(t)
  local function default(key, value)
    if t[key] == nil then t[key] = value end
  end
  local dual, step = t.accent ~= nil, t.step
  local function steps(n) return mix(t.bright, t.bg, n * step / 100) end
  local removed_tint = mix(t.white, t.dim, 0.5)
  default('comment', t.syntax and t.syntax.comment or dual and t.accent_dim or t.dim)
  default('faint', mix(t.white, t.bg, 0.40))
  default('added', t.bright)
  default('added_dim', t.dim)
  default('removed', dual and t.accent_dim or t.dim)
  default('removed_dim', dual and mix(t.accent_dim, t.bg, 0.60) or t.faint)
  default('ignored', mix(t.fg, t.bg, 0.60))
  default('warning', mix(t.white, t.bright, 0.5))
  default('error', dual and t.accent_bright or t.bright_white)
  default('diff_add', mix(t.bright, t.bg, 0.20))
  default('diff_add_word', mix(t.bright, t.bg, 0.33))
  default('diff_del', dual and mix(t.accent_dim, t.bg, 0.25) or mix(removed_tint, t.bg, 0.08))
  default('diff_del_word', dual and mix(t.accent_dim, t.bg, 0.42) or mix(removed_tint, t.bg, 0.20))
  default('link', dual and t.accent or mix(t.selection, t.fg, 0.5))
  default('cursor_line', mix(t.bright, t.bg, 0.30))
  default('hover', step and steps(1) or mix(t.bright, t.bg, 0.15))
  default('claude_shimmer', dual and t.accent_bright or t.selection)
  default('border_shimmer', dual and t.accent or t.normal)
  default('permission_shimmer', dual and t.accent_bright or t.bright_white)
  default('selected_row', step and steps(2) or t.cursor_line)
  default('unfocused_row', step and steps(2) or t.dark)
  default('mark_changed', step and steps(6) or t.white)
  default('mark_removed', step and steps(3) or t.removed)
  default('staged_add', step and mix(t.bright, t.bg, 0.5) or t.added_dim)
  default('staged_change', step and steps(3) or t.faint)
  default('staged_delete', step and steps(2) or t.removed_dim)

  -- Jobs a one-color theme gives to a color it already has, which a full-color theme sets apart
  default('changed', t.white)            -- modified files and lines
  default('mark_added', t.added)         -- the change marks' added color: VS Code's gutter, nvim's signs
  default('info', t.bright)              -- diagnostics, under error and warning
  default('hint', t.dim)
  default('success', t.normal)           -- nvim's OK messages, Claude Code's success
  default('brand', t.bright)             -- Claude Code's color for Claude: its ● and ✻, and its name
  default('focus', t.bright)             -- the focused pane's border: lazygit's
  default('match', t.link)               -- the letters a fuzzy search matched: fzf's
  default('list_row', t.cursor_line)     -- the selected row in fzf and lazygit, and in lazygit's
  default('list_row_inactive', t.selection_tint) -- panes that don't have focus
  default('float_bg', t.dark)            -- nvim's floats and completion menu
  default('statusline', t.bright)        -- nvim's statusline text
  default('directory', t.bright)
  default('line_nr', t.dim)
  default('line_nr_active', t.bright)
  default('nontext', t.dim)              -- nvim's ~ past the end of the file
  default('indent', t.dim)               -- indent guides, and the current scope's
  default('indent_active', t.fg)
  default('menu_sel', t.fg)              -- nvim's selected completion: its band and text
  default('menu_sel_text', t.bg)
  default('search', t.fg)                -- search matches, and the one the cursor is on: bands and
  default('search_text', t.bg)           -- their text, 'NONE' to keep the code's own colors
  default('cur_search', t.bright)
  default('cur_search_text', t.bg)
  default('brackets', { t.bright, t.fg }) -- rainbow brackets, by depth, around again after the last
  default('icons', {                     -- file icons, by the color nvim's mini.icons asks for
    red = t.normal, orange = t.normal, yellow = t.normal, green = t.normal, cyan = t.normal,
    azure = t.normal, blue = t.normal, purple = t.normal, grey = t.fg,
  })

  -- Code, by kind. A one-color theme's comes from its shades; a full-color theme's syntax table sets
  -- these and more kinds besides (see Dark Modern's), which nvim and Xcode then tell apart too
  t.full_color = t.syntax ~= nil
  default('syntax', {
    comment = t.comment,
    keyword = t.bold,
    string = t.normal,
    func = t.normal,
    constant = t.normal,
    variable = t.fg,
    type = t.bright,
    special = t.bright,
    preproc = t.bright,
    operator = t.fg,
    delimiter = t.fg,
    title = t.bold,
  })
  default('styles', t.full_color and {} or { comment = 'italic', keyword = 'bold', title = 'bold' })
  return t
end

M.green = theme({
  title = 'HaX0R Gr33N',
  light = false,
  -- HaX0R Gr33N, values from the original .itermcolors
  bg = '#020f01',             -- background
  fg = '#16b10e',             -- foreground
  dark = '#001f0b',           -- ansi 0: floats, statuslines, panels
  normal = '#15d00d',         -- ansi 1-6: strings, functions, constants
  bright = '#19e20e',         -- ansi 9-14: types, active items
  bold = '#19e30f',           -- bold: keywords, titles
  white = '#fafafa',          -- ansi 7: changed lines, Claude Code's auto-accept
  bright_white = '#fefefe',   -- ansi 15
  black = '#001510',          -- ansi 8 (iTerm's): float shadows
  cursor = '#15d00d',         -- cursor
  cursor_text = '#ffffff',    -- cursor text
  selection = '#d4ffc1',      -- selection: inline code, Claude Code's highlights
  -- HaX0R Gr33N, derived from iTerm-only colors
  dim = '#0b8700',            -- badge #14ff00 @ 50%: comments, line numbers
  badge = '#14ff0080',        -- badge itself, for VS Code's count badges
  gray = '#334843',           -- ansi 8 in ghostty's port: Claude Code's empty rate-limit bar
  -- Added: no hax0r theme has these
  selection_tint = '#1b2c18', -- selection @ 12%: selections everywhere, text keeps its color
  border = '#052703',         -- fg @ 15%: VS Code's panel outline, used for every border
  float_border = '#03350b',   -- fg @ 15% over dark
  prompt_band = '#073804',    -- fg @ 25%: Claude Code's prompts
  bash_band = '#2a3529',      -- white @ 16%: Claude Code's ! commands
  ansi = {
    [0] = '#001f0b',
    '#15d00d', '#15d00d', '#15d00d', '#15d00d', '#15d00d', '#15d00d',
    '#16b10e', -- 7, not white: fg, so Claude Code's plain code text matches nvim's variables
    '#0b8700', -- 8, not #334843: dim, so Claude Code's code comments match nvim's
    '#19e20e', '#19e20e', '#19e20e',
    '#d4ffc1', -- 12, not bright: selection mint, so inline code stands out from prose
    '#19e20e', '#19e20e',
    '#fefefe',
  },
})

M.red = theme({
  title = 'HaX0R R3D',
  light = false,
  -- HaX0R R3D, values from the original .itermcolors
  -- Picked from the page (2026-11-01) to read more easily: a darker background and raised text.
  -- Before that: bg #200101, fg and normal #d81010, dim #b00d0d, bright #ff1111
  bg = '#110000',
  fg = '#f01e1e',             -- not R3D's #b10e0e, which read at 2.76:1
  dark = '#100000',
  normal = '#f01e1e',         -- not R3D's ansi 1 #b00d0d: raised with fg (R3D's fg and ansi 1 match)
  bright = '#ff3a3a',         -- not ansi 9 #ff1111: raised with fg
  bold = '#ff3a3a',
  white = '#fafafa',
  bright_white = '#fefefe',
  black = '#0a0000',
  cursor = '#cf1414',
  cursor_text = '#ffffff',
  selection = '#ffc1c1',      -- not R3D's lavender #ebc1ff: red as pale as Gr33N's mint
  dim = '#cf1414',            -- not badge #ff2600 @ 50% (#901400, 2.14:1): raised with fg
  badge = '#cf1414',          -- dim, like the other themes
  gray = '#554040',           -- ansi 8 in ghostty's port
  -- Added
  selection_tint = '#2e1717', -- selection @ 12%
  border = '#320505',         -- fg @ 15%
  float_border = '#320505',   -- fg @ 15% over dark
  prompt_band = '#490808',    -- fg @ 25%
  bash_band = '#362828',      -- white @ 16%
  ansi = {
    [0] = '#100000',
    '#f01e1e', '#f01e1e', '#f01e1e', '#f01e1e', '#f01e1e', '#f01e1e', -- raised from #b00d0d with normal
    '#f01e1e', -- 7: fg
    '#cf1414', -- 8: dim
    '#ff3a3a', '#ff3a3a', '#ff3a3a',
    '#ffc1c1', -- 12: selection
    '#ff3a3a', '#ff3a3a',
    '#fefefe',
  },
})

M.blue = theme({
  title = 'HaX0R BLUE',
  light = false,
  -- HaX0R BLUE, values from the original .itermcolors. Its fg, ansi 1 and ansi 9 are one blue,
  -- so code has fewer levels than Gr33N's
  bg = '#010515',
  fg = '#11b7ff',
  dark = '#010921',
  normal = '#10b6ff',
  bright = '#00b3f7',
  bold = '#00b4f8',
  white = '#fafafa',
  bright_white = '#fefefe',
  black = '#080117',
  cursor = '#10b6ff',
  cursor_text = '#ffffff',
  selection = '#c1e4ff',
  dim = '#0b79ad',            -- not badge @ 50%: BLUE's badge is red-orange #ff2600, so fg @ 65%, as readable as Gr33N's
  badge = '#0b79ad',          -- dim, like the other themes
  gray = '#484157',           -- ansi 8 in ghostty's port
  -- Added
  selection_tint = '#182031', -- selection @ 12%
  border = '#032038',         -- fg @ 15%
  float_border = '#032342',   -- fg @ 15% over dark
  prompt_band = '#053250',    -- fg @ 25%
  bash_band = '#292c3a',      -- white @ 16%
  ansi = {
    [0] = '#010921',
    '#10b6ff', '#10b6ff', '#10b6ff', '#10b6ff', '#10b6ff', '#10b6ff',
    '#11b7ff', -- 7: fg
    '#0b79ad', -- 8: dim
    '#00b3f7', '#00b3f7', '#00b3f7',
    '#c1e4ff', -- 12: selection
    '#00b3f7', '#00b3f7',
    '#fefefe',
  },
})

-- Amber: Gr33N color for color, each as bright (same luminance) in amber phosphor's hue
M.amber = theme({
  title = 'Amber',
  light = false,
  bg = '#140a00',
  fg = '#cc8c00',
  dark = '#261700',
  normal = '#efa500',
  bright = '#ffb000',         -- amber phosphor itself
  bold = '#ffb400',
  white = '#fafafa',
  bright_white = '#fefefe',
  black = '#1b0f00',
  cursor = '#efa500',
  cursor_text = '#140a00',    -- bg: white on amber is hard to read
  selection = '#ffecc1',      -- amber as pale as Gr33N's mint
  dim = '#9c6a00',
  badge = '#9c6a00',
  gray = '#4c4230',           -- as faint as Gr33N's, tinted 30% amber
  selection_tint = '#302517', -- selection @ 12%
  border = '#301e00',         -- fg @ 15%
  float_border = '#3f2900',   -- fg @ 15% over dark
  prompt_band = '#422a00',    -- fg @ 25%
  bash_band = '#393028',      -- white @ 16%
  ansi = {
    [0] = '#261700',
    '#efa500', '#efa500', '#efa500', '#efa500', '#efa500', '#efa500',
    '#cc8c00', -- 7: fg
    '#9c6a00', -- 8: dim
    '#ffb000', '#ffb000', '#ffb000',
    '#ffecc1', -- 12: selection
    '#ffb000', '#ffb000',
    '#fefefe',
  },
})

-- White on black: Gr33N's levels in gray, scaled so the brightest is pure white
M.white = theme({
  title = 'White on black',
  light = false,
  bg = '#000000',
  fg = '#c8c8c8',
  dark = '#1a1a1a',           -- as bright as Gr33N's dark
  normal = '#ebebeb',
  bright = '#ffffff',
  bold = '#ffffff',
  white = '#fafafa',
  bright_white = '#ffffff',
  black = '#000000',
  cursor = '#ebebeb',
  cursor_text = '#000000',
  selection = '#ffffff',      -- inline code: pure white against gray prose
  dim = '#999999',
  badge = '#999999',
  gray = '#3f3f3f',           -- as faint as Gr33N's
  selection_tint = '#1f1f1f', -- selection @ 12%
  border = '#1e1e1e',         -- fg @ 15%
  float_border = '#343434',   -- fg @ 15% over dark
  prompt_band = '#323232',    -- fg @ 25%
  bash_band = '#282828',      -- white @ 16%
  step = 10,                  -- VS Code's grays, in 10% steps of bright (see theme())
  ansi = {
    [0] = '#1a1a1a',
    '#ebebeb', '#ebebeb', '#ebebeb', '#ebebeb', '#ebebeb', '#ebebeb',
    '#c8c8c8', -- 7: fg
    '#999999', -- 8: dim
    '#ffffff', '#ffffff', '#ffffff',
    '#ffffff', -- 12: selection
    '#ffffff', '#ffffff',
    '#ffffff',
  },
})

-- Black on white: white on black mirrored, each color at the same contrast against white
M.black = theme({
  title = 'Black on white',
  light = true,
  bg = '#ffffff',
  fg = '#333333',
  dark = '#eaeaea',
  normal = '#191919',
  bright = '#000000',
  bold = '#000000',
  white = '#000000',          -- the loud neutral: changed lines, auto-accept, ! commands
  bright_white = '#000000',
  black = '#000000',
  cursor = '#191919',
  cursor_text = '#ffffff',
  selection = '#000000',      -- inline code: pure black against gray prose
  dim = '#565656',
  badge = '#565656',
  gray = '#b7b7b7',           -- as faint as Gr33N's
  selection_tint = '#e6e6e6', -- selection @ 10%
  border = '#e0e0e0',         -- fg @ 15%
  float_border = '#cfcfcf',   -- fg @ 15% over dark
  prompt_band = '#cccccc',    -- fg @ 25%
  bash_band = '#e6e6e6',      -- black @ 10%
  step = 5,                   -- VS Code's grays, in 5% steps of bright (see theme())
  ansi = {
    [0] = '#333333', -- 0, not dark: fg, since Claude Code's light base draws code text in slot 0
    '#191919', '#191919', '#191919',
    '#000000', -- 4: selection, since Claude Code's light base draws inline code in slot 4
    '#191919', '#191919',
    '#eaeaea', -- 7: dark, the mirror of slot 0
    '#565656', -- 8: dim
    '#000000', '#000000', '#000000', '#000000', '#000000', '#000000',
    '#000000', -- 15: the strongest text, like bright white on a dark theme
  },
})

-- Pink: Gr33N's colors at OKLCH hue 355, each as readable against the background as Gr33N's
-- (made by derive.mono and derive.duo below, then frozen as hex, like the others)
M.pink = theme({
  title = 'Pink',
  light = false,
  bg = '#1a020d',             -- background
  fg = '#fd5ca7',             -- foreground
  dark = '#340013',           -- ansi 0: floats, statuslines, panels
  normal = '#fe91bd',         -- ansi 1-6: strings, functions, constants
  bright = '#feaaca',         -- ansi 9-14: types, active items
  bold = '#feabcb',           -- bold: keywords, titles
  white = '#fafafa',          -- ansi 7: changed lines, Claude Code's auto-accept
  bright_white = '#fefefe',   -- ansi 15
  black = '#260012',          -- ansi 8: float shadows
  cursor = '#fe91bd',         -- cursor
  cursor_text = '#1a020d',    -- cursor text
  selection = '#ffedf5',      -- selection: inline code, Claude Code's highlights
  dim = '#de0084',            -- comments, line numbers
  badge = '#de0084',          -- dim, like the other themes
  gray = '#603747',           -- ansi 8 in ghostty's port: Claude Code's empty rate-limit bar
  selection_tint = '#351e29', -- selection @ 12%: selections everywhere, text keeps its color
  border = '#3c1024',         -- fg @ 15%: VS Code's panel outline, used for every border
  float_border = '#520e29',   -- fg @ 15% over dark
  prompt_band = '#531934',    -- fg @ 25%: Claude Code's prompts
  bash_band = '#3e2a33',      -- white @ 16%: Claude Code's ! commands
  ansi = {
    [0] = '#340013',
    '#fe91bd', '#fe91bd', '#fe91bd', '#fe91bd', '#fe91bd', '#fe91bd',
    '#fd5ca7', -- 7: fg
    '#de0084', -- 8: dim
    '#feaaca', '#feaaca', '#feaaca',
    '#ffedf5', -- 12: selection
    '#feaaca', '#feaaca',
    '#fefefe',
  },
})

-- Purple: Gr33N's colors at OKLCH hue 300, each as readable against the background as Gr33N's
-- (made by derive.mono and derive.duo below, then frozen as hex, like the others)
M.purple = theme({
  title = 'Purple',
  light = false,
  bg = '#100223',             -- background
  fg = '#b07efd',             -- foreground
  dark = '#27003b',           -- ansi 0: floats, statuslines, panels
  normal = '#c3a2fe',         -- ansi 1-6: strings, functions, constants
  bright = '#cfb6fe',         -- ansi 9-14: types, active items
  bold = '#cfb7fe',           -- bold: keywords, titles
  white = '#fafafa',          -- ansi 7: changed lines, Claude Code's auto-accept
  bright_white = '#fefefe',   -- ansi 15
  black = '#180032',          -- ansi 8: float shadows
  cursor = '#c3a2fe',         -- cursor
  cursor_text = '#100223',    -- cursor text
  selection = '#f2f0ff',      -- selection: inline code, Claude Code's highlights
  dim = '#993bff',            -- comments, line numbers
  badge = '#993bff',          -- dim, like the other themes
  gray = '#4c3a6a',           -- ansi 8 in ghostty's port: Claude Code's empty rate-limit bar
  selection_tint = '#2b1f3d', -- selection @ 12%: selections everywhere, text keeps its color
  border = '#281544',         -- fg @ 15%: VS Code's panel outline, used for every border
  float_border = '#3c1358',   -- fg @ 15% over dark
  prompt_band = '#38215a',    -- fg @ 25%: Claude Code's prompts
  bash_band = '#352a45',      -- white @ 16%: Claude Code's ! commands
  ansi = {
    [0] = '#27003b',
    '#c3a2fe', '#c3a2fe', '#c3a2fe', '#c3a2fe', '#c3a2fe', '#c3a2fe',
    '#b07efd', -- 7: fg
    '#993bff', -- 8: dim
    '#cfb6fe', '#cfb6fe', '#cfb6fe',
    '#f2f0ff', -- 12: selection
    '#cfb6fe', '#cfb6fe',
    '#fefefe',
  },
})

-- Electric blue: Gr33N's colors at OKLCH hue 258, each as readable against the background as Gr33N's
-- (made by derive.mono and derive.duo below, then frozen as hex, like the others)
M.electric = theme({
  title = 'Electric blue',
  light = false,
  bg = '#010a1e',             -- background
  fg = '#5398fd',             -- foreground
  dark = '#060056',           -- ansi 0: floats, statuslines, panels
  normal = '#83b5fe',         -- ansi 1-6: strings, functions, constants
  bright = '#9dc5fe',         -- ansi 9-14: types, active items
  bold = '#9fc6fe',           -- bold: keywords, titles
  white = '#fafafa',          -- ansi 7: changed lines, Claude Code's auto-accept
  bright_white = '#fefefe',   -- ansi 15
  black = '#000f2c',          -- ansi 8: float shadows
  cursor = '#83b5fe',         -- cursor
  cursor_text = '#010a1e',    -- cursor text
  selection = '#eaf3ff',      -- selection: inline code, Claude Code's highlights
  dim = '#006feb',            -- comments, line numbers
  badge = '#006feb',          -- dim, like the other themes
  gray = '#314462',           -- ansi 8 in ghostty's port: Claude Code's empty rate-limit bar
  selection_tint = '#1d2639', -- selection @ 12%: selections everywhere, text keeps its color
  border = '#0d1f3f',         -- fg @ 15%: VS Code's panel outline, used for every border
  float_border = '#12176f',   -- fg @ 15% over dark
  prompt_band = '#162e56',    -- fg @ 25%: Claude Code's prompts
  bash_band = '#293041',      -- white @ 16%: Claude Code's ! commands
  ansi = {
    [0] = '#060056',
    '#83b5fe', '#83b5fe', '#83b5fe', '#83b5fe', '#83b5fe', '#83b5fe',
    '#5398fd', -- 7: fg
    '#006feb', -- 8: dim
    '#9dc5fe', '#9dc5fe', '#9dc5fe',
    '#eaf3ff', -- 12: selection
    '#9dc5fe', '#9dc5fe',
    '#fefefe',
  },
})

-- Cyan + pink: cyan (hue 195) with pink (355) as the second color, at Gr33N's contrast
-- (made by derive.mono and derive.duo below, then frozen as hex, like the others)
M['cyan-pink'] = theme({
  title = 'Cyan + pink',
  light = false,
  bg = '#010e0e',             -- background
  fg = '#11aaaa',             -- foreground
  dark = '#001d20',           -- ansi 0: floats, statuslines, panels
  normal = '#10c8c8',         -- ansi 1-6: strings, functions, constants
  bright = '#11d9d9',         -- ansi 9-14: types, active items
  bold = '#12dada',           -- bold: keywords, titles
  white = '#fafafa',          -- ansi 7: changed lines, Claude Code's auto-accept
  bright_white = '#fefefe',   -- ansi 15
  black = '#001414',          -- ansi 8: float shadows
  cursor = '#10c8c8',         -- cursor
  cursor_text = '#010e0e',    -- cursor text
  selection = '#befff9',      -- selection: inline code, Claude Code's highlights
  dim = '#008281',            -- comments, line numbers
  badge = '#008281',          -- dim, like the other themes
  gray = '#334847',           -- ansi 8 in ghostty's port: Claude Code's empty rate-limit bar
  selection_tint = '#182b2a', -- selection @ 12%: selections everywhere, text keeps its color
  border = '#032525',         -- fg @ 15%: VS Code's panel outline, used for every border
  float_border = '#033235',   -- fg @ 15% over dark
  prompt_band = '#053535',    -- fg @ 25%: Claude Code's prompts
  bash_band = '#293434',      -- white @ 16%: Claude Code's ! commands
  accent = '#fe91bd',         -- the second color: links
  accent_bright = '#feaaca',  -- the second color: errors
  accent_dim = '#de0084',     -- the second color: removed lines and their bands
  ansi = {
    [0] = '#001d20',
    '#10c8c8', '#10c8c8', '#10c8c8', '#10c8c8', '#10c8c8', '#10c8c8',
    '#11aaaa', -- 7: fg
    '#008281', -- 8: dim
    '#11d9d9', '#11d9d9', '#11d9d9',
    '#befff9', -- 12: selection
    '#11d9d9', '#11d9d9',
    '#fefefe',
  },
})

-- Pink + cyan: pink (hue 355) with cyan (195) as the second color, at Gr33N's contrast
-- (made by derive.mono and derive.duo below, then frozen as hex, like the others)
M['pink-cyan'] = theme({
  title = 'Pink + cyan',
  light = false,
  bg = '#1a020d',             -- background
  fg = '#fd5ca7',             -- foreground
  dark = '#340013',           -- ansi 0: floats, statuslines, panels
  normal = '#fe91bd',         -- ansi 1-6: strings, functions, constants
  bright = '#feaaca',         -- ansi 9-14: types, active items
  bold = '#feabcb',           -- bold: keywords, titles
  white = '#fafafa',          -- ansi 7: changed lines, Claude Code's auto-accept
  bright_white = '#fefefe',   -- ansi 15
  black = '#260012',          -- ansi 8: float shadows
  cursor = '#fe91bd',         -- cursor
  cursor_text = '#1a020d',    -- cursor text
  selection = '#ffedf5',      -- selection: inline code, Claude Code's highlights
  dim = '#de0084',            -- comments, line numbers
  badge = '#de0084',          -- dim, like the other themes
  gray = '#603747',           -- ansi 8 in ghostty's port: Claude Code's empty rate-limit bar
  selection_tint = '#351e29', -- selection @ 12%: selections everywhere, text keeps its color
  border = '#3c1024',         -- fg @ 15%: VS Code's panel outline, used for every border
  float_border = '#520e29',   -- fg @ 15% over dark
  prompt_band = '#531934',    -- fg @ 25%: Claude Code's prompts
  bash_band = '#3e2a33',      -- white @ 16%: Claude Code's ! commands
  accent = '#10c8c8',         -- the second color: links
  accent_bright = '#11d9d9',  -- the second color: errors
  accent_dim = '#008281',     -- the second color: removed lines and their bands
  ansi = {
    [0] = '#340013',
    '#fe91bd', '#fe91bd', '#fe91bd', '#fe91bd', '#fe91bd', '#fe91bd',
    '#fd5ca7', -- 7: fg
    '#de0084', -- 8: dim
    '#feaaca', '#feaaca', '#feaaca',
    '#ffedf5', -- 12: selection
    '#feaaca', '#feaaca',
    '#fefefe',
  },
})

-- Dark Modern: VS Code's default dark theme, the first full-color theme. Copied from VS Code 1.144's
-- own files (Dark Modern, and the Dark+ and Dark (Visual Studio) themes it builds on) and its
-- defaults for what none of them sets. Each color names the VS Code color it's from; "picked" marks
-- the ones for apps VS Code has no counterpart for. VS Code itself gets Dark Modern back from
-- vscode/hax0r-theme/themes/dark-modern.template.jsonc, which uses these colors by name
M['dark-modern'] = (function()
  local bg = '#1f1f1f'
  -- Dark+'s syntax colors, shared by several kinds of code each
  local blue, purple, orange, yellow = '#569cd6', '#c586c0', '#ce9178', '#dcdcaa'
  local teal, light_blue, bright_blue, green = '#4ec9b0', '#9cdcfe', '#4fc1ff', '#6a9955'
  local pale_green, gold, red = '#b5cea8', '#d7ba7d', '#d16969'
  -- VS Code's problem colors, also its chart colors
  local error, warning, info = '#f14c4c', '#cca700', '#59a4f9' -- editorError, editorWarning, editorInfo
  -- diffEditor's bands are these @ 20%, the changed words' over their line's band
  local add_tint, add_word_tint, del_tint = '#9bb955', '#9ccc2c', '#ff0000'
  local diff_add, diff_del = mix(add_tint, bg, 0.2), mix(del_tint, bg, 0.2)
  local mark_added, mark_changed, mark_removed = '#2ea043', '#0078d4', '#f85149'
  return theme({
    title = 'Dark Modern',
    light = false,
    -- Dark Modern's own
    bg = bg,                      -- editor.background
    fg = '#cccccc',               -- editor.foreground, and most text
    dark = '#181818',             -- sideBar, panel, statusBar, titleBar: the frame around the editor
    float_bg = '#202020',         -- editorWidget.background: hovers, completions, find
    border = '#2b2b2b',           -- panel.border, tab.border and the rest
    float_border = '#454545',     -- menu.border
    dim = '#9d9d9d',              -- descriptionForeground, tab.inactiveForeground
    bright = '#ffffff',           -- tab.activeForeground, settings.headerForeground
    focus = '#0078d4',            -- focusBorder, button.background, the active tab's top line
    line_nr = '#6e7681',          -- editorLineNumber.foreground
    line_nr_active = '#cccccc',   -- editorLineNumber.activeForeground
    statusline = '#cccccc',       -- statusBar.foreground
    directory = '#cccccc',        -- sideBar.foreground: folders aren't set apart in the explorer
    indent = '#404040',           -- editorIndentGuide.background1
    indent_active = '#707070',    -- editorIndentGuide.activeBackground1
    badge = '#616161',            -- badge.background
    link = '#4daafc',             -- textLink.foreground
    cur_search = '#9e6a03',       -- editor.findMatchBackground
    cur_search_text = 'NONE',     -- VS Code keeps the code's own colors on a match
    mark_added = mark_added,      -- editorGutter.addedBackground
    mark_changed = mark_changed,  -- editorGutter.modifiedBackground
    mark_removed = mark_removed,  -- editorGutter.deletedBackground
    -- VS Code's defaults, which Dark Modern keeps
    selection_tint = '#264f78',   -- editor.selectionBackground
    cursor_line = '#282828',      -- editor.lineHighlightBorder: an outline in VS Code, a band elsewhere
    cursor = '#aeafad',           -- editorCursor.foreground
    cursor_text = bg,
    search_tint = '#ea5c00',      -- editor.findMatchHighlightBackground is this @ 33%
    search = mix('#ea5c00', bg, 0x55 / 255),
    search_text = 'NONE',
    nontext_tint = '#e3e4e2',     -- editorWhitespace.foreground is this @ 16%
    nontext = mix('#e3e4e2', bg, 0x29 / 255),
    selected_row = '#04395e',     -- list.activeSelectionBackground
    menu_sel = '#04395e',         -- the same, in the completion list
    menu_sel_text = '#ffffff',    -- list.activeSelectionForeground
    hover = '#2a2d2e',            -- list.hoverBackground
    unfocused_row = '#37373d',    -- list.inactiveSelectionBackground
    match = '#2aaaff',            -- list.highlightForeground: the letters Quick Open matched
    list_row = '#04395e',         -- list.activeSelectionBackground, in fzf and lazygit
    list_row_inactive = '#37373d', -- list.inactiveSelectionBackground
    error = error,
    warning = warning,
    info = info,
    hint = mix('#eeeeee', bg, 0.7), -- editorHint.foreground
    brackets = { '#ffd700', '#da70d6', '#179fff' }, -- editorBracketHighlight.foreground1 to 3
    added = '#81b88b',            -- gitDecoration.addedResourceForeground
    untracked = '#73c991',        -- gitDecoration.untrackedResourceForeground, and renamed
    changed = '#e2c08d',          -- gitDecoration.modifiedResourceForeground
    removed = '#c74e39',          -- gitDecoration.deletedResourceForeground
    ignored = '#8c8c8c',          -- gitDecoration.ignoredResourceForeground
    conflict = '#e4676b',         -- gitDecoration.conflictingResourceForeground
    diff_add_tint = add_tint,     -- diffEditor.insertedLineBackground
    diff_add_word_tint = add_word_tint, -- diffEditor.insertedTextBackground
    diff_del_tint = del_tint,     -- diffEditor.removedLineBackground and removedTextBackground
    diff_add = diff_add,
    diff_add_word = mix(add_word_tint, diff_add, 0.2),
    diff_del = diff_del,
    diff_del_word = mix(del_tint, diff_del, 0.2),
    hues = {                      -- charts.*, for Raycast; magenta is the terminal's ansi 13
      red = error, orange = '#d18616', yellow = warning, green = '#89d185', blue = info, purple = '#b180d7',
      magenta = '#d670d6',
    },
    icons = {                     -- the Seti icon theme's colors
      blue = '#519aba', red = '#cc3e44', orange = '#e37933', purple = '#a074c4', green = '#8dc149',
      yellow = '#cbcb41', white = '#d4d7d6', pink = '#f55385', grey = '#6d8086', steel = '#4d5a5e',
      ignore = '#41535b', cyan = '#519aba', azure = '#519aba', -- nvim's names for Seti's blue
    },
    -- Dark+'s syntax colors, by kind
    syntax = {
      comment = green,
      keyword = blue,             -- let, function, class, new, typeof, and ${ } in template strings
      control = purple,           -- if, for, return, import, try
      storage = blue,             -- const, static, struct
      preproc = purple,           -- #include, #define
      macro = blue,               -- a macro's name
      string = orange,
      escape = gold,              -- \n, and other special characters in strings
      regex = red,
      selector = gold,            -- CSS's selectors
      number = pale_green,
      constant = bright_blue,     -- UPPER_CASE constants, enum members
      builtin = blue,             -- true, false, null, this, self
      func = yellow,
      type = teal,                -- classes, types, namespaces
      variable = light_blue,      -- variables, parameters, properties
      attribute = light_blue,     -- HTML's attributes
      tag = blue,                 -- HTML's tags
      tag_bracket = '#808080',    -- HTML's < >
      operator = '#d4d4d4',       -- keyword.operator
      plain = '#d4d4d4',          -- code inside other code, like ${ } in a template string
      delimiter = '#cccccc',      -- punctuation: Dark+ leaves it the editor's text color
      special = blue,
      label = '#c8c8c8',
      title = blue,               -- nvim's titles, like a markdown heading
      heading = blue,             -- markup.heading
      strong = blue,              -- markup.bold
      emphasis = purple,          -- markup.italic
      raw = orange,               -- markup.inline.raw: `code` in markdown
      quote = green,              -- a markdown quote's >
      list = '#6796e6',           -- a markdown list's - or 1.
      inserted = pale_green,      -- markup.inserted: + lines in a .diff file
      deleted = orange,           -- markup.deleted
      modified = blue,            -- markup.changed
    },
    styles = { title = 'bold', heading = 'bold', strong = 'bold', emphasis = 'italic' },
    -- The terminal's colors: VS Code's terminal.ansi* defaults, as they are, so Claude Code's code
    -- text is ansi 7, its comments ansi 8 and its inline code ansi 12, as in VS Code's terminal
    ansi = {
      [0] = '#000000',
      '#cd3131', '#0dbc79', '#e5e510', '#2472c8', '#bc3fbc', '#11a8cd',
      '#e5e5e5',
      '#666666',
      '#f14c4c', '#23d18b', '#f5f543', '#3b8eea', '#d670d6', '#29b8db',
      '#e5e5e5',
    },
    -- Picked: jobs VS Code has no color for, left to settle on the preview page
    normal = '#cccccc',           -- one-color themes' middle shade: Claude Code's rate-limit bar, Chrome's icons
    bold = '#ffffff',             -- nvim's float titles and bracket match
    white = '#ffffff',            -- Claude Code's auto-accept and ! border
    bright_white = '#ffffff',
    black = '#000000',            -- nvim's float shadows
    selection = '#85b6ff',        -- chat.slashCommandForeground: Claude Code's permission and suggestions
    gray = '#3c3c3c',             -- Claude Code's empty rate-limit bar: input.border
    prompt_band = mix('#264f78', bg, 0.3), -- chat.requestBubbleBackground: Claude Code's prompts
    bash_band = '#313131',        -- input.background: Claude Code's ! commands
    faint = mix('#e3e4e2', bg, 0x29 / 255), -- as editorWhitespace: fzf's borders, Xcode's invisibles
    success = '#73c991',          -- testing.iconPassed: Claude Code's success
    staged_add = mix(mark_added, bg, 0.5), -- nvim's staged signs: the change marks @ 50%
    staged_change = mix(mark_changed, bg, 0.5),
    staged_delete = mix(mark_removed, bg, 0.5),
    border_shimmer = '#0078d4',   -- focusBorder: Claude Code's prompt border while it works
    brand = '#0078d4',            -- focusBorder: Claude, in Claude Code, in the theme's own blue
    claude_shimmer = '#4daafc',   -- textLink.foreground: the shimmer across it
  })
end)()

-- Light Modern: VS Code's Light Modern, Dark Modern's light twin, copied the same way. Colors come
-- from VS Code 1.145's Light Modern and Light (Visual Studio) themes, its own defaults for a light
-- theme where those don't set one, and Light+'s syntax colors
M['light-modern'] = (function()
  local bg = '#ffffff'
  -- Light+'s syntax colors, shared by several kinds of code each
  local blue, purple, maroon, string_red = '#0000ff', '#af00db', '#800000', '#a31515'
  local green, number_green, brown, teal = '#008000', '#098658', '#795e26', '#267f99'
  local navy, var_blue, json_blue = '#000080', '#001080', '#0451a5'
  -- VS Code's problem colors for a light theme, also its chart colors
  local error, warning, info = '#e51400', '#bf8803', '#0063d3' -- editorError, editorWarning, editorInfo
  -- diffEditor's bands are these @ 20%, the added words' @ 25% over their line's band
  local add_tint, add_word_tint, del_tint = '#9bb955', '#9ccc2c', '#ff0000'
  local diff_add, diff_del = mix(add_tint, bg, 0.2), mix(del_tint, bg, 0.2)
  local mark_added, mark_changed, mark_removed = '#2ea043', '#005fb8', '#f85149'
  return theme({
    title = 'Light Modern',
    light = true,
    -- Light Modern's own
    bg = bg,                      -- editor.background
    fg = '#3b3b3b',               -- editor.foreground, and most text
    dark = '#f8f8f8',             -- sideBar, panel, statusBar, titleBar: the frame around the editor
    float_bg = '#f8f8f8',         -- editorWidget.background: hovers, completions, find
    border = '#e5e5e5',           -- panel.border, tab.border and the rest
    float_border = '#cecece',     -- menu.border, input.border
    dim = '#616161',              -- tab.inactiveForeground (descriptionForeground is the text color here)
    bright = '#1f1f1f',           -- settings.headerForeground (tab.activeForeground is the text color here)
    focus = '#005fb8',            -- focusBorder, button.background, the active tab's top line
    line_nr = '#6e7681',          -- editorLineNumber.foreground
    line_nr_active = '#171184',   -- editorLineNumber.activeForeground
    statusline = '#3b3b3b',       -- statusBar.foreground
    directory = '#3b3b3b',        -- sideBar.foreground: folders aren't set apart in the explorer
    indent = '#d3d3d3',           -- editorIndentGuide.background1
    indent_active = '#939393',    -- editorIndentGuide.activeBackground1
    badge = '#cccccc',            -- badge.background
    link = '#005fb8',             -- textLink.foreground
    mark_added = mark_added,      -- editorGutter.addedBackground
    mark_changed = mark_changed,  -- editorGutter.modifiedBackground
    mark_removed = mark_removed,  -- editorGutter.deletedBackground
    selected_row = '#e8e8e8',     -- list.activeSelectionBackground
    menu_sel = '#e8e8e8',         -- the same, in the completion list
    menu_sel_text = '#000000',    -- list.activeSelectionForeground
    hover = '#f2f2f2',            -- list.hoverBackground
    list_row = '#e8e8e8',         -- list.activeSelectionBackground, in fzf and lazygit
    -- VS Code's defaults for a light theme, which Light Modern keeps
    cur_search = '#a8ac94',       -- editor.findMatchBackground
    cur_search_text = 'NONE',     -- VS Code keeps the code's own colors on a match
    selection_tint = '#add6ff',   -- editor.selectionBackground
    cursor_line = '#eeeeee',      -- editor.lineHighlightBorder: an outline in VS Code, a band elsewhere
    cursor = '#000000',           -- editorCursor.foreground
    cursor_text = bg,
    search_tint = '#ea5c00',      -- editor.findMatchHighlightBackground is this @ 33%
    search = mix('#ea5c00', bg, 0x55 / 255),
    search_text = 'NONE',
    nontext_tint = '#333333',     -- editorWhitespace.foreground is this @ 20%
    nontext = mix('#333333', bg, 0x33 / 255),
    unfocused_row = '#e4e6f1',    -- list.inactiveSelectionBackground
    match = '#0066bf',            -- list.highlightForeground: the letters Quick Open matched
    list_row_inactive = '#e4e6f1', -- list.inactiveSelectionBackground
    error = error,
    warning = warning,
    info = info,
    hint = '#6c6c6c',             -- editorHint.foreground
    brackets = { '#0431fa', '#319331', '#7b3814' }, -- editorBracketHighlight.foreground1 to 3
    added = '#587c0c',            -- gitDecoration.addedResourceForeground
    untracked = '#007100',        -- gitDecoration.untrackedResourceForeground, and renamed
    changed = '#895503',          -- gitDecoration.modifiedResourceForeground
    removed = '#ad0707',          -- gitDecoration.deletedResourceForeground
    ignored = '#8e8e90',          -- gitDecoration.ignoredResourceForeground
    conflict = '#ad0707',         -- gitDecoration.conflictingResourceForeground
    diff_add_tint = add_tint,     -- diffEditor.insertedLineBackground
    diff_add_word_tint = add_word_tint, -- diffEditor.insertedTextBackground
    diff_del_tint = del_tint,     -- diffEditor.removedLineBackground and removedTextBackground
    diff_add = diff_add,
    diff_add_word = mix(add_word_tint, diff_add, 0x40 / 255),
    diff_del = diff_del,
    diff_del_word = mix(del_tint, diff_del, 0.2),
    hues = {                      -- charts.*, for Raycast; magenta is the terminal's ansi 13
      red = error, orange = '#d18616', yellow = warning, green = '#388a34', blue = info, purple = '#652d90',
      magenta = '#d670d6',
    },
    icons = {                     -- the Seti icon theme's colors for a light theme
      blue = '#498ba7', red = '#b8383d', orange = '#cc6d2e', purple = '#9068b0', green = '#7fae42',
      yellow = '#b7b73b', white = '#bfc2c1', pink = '#dd4b78', grey = '#627379', steel = '#455155',
      ignore = '#3b4b52', cyan = '#498ba7', azure = '#498ba7', -- nvim's names for Seti's blue
    },
    -- Light+'s syntax colors, by kind
    syntax = {
      comment = green,
      keyword = blue,             -- let, function, class, new, typeof, and ${ } in template strings
      control = purple,           -- if, for, return, import, try
      storage = blue,             -- const, static, struct
      preproc = purple,           -- #include, #define
      macro = blue,               -- a macro's name
      string = string_red,
      escape = '#ee0000',         -- \n, and other special characters in strings
      regex = '#811f3f',
      selector = maroon,          -- CSS's selectors
      number = number_green,
      constant = '#0070c1',       -- UPPER_CASE constants, enum members
      builtin = blue,             -- true, false, null, this, self
      func = brown,
      type = teal,                -- classes, types, namespaces
      variable = var_blue,        -- variables, parameters, properties
      attribute = '#e50000',      -- HTML's attributes
      tag = maroon,               -- HTML's tags
      tag_bracket = maroon,       -- HTML's < >
      operator = '#000000',       -- keyword.operator
      plain = '#000000',          -- code inside other code, like ${ } in a template string
      delimiter = '#3b3b3b',      -- punctuation: Light+ leaves it the editor's text color
      special = blue,
      label = '#000000',
      title = maroon,             -- nvim's titles, like a markdown heading
      heading = maroon,           -- markup.heading
      strong = navy,              -- markup.bold
      emphasis = '#800080',       -- markup.italic
      raw = maroon,               -- markup.inline.raw: `code` in markdown
      quote = json_blue,          -- a markdown quote's >
      list = json_blue,           -- a markdown list's - or 1.
      inserted = number_green,    -- markup.inserted: + lines in a .diff file
      deleted = string_red,       -- markup.deleted
      modified = json_blue,       -- markup.changed
    },
    styles = { title = 'bold', heading = 'bold', strong = 'bold', emphasis = 'italic' },
    -- The terminal's colors: VS Code's terminal.ansi* defaults for a light theme, as they are, so
    -- Claude Code's code text is ansi 0, its comments ansi 8 and its inline code ansi 4, as in VS
    -- Code's terminal
    ansi = {
      [0] = '#000000',
      '#cd3131', '#107c10', '#949800', '#0451a5', '#bc05bc', '#0598bc',
      '#555555',
      '#666666',
      '#f14c4c', '#14ce14', '#b5ba00', '#3b8eea', '#d670d6', '#29b8db',
      '#a5a5a5',
    },
    -- Picked: jobs VS Code has no color for, chosen to match Dark Modern's picks
    normal = '#3b3b3b',           -- one-color themes' middle shade: Claude Code's rate-limit bar, Chrome's icons
    bold = '#1f1f1f',             -- nvim's float titles and bracket match, as bright
    white = '#000000',            -- the loud neutral, black on a light theme as in Black on white:
    bright_white = '#000000',     -- Claude Code's auto-accept and ! border
    black = '#000000',            -- nvim's float shadows
    selection = '#26569e',        -- chat.slashCommandForeground: Claude Code's permission and suggestions
    gray = '#cecece',             -- Claude Code's empty rate-limit bar: input.border
    prompt_band = mix('#add6ff', bg, 0.3), -- chat.requestBubbleBackground: Claude Code's prompts
    bash_band = '#f2f2f2',        -- list.hoverBackground: Claude Code's ! commands (input.background is white here)
    faint = mix('#333333', bg, 0x33 / 255), -- as editorWhitespace: fzf's borders, Xcode's invisibles
    success = '#388a34',          -- charts.green: testing.iconPassed's #73c991 is too faint on white
    staged_add = mix(mark_added, bg, 0.5), -- nvim's staged signs: the change marks @ 50%
    staged_change = mix(mark_changed, bg, 0.5),
    staged_delete = mix(mark_removed, bg, 0.5),
    border_shimmer = '#005fb8',   -- focusBorder: Claude Code's prompt border while it works
    brand = '#005fb8',            -- focusBorder: Claude, in Claude Code, in the theme's own blue
    claude_shimmer = '#68a3da',   -- tab.selectedBorderTop: a lighter blue, as Dark Modern's shimmer is
  })
end)()

-- Deriving a theme in another hue: Gr33N's colors turned to a new OKLCH hue. Each keeps its
-- lightness and how much of the chroma sRGB allows at its hue, so every hue gets Gr33N's levels
-- and none comes out darker or duller by accident. The rest is filled in the way the hand-set
-- themes do it.
--   mono(title, hue)               one hue
--   duo(title, hue, accent_hue)    a second hue for comments, removed, errors and links (see theme())
-- Hues are OKLCH degrees, or `hue(color)` for a color's own. Each takes a last argument, `equal`:
-- 'contrast' (the default) gives every color Gr33N's contrast against the background, as amber was
-- matched; 'lightness' gives it only Gr33N's lightness, which is more vivid and dimmer to read.

-- hex as linear-light r, g, b, each 0 to 1
local function linear(hex)
  local out = {}
  for i = 2, 6, 2 do
    local v = tonumber(hex:sub(i, i + 1), 16) / 255
    table.insert(out, v <= 0.04045 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4)
  end
  return out[1], out[2], out[3]
end

local function contrast(a, b)
  local function luminance(hex)
    local r, g, bl = linear(hex)
    return 0.2126 * r + 0.7152 * g + 0.0722 * bl
  end
  local la, lb = luminance(a), luminance(b)
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05)
end

-- OKLab (Björn Ottosson's): lightness, then the two color axes
local function oklab(hex)
  local r, g, b = linear(hex)
  local l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ^ (1 / 3)
  local m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ^ (1 / 3)
  local s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ^ (1 / 3)
  return 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
    1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
    0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
end

-- linear r, g, b of an OKLab color: a channel outside 0 to 1 is outside the sRGB gamut
local function oklab_linear(L, a, b)
  local l = (L + 0.3963377774 * a + 0.2158037573 * b) ^ 3
  local m = (L - 0.1055613458 * a - 0.0638541728 * b) ^ 3
  local s = (L - 0.0894841775 * a - 1.2914855480 * b) ^ 3
  return 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
    -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
    -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
end

local atan2 = math.atan2 or math.atan

local function hue(hex)
  local _, a, b = oklab(hex)
  return math.deg(atan2(b, a)) % 360
end

-- the most chroma sRGB allows at a lightness and hue
local function max_chroma(L, h)
  local ca, sa = math.cos(math.rad(h)), math.sin(math.rad(h))
  local lo, hi = 0, 0.4
  for _ = 1, 24 do
    local mid = (lo + hi) / 2
    local fits = true
    for _, v in ipairs({ oklab_linear(L, mid * ca, mid * sa) }) do
      fits = fits and v > -1e-4 and v < 1 + 1e-4
    end
    if fits then lo = mid else hi = mid end
  end
  return lo
end

local function oklch_hex(L, C, h)
  local out = '#'
  for _, v in ipairs({ oklab_linear(L, C * math.cos(math.rad(h)), C * math.sin(math.rad(h))) }) do
    v = math.min(1, math.max(0, v))
    v = v <= 0.0031308 and 12.92 * v or 1.055 * v ^ (1 / 2.4) - 0.055
    out = out .. ('%02x'):format(math.floor(v * 255 + 0.5))
  end
  return out
end

-- hex with its hue turned by dh degrees. Given the original's background and the new one, its
-- lightness is then moved until it reads against the new one as well as the original did against
-- its own: equal lightness isn't equal contrast, and blue and purple fall short of it
local function rotate(hex, dh, original_bg, bg)
  local L, a, b = oklab(hex)
  local h = hue(hex)
  local top = max_chroma(L, h)
  local used = top > 1e-4 and math.min(math.sqrt(a * a + b * b) / top, 1) or 0
  local turned = (h + dh) % 360
  local function at(l)
    return oklch_hex(l, used * max_chroma(l, turned), turned)
  end
  if not original_bg then
    return at(L)
  end
  local want, lo, hi = contrast(hex, original_bg), 0, 1
  for _ = 1, 20 do
    local mid = (lo + hi) / 2
    if contrast(at(mid), bg) < want then lo = mid else hi = mid end
  end
  return at(hi)
end

-- a theme's colors before theme() fills in the rest
local function derive(title, h, equal)
  local g, t = M.green, { title = title, light = false }
  local dh, original_bg = h - hue(g.normal), equal ~= 'lightness' and g.bg
  t.white, t.bright_white = g.white, g.bright_white
  for _, k in ipairs({ 'bg', 'dark' }) do
    t[k] = rotate(g[k], dh)
  end
  for _, k in ipairs({ 'fg', 'normal', 'bright', 'bold', 'selection', 'dim' }) do
    t[k] = rotate(g[k], dh, original_bg, t.bg)
  end
  -- Gr33N's black and gray lean teal, 35 degrees off its hue, where amber's don't lean at all:
  -- turned along with the rest they'd tint pink brown, so they take the theme's own hue
  t.black = rotate(g.black, h - hue(g.black))
  t.gray = rotate(g.gray, h - hue(g.gray), original_bg, t.bg)
  t.cursor = t.normal
  t.cursor_text = contrast(t.cursor, t.white) >= 3 and t.white or t.bg -- as amber: white on a light cursor is hard to read
  t.badge = t.dim
  t.selection_tint = mix(t.selection, t.bg, 0.12)
  t.border = mix(t.fg, t.bg, 0.15)
  t.float_border = mix(t.fg, t.dark, 0.15)
  t.prompt_band = mix(t.fg, t.bg, 0.25)
  t.bash_band = mix(t.white, t.bg, 0.16)
  t.ansi = {
    [0] = t.dark,
    t.normal, t.normal, t.normal, t.normal, t.normal, t.normal,
    t.fg, t.dim,
    t.bright, t.bright, t.bright, t.selection, t.bright, t.bright,
    t.bright_white,
  }
  return t
end

M.derive = {
  hue = hue,
  theme = theme,
  -- OKLCH: lightness, chroma, and hue in radians, 0 to 2 pi
  oklch = function(hex)
    local L, a, b = oklab(hex)
    return L, math.sqrt(a ^ 2 + b ^ 2), atan2(b, a) % (2 * math.pi)
  end,
  mono = function(title, h, equal)
    return theme(derive(title, h, equal))
  end,
  duo = function(title, h, accent_h, equal)
    local t, accent = derive(title, h, equal), derive(title, accent_h, equal)
    t.accent, t.accent_bright, t.accent_dim, t.accent_pale = accent.normal, accent.bright, accent.dim, accent.selection
    return theme(t)
  end,
  -- how far apart two colors look, whatever their lightness: 0.02 is about the least anyone sees
  distance = function(a, b)
    local l1, a1, b1 = oklab(a)
    local l2, a2, b2 = oklab(b)
    return math.sqrt((l1 - l2) ^ 2 + (a1 - a2) ^ 2 + (b1 - b2) ^ 2)
  end,
}

-- Chrome's inactive tab text: dim, pulled toward the background if it stands further from it than
-- this. Chrome's Flat theme marks the active tab with text alone, and black and white's dim, at
-- about 7.3, sat too close to their bright text. Every other theme's dim is already at 4.2 or under.
-- Light themes (black on white) get their own, lower limit: at 4.2 black's inactive tabs still read
-- too close to its active one while every dark theme looked fine. 2.0 was picked by eye from live
-- sliders on 2026-11-02, well under AA on purpose
--
-- Chrome's active tab text: bright, moved toward the theme's pale selection color if it doesn't have
-- this many times the inactive text's contrast. Red's bright, at 5.8, couldn't be told from its
-- inactive tabs, and dimming those any further would make them too hard to read
local TAB_TEXT_CONTRAST = 4.2
local TAB_TEXT_CONTRAST_LIGHT = 2.0
local TAB_ACTIVE_GAP = 3
for _, name in ipairs(M.order) do
  local t = M[name]
  local limit = t.light and TAB_TEXT_CONTRAST_LIGHT or TAB_TEXT_CONTRAST
  t.tab_dim = t.dim
  if contrast(t.dim, t.bg) > limit then
    local lo, hi = 0, 1
    for _ = 1, 30 do
      local p = (lo + hi) / 2
      if contrast(mix(t.dim, t.bg, p), t.bg) < limit then lo = p else hi = p end
    end
    t.tab_dim = mix(t.dim, t.bg, lo)
  end
  t.tab_bright = t.bright
  local want = TAB_ACTIVE_GAP * contrast(t.tab_dim, t.bg)
  if contrast(t.bright, t.bg) < want then
    local lo, hi = 0, 1
    for _ = 1, 30 do
      local p = (lo + hi) / 2
      if contrast(mix(t.selection, t.bright, p), t.bg) < want then lo = p else hi = p end
    end
    t.tab_bright = mix(t.selection, t.bright, hi)
  end
end

return M
