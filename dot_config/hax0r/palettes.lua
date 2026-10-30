-- The hax0r themes: one palette per theme, each color named for the job it does.
--
-- nvim's colors/hax0r.lua reads this file directly. Every other app's theme files are built
-- from it by generate.lua, so run `hax0r build` after changing a color here.
-- "X @ N%" means X composited over the background at N% (or over another color when named).
--
-- Rules every theme follows, chosen with Gr33N and carried over:
-- - git, diff, problem and link colors aren't set per theme: theme() below builds them from each
--   theme's own colors, the same way every time, so a theme stays one color
-- - ansi 7 is fg and ansi 8 is dim, so Claude Code's code text and comments match nvim's
-- - ansi 12 is the selection color, so Claude Code's inline code stands out from prose
--   (black on white uses ansi 4 for this, since Claude Code's light base reads that slot)

local M = {}

M.order = { 'green', 'red', 'blue', 'amber', 'white', 'black', 'pink', 'purple', 'electric', 'cyan-pink', 'pink-cyan' }

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
--                          read as gray over amber (VS Code's hovers, nvim's cursor line)
--
-- A dual theme also sets accent, accent_bright and accent_dim: a second hue. It takes the jobs one
-- hue can only do with brightness: removed is accent_dim and error accent_bright, links are accent,
-- and the removed bands are accent_dim @ 25% and 42%, nearly as strong as the added ones since
-- their hue sets them apart (accent_dim, because the paler shades are too gray to tint a band).
local function theme(t)
  t.faint = mix(t.white, t.bg, 0.40)
  t.added = t.bright
  t.added_dim = t.dim
  t.removed = t.dim
  t.removed_dim = t.faint
  t.ignored = mix(t.fg, t.bg, 0.60)
  t.warning = mix(t.white, t.bright, 0.5)
  t.error = t.bright_white
  t.diff_add = mix(t.bright, t.bg, 0.20)
  t.diff_add_word = mix(t.bright, t.bg, 0.33)
  local removed_tint = mix(t.white, t.dim, 0.5)
  t.diff_del = mix(removed_tint, t.bg, 0.08)
  t.diff_del_word = mix(removed_tint, t.bg, 0.20)
  t.link = mix(t.selection, t.fg, 0.5)
  t.cursor_line = mix(t.bright, t.bg, 0.30)
  if t.accent then
    t.removed = t.accent_dim
    t.removed_dim = mix(t.accent_dim, t.bg, 0.60)
    t.error = t.accent_bright
    t.diff_del = mix(t.accent_dim, t.bg, 0.25)
    t.diff_del_word = mix(t.accent_dim, t.bg, 0.42)
    t.link = t.accent
  end
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
  bg = '#200101',
  fg = '#d81010',             -- not R3D's #b10e0e, which read at 2.76:1: lifted halfway to bright
  dark = '#1f0000',
  normal = '#d81010',         -- not R3D's ansi 1 #b00d0d: lifted with fg (R3D's fg and ansi 1 match)
  bright = '#ff1111',         -- ansi 9 (10-14 are #ff1010)
  bold = '#ff0000',
  white = '#fafafa',
  bright_white = '#fefefe',
  black = '#150000',
  cursor = '#b00d0d',
  cursor_text = '#ffffff',
  selection = '#ffc1c1',      -- not R3D's lavender #ebc1ff: red as pale as Gr33N's mint
  dim = '#b00d0d',            -- not badge #ff2600 @ 50% (#901400, 2.14:1): R3D's ansi 1, lifted with fg
  badge = '#b00d0d',          -- dim, like the other themes
  gray = '#554040',           -- ansi 8 in ghostty's port
  -- Added
  selection_tint = '#3b1818', -- selection @ 12%
  border = '#3c0303',         -- fg @ 15%
  float_border = '#3b0202',   -- fg @ 15% over dark
  prompt_band = '#4e0505',    -- fg @ 25%
  bash_band = '#432929',      -- white @ 16%
  ansi = {
    [0] = '#1f0000',
    '#d81010', '#d81010', '#d81010', '#d81010', '#d81010', '#d81010', -- lifted from #b00d0d with normal
    '#d81010', -- 7: fg
    '#b00d0d', -- 8: dim
    '#ff1111', '#ff1010', '#ff1010',
    '#ffc1c1', -- 12: selection
    '#ff1010', '#ff1010',
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

-- Deriving a theme in another hue: Gr33N's colors turned to a new OKLCH hue. Each keeps its
-- lightness and how much of the chroma sRGB allows at its hue, so every hue gets Gr33N's levels
-- and none comes out darker or duller by accident. The rest is filled in the way the hand-set
-- themes do it.
--   mono(title, hue)               one hue
--   duo(title, hue, accent_hue)    a second hue for removed, errors and links (see theme())
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

return M
