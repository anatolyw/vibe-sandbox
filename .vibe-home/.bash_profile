# ~/.bash_profile – bash only (sourced from .zshrc with a guard)

# aliases are fine in both bash and zsh
alias la='ls -la'
alias ll='ls -l'
alias ..='cd ..'
alias ...='cd ../..'

# OpenCode CLI (installed in the image under $HOME/.opencode/bin)
export PATH="$PATH:$HOME/.opencode/bin"
