# ── 10-history ────────────────────────────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000

setopt EXTENDED_HISTORY
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY_TIME
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_SPACE
setopt HIST_NO_STORE
setopt HIST_VERIFY

# Comandos triviales que no merece la pena recordar
HISTORY_IGNORE='(ls|ll|la|l|lt|pwd|exit|clear|history|cd|cd ..)'
