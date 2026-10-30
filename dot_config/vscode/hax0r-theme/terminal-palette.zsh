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
        red) printf '\e]4;22;#4d0404\a\e]4;28;#6a0606\a\e]4;52;#441b1b\a\e]4;88;#5c2c2c\a\e]4;196;#fefefe\a' ;;
        blue) printf '\e]4;22;#012842\a\e]4;28;#013e60\a\e]4;52;#1b293b\a\e]4;88;#2c4154\a\e]4;196;#fefefe\a' ;;
        amber) printf '\e]4;22;#432b00\a\e]4;28;#624100\a\e]4;52;#392c19\a\e]4;88;#504129\a\e]4;196;#fefefe\a' ;;
        white) printf '\e]4;22;#333333\a\e]4;28;#545454\a\e]4;52;#282828\a\e]4;88;#434343\a\e]4;196;#ffffff\a' ;;
        black) printf '\e]4;22;#cccccc\a\e]4;28;#ababab\a\e]4;52;#d5d5d5\a\e]4;88;#b9b9b9\a\e]4;196;#000000\a' ;;
        *) printf '\e]4;22;#073904\a\e]4;28;#0a5505\a\e]4;52;#1c331a\a\e]4;88;#2d4a2a\a\e]4;196;#fefefe\a' ;;
    esac
}
precmd_functions+=(_hax0r_palette)
