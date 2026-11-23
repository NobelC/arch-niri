# ── 30-plugins: plugins de Arch (/usr/share/zsh/plugins), fzf y zoxide ────────

_fzftab=(/usr/share/zsh/plugins/fzf-tab*/fzf-tab.plugin.zsh(N) /usr/share/fzf-tab/fzf-tab.plugin.zsh(N))
(( $#_fzftab )) && source "$_fzftab[1]"
unset _fzftab

if (( $+commands[fzf] )); then
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

  _fzf_cache="$ZSH_CACHE_DIR/fzf-init.zsh"
  if [[ ! -s "$_fzf_cache" || "$commands[fzf]" -nt "$_fzf_cache" ]]; then
    if ! fzf --zsh >| "$_fzf_cache" 2>/dev/null; then
      rm -f "$_fzf_cache"
    else
      zcompile "$_fzf_cache" 2>/dev/null || true
    fi
  fi
  if [[ -s "$_fzf_cache" ]]; then
    source "$_fzf_cache"
  else
    [[ -r /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
    [[ -r /usr/share/fzf/completion.zsh ]]   && source /usr/share/fzf/completion.zsh
  fi
  unset _fzf_cache

  zstyle ':fzf-tab:*' switch-group ',' '.'
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --icons=auto --color=always $realpath 2>/dev/null'
  zstyle ':fzf-tab:complete:z:*'  fzf-preview 'eza -1 --icons=auto --color=always $realpath 2>/dev/null'
fi

if (( $+commands[zoxide] )); then
  _zox_cache="$ZSH_CACHE_DIR/zoxide-init.zsh"
  if [[ ! -s "$_zox_cache" || "$commands[zoxide]" -nt "$_zox_cache" ]]; then
    zoxide init zsh >| "$_zox_cache"
    zcompile "$_zox_cache" 2>/dev/null || true
  fi
  source "$_zox_cache"
  unset _zox_cache
fi

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=60
[[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] \
  && source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=8,fg=7,bold'
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='bg=1,fg=0,bold'
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1
[[ -r /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh ]] \
  && source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

[[ -r /usr/share/doc/pkgfile/command-not-found.zsh ]] && source /usr/share/doc/pkgfile/command-not-found.zsh
