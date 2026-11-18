 __build_prompt() {
  local last=$?
  local c_reset='\[\e[0m\]'
  local c_gray='\[\e[90m\]'
  local c_user='\[\e[1;32m\]'
  local c_host='\[\e[1;36m\]'
  local c_path='\[\e[1;34m\]'
  local c_git='\[\e[0;35m\]'
  local c_ok='\[\e[1;32m\]'
  local c_err='\[\e[1;31m\]'
  local git_seg='' branch mark=''
  branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  if [[ -n $branch ]]; then
    [[ -n $(git status --porcelain 2>/dev/null) ]] && mark='*'
    git_seg=" ${c_gray}│${c_git} $branch$mark${c_reset}"
  fi
  local sym="${c_ok}❯${c_reset}"
  ((last != 0)) && sym="${c_err}✗${c_reset}"
  PS1="\n${c_gray}┌─ ${c_user}\u${c_gray}@${c_host}\h ${c_gray}│ ${c_path}\w${git_seg}${c_reset}\n${c_gray}└─ ${sym} "
}
PROMPT_COMMAND='__build_prompt' 

# --- 1. NAVEGACIÓN INTELIGENTE (cd -> zoxide) ---
# Zoxide aprende los directorios que más visitas; 'cd proyectos' salta directo desde cualquier ruta
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init --cmd cd bash)"
fi

# --- 2. LISTADO Y ÁRBOLES (ls / tree -> eza) ---
if command -v eza &>/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -lh --icons --git --group-directories-first'
  alias la='eza -lah --icons --git --group-directories-first'
  alias tree='eza --tree --icons --level=3 --ignore-glob=".git|node_modules|target"'
fi

function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}
alias yazi='y'
# --- 3. LECTURA DE ARCHIVOS (cat -> bat) ---
if command -v bat &>/dev/null; then
  # --style=plain omite números de línea y bordes para copiar/pegar limpio, manteniendo el resaltado de sintaxis
  alias cat='bat --paging=never --style=plain'
  alias catn='bat --paging=never' # Con números de línea y cabecera cuando quieras inspeccionar código
fi

# --- 4. OPCIONES DE COMODIDAD EN BASH ---
# Permite entrar a una carpeta escribiendo solo su nombre (sin escribir 'cd')
shopt -s autocd
# Corrige errores tipográficos menores al escribir rutas con 'cd'
shopt -s cdspell
export PATH="$HOME/.local/bin:$PATH"

function mpv() {
    # Si se pasa una URL dividida por el shell o con espacios, la recompone o la desacopla
    if [[ "$1" =~ ^https?:// ]]; then
        setsid -f command mpv --force-window=immediate "$*" >/dev/null 2>&1
    elif [[ $# -gt 0 ]]; then
        setsid -f command mpv --force-window=immediate "$@" >/dev/null 2>&1
    else
        command mpv
    fi
}
