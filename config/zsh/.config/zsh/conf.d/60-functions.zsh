# ── 60-functions ──────────────────────────────────────────────────────────────

mkcd() { mkdir -p -- "$1" && cd -- "$1"; }                 # crea la carpeta y entra
up()   { local p=; repeat ${1:-1} p+=../; cd "${p:-.}"; }   # up 3 = cd ../../..
backup() { cp -a -- "$1" "$1.bak-$(date +%F-%H%M%S)"; }
serve()  { python -m http.server "${1:-8000}"; }            # sirve la carpeta actual
ports()  { ss -tulpn; }                                     # puertos en escucha
path()   { print -l $path; }                                # PATH, uno por línea
wttr()   { curl -s "wttr.in/${1:-}?format=3"; }
ztime()  { local i; for i in 1 2 3; do ( time zsh -i -c exit ) 2>&1 | grep total; done; }   # tiempo de arranque

# Descomprime casi cualquier cosa:  extract archivo.tar.gz otro.zip
extract() {
  (( $# )) || { print -u2 "uso: extract <archivo>..."; return 1; }
  local f
  for f in "$@"; do
    [[ -f $f ]] || { print -u2 "extract: no existe: $f"; continue; }
    if (( $+commands[ouch] )); then ouch decompress "$f"; continue; fi
    case ${f:l} in
      *.tar.gz|*.tgz)   tar xzf "$f" ;;
      *.tar.bz2|*.tbz2) tar xjf "$f" ;;
      *.tar.xz|*.txz)   tar xJf "$f" ;;
      *.tar.zst)        tar --zstd -xf "$f" ;;
      *.tar)            tar xf "$f" ;;
      *.zip)            unzip "$f" ;;
      *.7z)             7z x "$f" ;;
      *.rar)            unrar x "$f" ;;
      *.gz)             gunzip -k "$f" ;;
      *.bz2)            bunzip2 -k "$f" ;;
      *.xz)             unxz -k "$f" ;;
      *.zst)            unzstd "$f" ;;
      *) print -u2 "extract: formato no soportado: $f" ;;
    esac
  done
}

if (( $+commands[yazi] )); then
  y() {
    local tmp cwd
    tmp="$(mktemp -t yazi-cwd.XXXXXX)"
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [[ -n $cwd && $cwd != $PWD && -d $cwd ]] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
  }
  alias yazi='y'
fi

# Paleta ANSI del terminal (para ver el tema activo de Aether)
colors() {
  local i
  for i in {0..15}; do
    printf '\e[48;5;%sm %3s \e[0m' $i $i
    (( i == 7 || i == 15 )) && printf '\n'
  done
}

# Cambiar de tema de Aether:  theme  (elige con fzf)   |   theme <nombre>
theme() {
  local s="$DOTFILES/scripts" t=$1
  if [[ -z $t ]]; then
    (( $+commands[fzf] )) || { print -u2 "uso: theme <nombre>"; return 1; }
    t=$(bash "$s/list-themes.sh" | awk -F'\t' '!/^#ACTIVE/ {print $1}' \
        | fzf --prompt='tema ❯ ' --header "activo: $(cat ~/.config/aether/theme/.active-theme 2>/dev/null)") || return
  fi
  bash "$s/switch-theme.sh" "$t"
}
_theme() { compadd -- ${(f)"$(ls ~/.config/aether/themes 2>/dev/null)"}; }
compdef _theme theme

if (( $+commands[fzf] )); then
  _fd_dirs() { if (( $+commands[fd] )); then fd --type d --hidden --exclude .git "$@"; else find "${1:-.}" -type d -not -path '*/.git/*'; fi }
  _fd_files() { if (( $+commands[fd] )); then fd --type f --hidden --exclude .git "$@"; else find "${1:-.}" -type f -not -path '*/.git/*'; fi }

  # Entrar a una carpeta buscándola con fzf
  fcd() {
    local d
    d=$(_fd_dirs ${1:-.} | fzf --prompt='cd ❯ ' --preview 'eza --tree --level=2 --icons=auto --color=always {} 2>/dev/null') && cd -- "$d"
  }
  # Abrir archivos en $EDITOR buscándolos con fzf (Tab = varios)
  fe() {
    local prev='head -n 200 {}' ; local -a f
    (( $+commands[bat] )) && prev='bat --color=always --style=numbers --line-range=:200 {}'
    f=("${(@f)$(_fd_files ${1:-.} | fzf -m --prompt='editar ❯ ' --preview "$prev")}")
    [[ -n $f[1] ]] && ${EDITOR:-nvim} "${f[@]}"
  }
  # Buscar texto con ripgrep y abrir el resultado en nvim en esa línea:  rgf patrón
  if (( $+commands[rg] )); then
    rgf() {
      rg --line-number --no-heading --color=always --smart-case "$@" \
        | fzf --ansi --delimiter : --prompt='rg ❯ ' \
              --preview 'bat --color=always --highlight-line {2} {1}' \
              --preview-window='right,60%,+{2}+3/3' \
              --bind 'enter:become(${EDITOR:-nvim} {1} +{2})'
    }
  fi
  # Matar procesos eligiéndolos (Tab = varios):  fkill [señal]
  fkill() {
    local pids
    pids=$(ps -u "$USER" -o pid=,comm=,args= | fzf -m --prompt='kill ❯ ' | awk '{print $1}') || return
    [[ -n $pids ]] && print -l $pids | xargs kill -"${1:-15}"
  }
fi

# Instalar / desinstalar paquetes con fzf (Tab = varios)
pacs() {
  local helper='sudo pacman'; (( $+commands[yay] )) && helper='yay'
  local -a sel
  sel=("${(@f)$( { (( $+commands[yay] )) && yay -Slq || pacman -Slq; } 2>/dev/null | sort -u \
      | fzf -m --prompt='instalar ❯ ' --preview 'pacman -Si {1} 2>/dev/null || yay -Si {1} 2>/dev/null')}")
  [[ -n $sel[1] ]] && ${=helper} -S --needed "${sel[@]}"
}
pacr() {
  pacman -Qq | fzf -m --prompt='quitar ❯ ' --preview 'pacman -Qi {1}' | xargs -ro sudo pacman -Rns
}
