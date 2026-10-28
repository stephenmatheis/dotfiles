# hax0r for VS Code's terminal. Sourced from ~/.zshrc when TERM_PROGRAM is vscode.
# Built by `hax0r build` from ~/.config/hax0r/palettes.lua: edit that, not this file.
#
# Claude Code draws diff backgrounds with 256-color slots 22/28/52/88, and Starship draws a failed
# command's prompt in slot 196. Each Ghostty theme sets those slots, but a VS Code color theme can
# only set colors 0-15, so set them here with OSC 4, which VS Code's terminal (xterm.js) supports.
# nvim's terminal needs nothing: it passes these slots through to Ghostty.
# Done at every prompt, because a VS Code theme change or window reload resets them, and so
# `hax0r <theme>` reaches terminals that are already open.
_hax0r_palette() {
    local theme
    read -r theme < ${XDG_STATE_HOME:-$HOME/.local/state}/hax0r/theme 2>/dev/null
    case $theme in
        red) printf '\e]4;22;#003300\a\e]4;28;#004c00\a\e]4;52;#5f0000\a\e]4;88;#870000\a\e]4;196;#fefefe\a' ;;
        blue) printf '\e]4;22;#003300\a\e]4;28;#004c00\a\e]4;52;#5f0000\a\e]4;88;#870000\a\e]4;196;#ff1111\a' ;;
        amber) printf '\e]4;22;#003300\a\e]4;28;#004c00\a\e]4;52;#5f0000\a\e]4;88;#870000\a\e]4;196;#ff1111\a' ;;
        white) printf '\e]4;22;#003300\a\e]4;28;#004c00\a\e]4;52;#5f0000\a\e]4;88;#870000\a\e]4;196;#ff1111\a' ;;
        black) printf '\e]4;22;#d4f5d0\a\e]4;28;#a9e5a1\a\e]4;52;#ffd6d6\a\e]4;88;#ffadad\a\e]4;196;#b00d0d\a' ;;
        *) printf '\e]4;22;#003300\a\e]4;28;#004c00\a\e]4;52;#5f0000\a\e]4;88;#870000\a\e]4;196;#ff1111\a' ;;
    esac
}
precmd_functions+=(_hax0r_palette)
