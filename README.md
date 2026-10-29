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
