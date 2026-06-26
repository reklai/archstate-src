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

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

# java
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH="$JAVA_HOME/bin:$PATH"

# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
[[ -r "$HOME/.grok/completions/bash/grok.bash" ]] && source "$HOME/.grok/completions/bash/grok.bash"
# <<< grok installer <<<
