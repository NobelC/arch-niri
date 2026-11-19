# ── 90-syntax-highlighting: SIEMPRE el último en cargarse ─────────────────────
# Colores de la paleta ANSI -> siguen al tema de Aether.
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
ZSH_HIGHLIGHT_MAXLENGTH=300
if [[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  typeset -A ZSH_HIGHLIGHT_STYLES
  ZSH_HIGHLIGHT_STYLES[comment]='fg=8'
  ZSH_HIGHLIGHT_STYLES[command]='fg=2'
  ZSH_HIGHLIGHT_STYLES[builtin]='fg=2'
  ZSH_HIGHLIGHT_STYLES[alias]='fg=2'
  ZSH_HIGHLIGHT_STYLES[function]='fg=2'
  ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=1,bold'
  ZSH_HIGHLIGHT_STYLES[path]='fg=6,underline'
  ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=3'
  ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=3'
  ZSH_HIGHLIGHT_STYLES[globbing]='fg=5'
fi
