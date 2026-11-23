# ── 50-aliases ────────────────────────────────────────────────────────────────
# Para saltarte un alias puntualmente: \cat archivo   o   command cat archivo

# --- ls -> eza ---
if (( $+commands[eza] )); then
  alias ls='eza --icons=auto --group-directories-first'
  alias l='eza -1 --icons=auto --group-directories-first'
  alias ll='eza -lh --icons=auto --group-directories-first --git'
  alias la='eza -lah --icons=auto --group-directories-first --git'
  alias lt='eza --tree --level=2 --icons=auto --group-directories-first'
  alias lta='eza --tree --level=2 -a --icons=auto --group-directories-first --ignore-glob=.git'
else
  alias ls='ls --color=auto --group-directories-first'
  alias ll='ls -lh'
  alias la='ls -lAh'
fi

# --- cat -> bat (en una tubería se comporta como cat normal) ---
if (( $+commands[bat] )); then
  alias cat='bat --paging=never'
  alias catp='bat --paging=never --plain'     # sin números ni cabecera
  alias less='bat --paging=always'            # visor con colores (q para salir)
fi

# --- Herramientas modernas, si existen ---
(( $+commands[nvim] ))    && alias v='nvim' vi='nvim' vim='nvim'
alias grep='grep --color=auto'
(( $+commands[lazygit] )) && alias lg='lazygit'
(( $+commands[btop] ))    && alias top='btop'
alias diff='diff --color=auto'
alias ip='ip -color=auto'
alias df='df -h'
alias free='free -h'
alias mkdir='mkdir -pv'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -I'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'
alias dirs='dirs -v'
alias h='history 1'
alias c='clear'
alias q='exit'
alias ping='gping'

# --- Arch / pacman / paru ---
if (( $+commands[paru] )); then
  alias update='paru -Syu'
  alias aur='paru -S --needed'
else
  alias update='sudo pacman -Syu'
fi
alias pac='sudo pacman -S --needed'
alias pacrm='sudo pacman -Rns'
alias orphans='pacman -Qtdq'
alias pkgclean='sudo pacman -Sc'

# --- Dotfiles / Niri ---
alias dots='cd "$DOTFILES"'
alias nirilog='journalctl --user -u niri -f'
alias reload='exec zsh'
