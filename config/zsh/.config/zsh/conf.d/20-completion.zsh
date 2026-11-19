# ── 20-completion ─────────────────────────────────────────────────────────────
zmodload zsh/complist
autoload -Uz compinit

# El volcado se regenera como máximo una vez al día (arranque mucho más rápido)
_zcd="$ZSH_CACHE_DIR/zcompdump"
if [[ -n $_zcd(#qN.mh+24) ]]; then
  compinit -d "$_zcd"
else
  compinit -C -d "$_zcd"
fi
unset _zcd

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose yes
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "$ZSH_CACHE_DIR/zcompcache"
zstyle ':completion:*:descriptions' format '%F{5}── %d ──%f'
zstyle ':completion:*:warnings'     format '%F{1}── sin coincidencias ──%f'
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:*:*:*:processes' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'
zstyle ':completion:*:*:kill:*' menu yes select
