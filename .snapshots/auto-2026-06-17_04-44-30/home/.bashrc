#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
eval "$(starship init bash)"
export PATH="$HOME/.local/bin:$PATH"

# Show system info when opening an interactive terminal
command -v fastfetch >/dev/null && fastfetch
