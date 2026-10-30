# dotfiles

Managed with [chezmoi](https://www.chezmoi.io). Shell config (`~/.zshenv`, `~/.zshrc`) is **not** tracked: it differs per machine.

## New machine checklist

- Add `~/.local/bin` to PATH in `~/.zshenv`, or `hax0r` (installed to `~/.local/bin/hax0r`) won't be found:

  ```zsh
  export PATH="$HOME/.local/bin:$PATH"
  ```

- To get hax0r colors in VS Code's terminal, add this to `~/.zshrc`:

  ```zsh
  [[ $TERM_PROGRAM == vscode && -r ~/.config/vscode/hax0r-theme/terminal-palette.zsh ]] && . ~/.config/vscode/hax0r-theme/terminal-palette.zsh
  ```

- `hax0r` needs `jq`, `nvim` and `tmux` (all via Homebrew). Then run `hax0r <theme>` once to create `~/.local/state/hax0r`.

- For the Claude Code status line (session, context, cost and plan limits), add this to `~/.claude/settings.json`, which isn't tracked. It also needs `jq`:

  ```json
  "statusLine": { "type": "command", "command": "~/.local/bin/claude-statusline", "refreshInterval": 60 }
  ```

- For the animated `clear`, build [neoclear](https://codeberg.org/ftranschel/neoclear/). It's Linux only upstream and GPL, so its source isn't kept here, and it needs these edits to work on a Mac:

  ```zsh
  git clone https://codeberg.org/ftranschel/neoclear.git ~/.local/src/neoclear
  ```

  - `src/main.rs`: change the `compile_error!`'s condition to `not(any(target_os = "linux", target_os = "macos"))`.
  - `src/term.rs`: add `target_os = "macos"` to both `target_arch` lists around `TIOCGWINSZ`, so macOS gets `0x4008_7468`.
  - `src/term.rs`: make `LFLAG_OFFSET` 24 on macOS. It stays 12 elsewhere.
  - `src/term.rs`: in `disable_echo`, clear `ICANON` along with `ECHO` (`0x100` on macOS, `0x2` on Linux). Otherwise Ghostty takes it for a password prompt and shows its lock cursor during the animation.
  - `src/config.rs` and `src/main.rs`: add a `--hold-sync` flag (a `hold_sync` bool, default false) that leaves `\x1b[?2026l` off the end of the final clear in `run`. The prompt closes it instead, so the clear and the prompt appear in one frame rather than the prompt blipping in.

  ```zsh
  cd ~/.local/src/neoclear && cargo build --release && cp target/release/neoclear ~/.local/bin/
  ```

  Then add these to `~/.zshrc`, the second one after `eval "$(starship init zsh)"`. Without neoclear, `hax0r clear` does a plain `clear`, but a neoclear without the edits above rejects `--hold-sync`:

  ```zsh
  alias clear="hax0r clear --hold-sync"
  PROMPT+=$'%{\e[?2026l%}'
  ```

## How the hax0r theme works

- **One source:** `~/.config/hax0r/palettes.lua`. Each theme lists its base colors, and `theme()` at the top derives the git, diff, warning, error, faint and link colors from them, the same way for every theme. The rules are written there, so change them there.
- **Building:** `hax0r build` regenerates each app's theme files from `palettes.lua`, and `hax0r <theme>` switches the apps over. nvim needs no build: `colors/hax0r.lua` reads `palettes.lua` directly. Every generated file says so at the top: edit `palettes.lua` or a template, not the generated file.
- **Comparing colors:** `nvim -l ~/.config/hax0r/page.lua page.html` writes a web page that draws the themes from `palettes.lua` in exact colors: each app's diffs now and the other options considered, plus where white and black can't tell git and problem colors apart. To weigh a change, add an option to the page and look before editing `palettes.lua`.
- **What each app lets a theme set:**
  - VS Code and nvim: named colors for nearly everything. VS Code's come from `vscode/hax0r-theme/themes/color-theme.template.jsonc`.
  - Ghostty: the 16 ANSI colors, plus palette slots 22/28/52/88 (Claude Code's diff bands) and 196 (Starship's error prompt). VS Code's terminal sets those slots with escape codes (`terminal-palette.zsh`).
  - Claude Code: named keys, listed in `hax0r/generate.lua`. Its diff keys are backgrounds only. For example, its `subtle` key colors the `· summary` tag.
- **What the apps decide themselves:** Claude Code draws the text of removed diff lines dim. Ghostty blends dim text toward the background, and its `faint-opacity` setting defaults to 0.5. We don't set it.

## Working on this repo

- **Source and live copies:** `dot_config/` here becomes `~/.config` and `private_dot_local/bin/` becomes `~/.local/bin`. The `hax0r` scripts read and write the live copies, so a change made here has to reach them (`chezmoi apply`) before `hax0r build` can see it. Run `chezmoi diff` first if the live files might have changed, since apply overwrites them.
- **After `hax0r build`:** it writes the generated files into `~/.config`, not into this repo. Run `chezmoi re-add` to bring them back, then commit them together with the `palettes.lua` or template change that caused them.
- **Generated files:** the per-theme files for Ghostty, tmux, Claude Code and VS Code, plus `hax0r/themes`, `vscode/hax0r-theme/package.json` and `vscode/hax0r-theme/terminal-palette.zsh`. Edit `palettes.lua` or a template instead.
- **Checking a change:** `hax0r build` only writes files whose contents changed, so a second run should print nothing. `hax0r preview` shows every theme in the terminal, and `page.lua` (above) shows exact colors in a browser.
- **Not tracked, per machine:** the current theme (`~/.local/state/hax0r`), `~/.claude/themes/hax0r.json`, `~/.claude/settings.json` and the shell config.
- **Commits:** one change per commit, with a one-line subject in lowercase after a `feat:`, `fix:`, `chore:` or `docs:` prefix.
- **Ideas and plans:** `IDEAS.md` lists what's decided, what's next and what's still unverified. Like this README, `.chezmoiignore` keeps it out of `~`.
