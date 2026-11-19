# ── 30-plugins: plugins de Arch (/usr/share/zsh/plugins), fzf y zoxide ────────
# Todo es opcional: si un paquete no está instalado simplemente se omite.
# (syntax-highlighting se carga al final, en 90-syntax-highlighting.zsh)

# fzf-tab (AUR: fzf-tab-git): completado con fzf. Debe ir tras compinit y antes de los demás plugins.
_fzftab=(/usr/share/zsh/plugins/fzf-tab*/fzf-tab.plugin.zsh(N) /usr/share/fzf-tab/fzf-tab.plugin.zsh(N))
(( $#_fzftab )) && source "$_fzftab[1]"
unset _fzftab

# --- fzf: Ctrl+R (historial), Ctrl+T (archivos), Alt+C (carpetas) ---
if (( $+commands[fzf] )); then
  # Colores = índices de la paleta ANSI del terminal -> siguen al tema de Aether
  export FZF_DEFAULT_OPTS="--height=60% --layout=reverse --border=rounded --info=inline \
--prompt='❯ ' --pointer='▶' --marker='✓' \
--color=fg:-1,bg:-1,hl:5,fg+:-1,bg+:8,hl+:5,info:6,prompt:4,pointer:5,marker:2,spinner:5,header:6,border:8,gutter:-1"

  if (( $+commands[fd] )); then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi

  _fzf_dir_prev='eza --tree --level=2 --icons=auto --color=always {} 2>/dev/null || ls -1 {}'
  if (( $+commands[bat] )); then
    _fzf_file_prev='bat --color=always --style=numbers --line-range=:200 {}'
  else
    _fzf_file_prev='head -n 200 {}'
  fi
  export FZF_CTRL_T_OPTS="--preview 'if [ -d {} ]; then $_fzf_dir_prev; else $_fzf_file_prev; fi'"
  export FZF_ALT_C_OPTS="--preview '$_fzf_dir_prev'"
  export FZF_CTRL_R_OPTS="--preview 'echo {2..}' --preview-window=down:3:wrap"
  unset _fzf_dir_prev _fzf_file_prev

  if ! source <(fzf --zsh 2>/dev/null) 2>/dev/null; then   # fzf >= 0.48; si no, los archivos clásicos
    [[ -r /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
    [[ -r /usr/share/fzf/completion.zsh ]]   && source /usr/share/fzf/completion.zsh
  fi

  # fzf-tab: vista previa al completar
  zstyle ':fzf-tab:*' switch-group ',' '.'
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --icons=auto --color=always $realpath 2>/dev/null'
  zstyle ':fzf-tab:complete:z:*'  fzf-preview 'eza -1 --icons=auto --color=always $realpath 2>/dev/null'
fi

# --- zoxide: `z carpeta` salta a las carpetas más usadas, `zi` elige con fzf ---
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

# --- Sugerencias gris tenue mientras escribes (→ o Ctrl+Espacio para aceptar) ---
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=60
[[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] \
  && source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# --- ↑/↓ buscan en el historial lo que ya escribiste ---
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=8,fg=7,bold'
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='bg=1,fg=0,bold'
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1
[[ -r /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh ]] \
  && source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

# --- "comando no encontrado" que sugiere el paquete (sudo pacman -S pkgfile && sudo pkgfile -u) ---
[[ -r /usr/share/doc/pkgfile/command-not-found.zsh ]] && source /usr/share/doc/pkgfile/command-not-found.zsh
