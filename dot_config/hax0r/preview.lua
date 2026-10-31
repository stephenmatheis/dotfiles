-- `hax0r preview`: every theme side by side, drawn from palettes.lua in exact colors. Each panel
-- shows nvim code, a statusline and float, a Claude Code prompt, ! command and reply, and a diff.
local config = vim.env.XDG_CONFIG_HOME or (vim.env.HOME .. '/.config')
local P = dofile(config .. '/hax0r/palettes.lua')
local W = 62

local function rgb(h)
  return tonumber(h:sub(2, 3), 16), tonumber(h:sub(4, 5), 16), tonumber(h:sub(6, 7), 16)
end

local function luminance(h)
  local sum, weights = 0, { 0.2126, 0.7152, 0.0722 }
  for i, v in ipairs({ rgb(h) }) do
    v = v / 255
    sum = sum + weights[i] * (v <= 0.04045 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4)
  end
  return sum
end

local function contrast(a, b)
  local la, lb = luminance(a), luminance(b)
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05)
end

local ATTRS = { b = '\27[1m', i = '\27[3m', u = '\27[4m' }

-- parts: { text, color role or hex, attrs, background }; the row is padded to W on `back`
local function row(c, parts, back)
  back = back or c.bg
  local out, n = {}, 0
  for _, p in ipairs(parts) do
    local text, color, attrs, bg = p[1], c[p[2]] or p[2], p[3] or '', p[4] or back
    local codes = ('\27[48;2;%d;%d;%dm'):format(rgb(bg)) .. ('\27[38;2;%d;%d;%dm'):format(rgb(color))
    for a in attrs:gmatch('.') do
      codes = codes .. ATTRS[a]
    end
    table.insert(out, codes .. text .. '\27[0m')
    n = n + vim.fn.strdisplaywidth(text)
  end
  return table.concat(out) .. ('\27[48;2;%d;%d;%dm'):format(rgb(back)) .. (' '):rep(W - n) .. '\27[0m'
end

local function panel(name, c)
  local cl = c.cursor_line
  local nr = function(n) return { ('%3d '):format(n), 'dim' } end
  local ratio = function(k) return ('%.1f'):format(contrast(c[k], c.bg)) end
  return {
    row(c, { { ' ' .. name, 'bright', 'b' }, { '  ' .. c.title, 'fg' }, { ('  %s on %s'):format(c.fg, c.bg), 'dim' } }),
    row(c, {}),
    row(c, { nr(1), { '-- palette for the hax0r theme', 'comment', 'i' } }),
    row(c, { nr(2), { 'local function', 'bold', 'b' }, { ' ', 'fg' }, { 'hl', 'normal' }, { '(group, opts)', 'fg' } }),
    row(c, { { '  3 ', 'bright', '', cl }, { '  ', 'fg', '', cl }, { 'return', 'bold', 'b', cl }, { ' set(', 'fg', '', cl },
      { "'Normal'", 'normal', '', cl }, { ', ', 'fg', '', cl }, { 'Color', 'bright', '', cl }, { ')', 'fg', '', cl } }, cl),
    row(c, { nr(4), { '  ', 'fg' }, { 'vim.o.background', 'fg', '', c.selection_tint }, { ' = ', 'fg' }, { "'dark'", 'normal' },
      { '  E error', 'error' }, { '  W warn', 'warning' } }),
    row(c, { { ' NORMAL ', 'bright', 'b', c.dark }, { ' hax0r.lua ', 'fg', '', c.dark }, { '  [+]', 'dim', '', c.dark },
      { '  +3', 'added', '', c.dark }, { ' ~1', 'white', '', c.dark }, { ' -2', 'removed', '', c.dark } }, c.dark),
    row(c, { { '╭' .. ('─'):rep(26) .. '╮', 'float_border', '', c.dark }, { ' float', 'fg', '', c.dark } }, c.dark),
    row(c, {}),
    row(c, { { ' ❯ ', 'fg', '', c.prompt_band }, { 'make the selection softer', 'fg', '', c.prompt_band } }, c.prompt_band),
    row(c, {}),
    row(c, { { ' ! ', 'white', '', c.bash_band }, { 'git status', 'fg', '', c.bash_band } }, c.bash_band),
    row(c, {}),
    row(c, { { ' ● ', 'bright' }, { 'Set ', 'fg' }, { 'selection_tint', 'selection' }, { ' and ', 'fg' },
      { 'the docs', 'link', 'u' }, { ' (2 lines hidden)', 'faint' } }),
    row(c, { { '   ✻ Thinking… ', 'bright' }, { 'esc to interrupt', 'dim' } }),
    row(c, { { '  3 ', 'dim', '', c.diff_del }, { "-  fg = '", 'fg', '', c.diff_del }, { '#16b10e', 'normal', '', c.diff_del_word },
      { "',", 'fg', '', c.diff_del }, { ' -- old green', 'comment', 'i', c.diff_del } }, c.diff_del),
    row(c, { { '  3 ', 'dim', '', c.diff_add }, { "+  fg = '", 'fg', '', c.diff_add }, { '#19e20e', 'normal', '', c.diff_add_word },
      { "',", 'fg', '', c.diff_add }, { ' -- brighter', 'comment', 'i', c.diff_add } }, c.diff_add),
    row(c, {}),
    row(c, { { (' contrast: text %s  comments %s  bright %s  error %s'):format(ratio('fg'), ratio('comment'), ratio('bright'), ratio('error')), 'dim' } }),
  }
end

local columns = tonumber(vim.env.HAX0R_COLUMNS) or 126
local per_row = math.max(1, math.floor((columns + 2) / (W + 2)))
local panels = {}
for _, name in ipairs(P.order) do
  table.insert(panels, panel(name, P[name]))
end
for first = 1, #panels, per_row do
  for line = 1, #panels[first] do
    local parts = {}
    for i = first, math.min(first + per_row - 1, #panels) do
      table.insert(parts, panels[i][line])
    end
    io.write(table.concat(parts, '  '), '\n')
  end
  io.write('\n')
end
