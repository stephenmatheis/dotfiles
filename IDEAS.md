# Ideas

Plans and ideas for these dotfiles, mostly the hax0r themes. Started 2026-10-30. Items marked *unverified* are from memory or a guess and need checking on a machine before anyone builds on them.

## Next up (handoff, written 2026-10-30)

Written on one machine for the other: memory is per machine, so a fresh session there won't know any of this. Read this file and the README first.

- **Where things stand:** the five new themes (`pink`, `purple`, `electric`, `cyan-pink`, `pink-cyan`) are built, applied on the first machine and pushed. `hax0r pink-cyan` was tried in VS Code and Claude Code in Ghostty and looks good. In the dual themes the second hue only takes removed lines, errors, links and VS Code's submodule color, so they read as pink or cyan with a few accents. The rename is on hold.
- **Staged for review:** `page.lua` has a section, "The second hue in more places", with mock-ups for the two dual themes only. Nothing in the apps uses any of it yet. To see it, after `chezmoi update`:

  ```zsh
  nvim -l ~/.config/hax0r/page.lua page.html && open page.html
  ```

- **Decisions to make from that section:**
  1. ~~Claude Code's shimmer in the second hue.~~ Dropped for now (2026-10-30), see Animations.
  2. Starship: Now, Prompt only, Prompt and time, or Git in the second hue. My recommendation is a new palette slot (see Dual themes) over remapping ANSI colors.
  3. git's red as the second hue: yes or no. It's an ANSI remap, so it reaches every terminal tool.
- **Then build whatever is chosen:** any new palette slot in `generate.lua` (the Ghostty themes and `terminal-palette.zsh` both set slots), `starship.toml` to use the slot, then `hax0r build`, `chezmoi re-add`, and commit with the `palettes.lua` or template change that caused it (README, "Working on this repo").


## Decided

- **Name:** `phosphor` was the pick to replace `hax0r` (typed as plain letters, and `palettes.lua` already calls amber "phosphor"), but **on hold: still thinking (2026-10-30), so everything is still `hax0r`.** The notes below are for when it happens. Rename before generating more themes, as its own commit. The "HaX0R Gr33N / R3D / BLUE" titles stay: they're credited to the original iTerm themes.
  - The rename touches about 190 mentions in 20 tracked files, plus the generated files: every generated file name, VS Code theme and icon ids, `colors/hax0r.lua`, Ghostty and tmux theme files, `~/.config/hax0r`, and the `hax0r` script.
  - Per-machine state needs a one-time migration on each machine: `~/.local/state/hax0r`, `~/.claude/themes/hax0r.json` and `custom:hax0r` in `~/.claude/settings.json`, and VS Code's `workbench.colorTheme` / `workbench.iconTheme`. Retire old paths with `.chezmoiremove`, as before.
  - Two things outside the repo also point at the old name: the `~/.zshrc` line that sources `vscode/hax0r-theme/terminal-palette.zsh`, and VS Code's extension registry (`~/.vscode/extensions/extensions.json`, id `stephenmatheis.hax0r-theme`, location `~/.config/vscode/hax0r-theme`). Option: keep that one folder and id, which is never typed, so neither needs a manual edit.
  - Not `glow` (it's a popular Charm CLI). Other options considered: `crt` (short), `neon` (doesn't fit amber, white or black).
- **Dual themes may break "a theme stays one color".** The second hue takes the jobs brightness handles worst: removed lines, errors and links.
- **Preview first:** add options to `page.lua` and look before editing `palettes.lua`.
- **Picked (2026-10-30), all matched to Gr33N's contrast** (the other way, matching only its lightness, was more vivid but dimmer to read and had more colors that clash, so it was dropped): `pink` (OKLCH hue 355), `purple` (300), `electric` (electric blue, 258; `blue` is taken), and the dual themes `cyan-pink` (cyan 195 with pink as the second color) and `pink-cyan` (the reverse). Purple + amber, green + amber and blue + orange weren't picked yet.
- **Frozen as plain hex** in `palettes.lua`, like the hand-set themes. The derive helpers stay in the same file as a tool for making more.

## New monochrome themes

Neon pink, electric blue and purple.

- Purple and electric blue are dark at full saturation, so they have to be lifted to match Gr33N's readability (red was lifted the same way).
- The existing blue (`#11b7ff`) is a sky blue, so a new blue needs a distinct hue.
- Approach: an OKLCH helper in `palettes.lua` that builds a whole theme from a hue by rotating Gr33N's colors (same lightness and relative saturation per role). Check it by regenerating Gr33N from itself, which should give the same colors, and amber, which was matched by hand.
- Starting hues in OKLCH degrees (*unverified*, judge on the page): pink 325 to 355, purple 290 to 310, electric blue 250 to 266, existing blue about 235.
- Show contrast ratios on the page, so nothing falls short the way red did (2.76:1).

## Dual themes

Two hues that go together, with equal OKLCH lightness so neither dominates. The accent takes removed, error and link; the primary keeps everything else.

- cyan + pink (the cyberpunk one; the accent is the warm color so errors read as errors)
- purple + amber
- green + amber (colors that already exist, a two-tone phosphor look)
- blue + orange (teal and orange)

Later: let syntax colors (strings, types) use the accent. Mock-ups of three more uses are on the page (see Next up): Claude Code's shimmer, Starship, and git's red.

