-- The hax0r themes: one palette per theme, each color named for the job it does.
--
-- nvim's colors/hax0r.lua reads this file directly. Every other app's theme files are built
-- from it by generate.lua, so run `hax0r build` after changing a color here.
-- "X @ N%" means X composited over the background at N% (or over another color when named).
--
-- Rules every theme follows, chosen with Gr33N and carried over:
-- - diffs and git signs stay green and red in every theme, since that's where color carries meaning
-- - when error or warning would be the theme's own text color, it turns white
-- - ansi 7 is fg and ansi 8 is dim, so Claude Code's code text and comments match nvim's
-- - ansi 12 is the selection color, so Claude Code's inline code stands out from prose
--   (black on white uses ansi 4 for this, since Claude Code's light base reads that slot)

local M = {}

M.order = { 'green', 'red', 'blue', 'amber', 'white', 'black' }

-- Diff and git colors shared by the dark themes (Ghostty palette slots 22/28/52/88)
local dark_diffs = {
  added = '#19e20e',         -- Gr33N's bright green
  added_dim = '#0b8700',     -- staged: Gr33N's dim green
  removed = '#ff1111',       -- HaX0R R3D ansi 9
  removed_dim = '#b00d0d',   -- staged: HaX0R R3D ansi 1
  diff_add = '#003300',      -- added line, as bright as diff_del
  diff_add_word = '#004c00', -- added word, as bright as diff_del_word
  diff_del = '#5f0000',      -- removed line, xterm's 52
  diff_del_word = '#870000', -- removed word, xterm's 88
}

local function theme(t)
  for k, v in pairs(t.diffs or {}) do
    t[k] = t[k] or v
  end
  t.diffs = nil
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
  link = '#00e8ca',           -- link
  -- HaX0R Gr33N, derived from iTerm-only colors
  dim = '#0b8700',            -- badge #14ff00 @ 50%: comments, line numbers
  badge = '#14ff0080',        -- badge itself, for VS Code's count badges
  cursor_line = '#2e4640',    -- cursor guide #b3ecff @ 25%
  gray = '#334843',           -- ansi 8 in ghostty's port: Claude Code's empty rate-limit bar
  -- Added: no hax0r theme has these
  error = '#ff1111',          -- HaX0R R3D ansi 9
  warning = '#ffb000',        -- amber phosphor, green screen's monochrome sibling
  faint = '#496767',          -- cursor guide @ 40%: Claude Code's faint text, staged changes
  selection_tint = '#1b2c18', -- selection @ 12%: selections everywhere, text keeps its color
  border = '#052703',         -- fg @ 15%: VS Code's panel outline, used for every border
  float_border = '#03350b',   -- fg @ 15% over dark
  prompt_band = '#073804',    -- fg @ 25%: Claude Code's prompts
  bash_band = '#2a3529',      -- white @ 16%: Claude Code's ! commands
  diffs = dark_diffs,
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
  selection = '#ebc1ff',
  link = '#b700e8',
  dim = '#b00d0d',            -- not badge #ff2600 @ 50% (#901400, 2.14:1): R3D's ansi 1, lifted with fg
  badge = '#b00d0d',          -- dim, like the other themes
  cursor_line = '#453c40',    -- cursor guide #b3ecff @ 25%
  gray = '#554040',           -- ansi 8 in ghostty's port
  -- Added
  error = '#fefefe',          -- not red: red is the text color, so errors turn white
  warning = '#ffb000',
  faint = '#5b5f67',          -- cursor guide @ 40%
  selection_tint = '#38181f', -- selection @ 12%
  border = '#3c0303',         -- fg @ 15%
  float_border = '#3b0202',   -- fg @ 15% over dark
  prompt_band = '#4e0505',    -- fg @ 25%
  bash_band = '#432929',      -- white @ 16%
  diffs = dark_diffs,
  ansi = {
    [0] = '#1f0000',
    '#d81010', '#d81010', '#d81010', '#d81010', '#d81010', '#d81010', -- lifted from #b00d0d with normal
    '#d81010', -- 7: fg
    '#b00d0d', -- 8: dim
    '#ff1111', '#ff1010', '#ff1010',
    '#ebc1ff', -- 12: selection
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
  link = '#e8008f',
  dim = '#0b79ad',            -- not badge @ 50%: BLUE's badge is red-orange #ff2600, so fg @ 65%, as readable as Gr33N's
  badge = '#0b79ad',          -- dim, like the other themes
  cursor_line = '#2e3f50',    -- cursor guide #b3ecff @ 25%
  gray = '#484157',           -- ansi 8 in ghostty's port
  -- Added
  error = '#ff1111',          -- HaX0R R3D ansi 9, like Gr33N
  warning = '#ffb000',
  faint = '#486173',          -- cursor guide @ 40%
  selection_tint = '#182031', -- selection @ 12%
  border = '#032038',         -- fg @ 15%
  float_border = '#032342',   -- fg @ 15% over dark
  prompt_band = '#053250',    -- fg @ 25%
  bash_band = '#292c3a',      -- white @ 16%
  diffs = dark_diffs,
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
  link = '#00e8ca',           -- Gr33N's cyan
  dim = '#9c6a00',
  badge = '#9c6a00',
  cursor_line = '#3c4240',    -- cursor guide #b3ecff @ 25%
  gray = '#4c4230',           -- as faint as Gr33N's, tinted 30% amber
  error = '#ff1111',
  warning = '#fefefe',        -- not amber: amber is the text color, so warnings turn white
  faint = '#546466',          -- cursor guide @ 40%
  selection_tint = '#302517', -- selection @ 12%
  border = '#301e00',         -- fg @ 15%
  float_border = '#3f2900',   -- fg @ 15% over dark
  prompt_band = '#422a00',    -- fg @ 25%
  bash_band = '#393028',      -- white @ 16%
  diffs = dark_diffs,
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
  link = '#00e8ca',           -- Gr33N's cyan
  dim = '#999999',
  badge = '#999999',
  cursor_line = '#2e2e2e',    -- white @ 18%: a cyan cursor guide looked out of place in gray
  gray = '#3f3f3f',           -- as faint as Gr33N's
  error = '#ff1111',
  warning = '#ffb000',
  faint = '#5c5c5c',          -- white @ 36%, as faint as Gr33N's
  selection_tint = '#1f1f1f', -- selection @ 12%
  border = '#1e1e1e',         -- fg @ 15%
  float_border = '#343434',   -- fg @ 15% over dark
  prompt_band = '#323232',    -- fg @ 25%
  bash_band = '#282828',      -- white @ 16%
  diffs = dark_diffs,
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
  link = '#00796b',           -- Gr33N's cyan darkened to read on white
  dim = '#565656',
  badge = '#565656',
  cursor_line = '#ededed',    -- black @ 7%
  gray = '#b7b7b7',           -- as faint as Gr33N's
  error = '#b00d0d',          -- HaX0R R3D ansi 1, reads on white
  warning = '#8a5f00',        -- amber darkened to read on white
  faint = '#8c8c8c',          -- black @ 45%
  selection_tint = '#e6e6e6', -- black @ 10%
  border = '#e0e0e0',         -- fg @ 15%
  float_border = '#cfcfcf',   -- fg @ 15% over dark
  prompt_band = '#cccccc',    -- fg @ 25%
  bash_band = '#e6e6e6',      -- black @ 10%
  added = '#098204',          -- Gr33N's bright green darkened to read on white
  added_dim = '#13be0a',
  removed = '#b00d0d',
  removed_dim = '#d88686',
  diff_add = '#d4f5d0',
  diff_add_word = '#a9e5a1',
  diff_del = '#ffd6d6',
  diff_del_word = '#ffadad',
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

return M
