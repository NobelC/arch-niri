# ── 40-keybinds ───────────────────────────────────────────────────────────────
bindkey -e                                   # modo emacs (Ctrl+A/E/K/W...)

# Inicio / fin / suprimir (varias secuencias según el terminal)
bindkey '^[[H'  beginning-of-line;  bindkey '^[[1~' beginning-of-line;  bindkey '^[OH' beginning-of-line
bindkey '^[[F'  end-of-line;        bindkey '^[[4~' end-of-line;        bindkey '^[OF' end-of-line
bindkey '^[[3~' delete-char

# Ctrl+←/→ saltan palabras; Ctrl+Backspace / Ctrl+Supr las borran
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^H'      backward-kill-word
bindkey '^[[3;5~' kill-word

# Shift+Tab: retrocede en el menú de completado
bindkey '^[[Z' reverse-menu-complete
bindkey -M menuselect '^[[Z' reverse-menu-complete

# ↑/↓: historial filtrado por lo ya escrito
if (( $+widgets[history-substring-search-up] )); then
  bindkey '^[[A' history-substring-search-up;   bindkey '^[OA' history-substring-search-up
  bindkey '^[[B' history-substring-search-down; bindkey '^[OB' history-substring-search-down
else
  autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
  zle -N up-line-or-beginning-search; zle -N down-line-or-beginning-search
  bindkey '^[[A' up-line-or-beginning-search;   bindkey '^[OA' up-line-or-beginning-search
  bindkey '^[[B' down-line-or-beginning-search; bindkey '^[OB' down-line-or-beginning-search
fi

# Ctrl+Espacio acepta la sugerencia
(( $+widgets[autosuggest-accept] )) && bindkey '^ ' autosuggest-accept

# Ctrl+X Ctrl+E: edita la línea en $EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# Esc Esc: antepone/quita `sudo` (si la línea está vacía, usa el comando anterior)
_sudo_toggle() {
  [[ -z $BUFFER ]] && BUFFER=$history[$((HISTCMD-1))]
  if [[ $BUFFER == sudo\ * ]]; then BUFFER="${BUFFER#sudo }"; else BUFFER="sudo $BUFFER"; fi
  CURSOR=${#BUFFER}
}
zle -N _sudo_toggle
bindkey '\e\e' _sudo_toggle

# Ctrl+Z: con la línea vacía vuelve al trabajo suspendido (fg); si no, guarda lo escrito
_fg_toggle() {
  if (( ${#BUFFER} == 0 )); then BUFFER=fg; zle accept-line
  else zle push-input; zle clear-screen; fi
}
zle -N _fg_toggle
bindkey '^Z' _fg_toggle