- **Starship:** it names ANSI colors, which are all the theme's one color. Two ways to give it the second hue. A new palette slot like 196 (the error slot), set by each Ghostty theme and by VS Code's `terminal-palette.zsh`: the second hue in a dual theme and the normal color in the rest, so nothing else changes (the safer one). Or remap ANSI colors, which changes every terminal tool.
- **git's red:** git (and ripgrep, `ls`) color removed lines, unstaged changes and untracked files with ANSI red, and added and staged with green, and every theme makes both the one color. Giving ANSI red the second hue fixes that, but it's the remap, so it may also change Claude Code's code blocks. Undecided.

## Animations

- **Claude Code shimmer:** dropped for now (2026-10-30); `claudeShimmer` stays as it is. A theme only sets the color, and Claude Code decides when it animates. Read from 2.1.314's minified code: the spinner sweeps a 3-character band of plain shimmer color while requesting and responding, and the whole message pulses on a 2-second cycle during tool use, blending only colors it can parse as `rgb(r,g,b)` (our theme files use hex). Hooks use `claudeBlueShimmer_FOR_SYSTEM_SPINNER`, and typing `ultrathink` uses the `rainbow_*_shimmer` keys. No use found for `promptBorderShimmer`, `permissionShimmer`, `inactiveShimmer`, `warningShimmer` or `fastModeShimmer`, so the border and permission rows on the page probably show animations that never happen. If this comes back, the hook spinner is the best place for the second hue: it's rare and means hooks, not Claude. The second hue on the main spinner would be loud and would blur the stall signal.
- **neoclear** (https://codeberg.org/ftranschel/neoclear/): a `clear` replacement that pours braille glyph streams down the screen, cmatrix-style. Rust, standard library only (a little libc), GPL-3.0 or later. Options for direction (`-d`), duration (`-t`) and color (`-c`), speed, trail length and glitch rate; defaults go in `~/.config/neoclear/config.toml` via `--write-config`. Prints a plain clear when output isn't a terminal.
  - **Linux only upstream:** `src/main.rs` has a `compile_error!` for anything else, and `src/term.rs` uses Linux values. Read on 2026-10-30, it has no dependencies or build script, and it only prints escape codes and reads its config. The patch is small: allow macOS in the `compile_error!` check, use `TIOCGWINSZ` 0x40087468 on macOS, set `LFLAG_OFFSET` to 24 on macOS, clear `ICANON` along with `ECHO` so Ghostty doesn't show its password-prompt lock cursor, and add `--hold-sync` so the prompt closes the final synchronized update and appears in the same frame as the clear. It lives uncommitted in `~/.local/src/neoclear` on `steve-mbp-16-m2-max`, built and installed to `~/.local/bin` there and passing checks in a simulated terminal. The other Mac still needs it (README, new-machine checklist). Don't copy its source into this repo (the license).
  - Wrapper: `hax0r clear` passes the current theme's foreground as `--color` and falls back to plain `clear` without neoclear. Fades go to black, not the theme's background, and the head glyph tints toward white, so check `black` (white background) by eye.
  - The alias (`alias clear="hax0r clear --hold-sync"`) and the `PROMPT+=` line that closes the update are in `~/.zshrc`, which isn't tracked, so they're on the README's new-machine checklist. `~/.config/neoclear/config.toml` sets `fade_ms = 0`.
- **Theme-switch fade:** `hax0r <theme>` fades the terminal from the old colors to the new with OSC 10/11 escape codes. It only fades the terminal that ran it; the others get the normal reload.
- **Ghostty shader:** `custom-shader` and `custom-shader-animation` for CRT scanlines, glow and flicker, tinted per theme. Costs some GPU and battery. *Unverified* for Ghostty 1.4.0: check `ghostty +show-config --docs`.
- **nvim:** a cursor-smear plugin would work (`vim.pack` is already in use). Low priority.

## Where else to apply the theme

Tools that use the ANSI palette already follow Ghostty. The ones that need hex colors:

- `fzf` (installed): `FZF_DEFAULT_OPTS --color`, which needs a state file the shell reads
- Xcode: an `.xccolortheme` in `~/Library/Developer/Xcode/UserData/FontAndColorThemes` (*unverified* path)
- Chrome, Slack and Raycast: theme files or pasteable theme strings
- `bat` and `delta` if installed (not yet; `delta` would help with diffs), also `eza`, `btop`, `lazygit`

## macOS

Checked on one machine on 2026-10-30: macOS 27.0.1, light mode, default accent (no appearance keys set). Confirm each option on the machine before wiring it in.

- **Official and scriptable:** Light/Dark through System Events AppleScript, and a generated solid wallpaper in the theme's background color.
- **Official, in System Settings:** accent color (a fixed set, so the nearest match) and highlight color (custom). Accessibility ▸ Display ▸ Color Filters has a color tint, which gives a full-screen phosphor effect.
- **Second, not a documented API:** writing `AppleAccentColor` and `AppleHighlightColor` with `defaults write -g`, which is what the UI writes.
- A dark theme flips macOS to dark, so make it opt-in per machine.

## Other ideas

- Switch themes by time of day (light by day, a dark one at night), paired with macOS's automatic appearance.
- A theme per repo or tmux session, such as red for production.
- Have `page.lua` flag low-contrast colors automatically.

## Order of work

1. ~~Prototype the monochrome themes and dual pairings in `page.lua`.~~ Done.
2. ~~Pick the finalists and add them to `palettes.lua`.~~ Done for pink, purple, electric, cyan-pink and pink-cyan. The rename to `phosphor` is on hold (see Decided).
3. Dual-theme roles in the apps: syntax colors and Starship (so far only removed, errors and links use the second hue).
4. macOS appearance, then the switch fade, then a shader. ~~neoclear~~ is done on one machine.
5. More apps: `fzf`, then Xcode.
