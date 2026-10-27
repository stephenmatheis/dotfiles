# hax0r for VS Code's terminal. Sourced from ~/.zshrc when TERM_PROGRAM is vscode.
#
# Claude Code draws diff backgrounds with 256-color slots 22/28/52/88, and Ghostty's config
# redefines them as the theme's diff colors. A VS Code color theme can only set colors 0-15,
# so redefine these four here with OSC 4, which VS Code's terminal (xterm.js) supports.
# nvim's terminal needs nothing: it passes these slots through to Ghostty.
# Done at every prompt, because a VS Code theme change or window reload resets them.
_hax0r_palette() {
    printf '\e]4;22;#003300\a\e]4;28;#004c00\a\e]4;52;#5f0000\a\e]4;88;#870000\a'
}
precmd_functions+=(_hax0r_palette)
