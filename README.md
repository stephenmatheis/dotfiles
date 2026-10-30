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

## How the hax0r theme works

- **One source:** `~/.config/hax0r/palettes.lua`. Each theme lists its base colors, and `theme()` at the top derives the git, diff, warning, error and faint colors from them, the same way for every theme. The rules are written there, so change them there.
- **Building:** `hax0r build` regenerates each app's theme files from `palettes.lua`, and `hax0r <theme>` switches the apps over. nvim needs no build: `colors/hax0r.lua` reads `palettes.lua` directly. Every generated file says so at the top: edit `palettes.lua` or a template, not the generated file.
- **What each app lets a theme set:**
  - VS Code and nvim: named colors for nearly everything. VS Code's come from `vscode/hax0r-theme/themes/color-theme.template.jsonc`.
  - Ghostty: the 16 ANSI colors, plus palette slots 22/28/52/88 (Claude Code's diff bands) and 196 (Starship's error prompt). VS Code's terminal sets those slots with escape codes (`terminal-palette.zsh`).
  - Claude Code: named keys, listed in `hax0r/generate.lua`. Its diff keys are backgrounds only. For example, its `subtle` key colors the `· summary` tag.
- **What the apps decide themselves:** Claude Code draws the text of removed diff lines dim. Ghostty blends dim text toward the background, and its `faint-opacity` setting defaults to 0.5. We don't set it.
