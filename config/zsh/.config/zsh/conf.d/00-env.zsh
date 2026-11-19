# ── 00-env: cache, PATH, colores base y variables de entorno ──────────────────

# --- Variables base XDG ---
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# --- Cache y directorios base ---
export ZSH_CACHE_DIR="$XDG_CACHE_HOME/zsh"
[[ -d "$ZSH_CACHE_DIR" ]] || mkdir -p "$ZSH_CACHE_DIR"
[[ -d "$HOME/.local/bin" ]] || mkdir -p "$HOME/.local/bin"

# Raíz del repo (<repo>/config/zsh/.config/zsh/conf.d/00-env.zsh -> 5 niveles arriba)
export DOTFILES="${${(%):-%x}:A:h:h:h:h:h}"

# --- Compilación paralela (paru, C++, Rust) ---
export MAKEFLAGS="-j$(nproc)"

# --- PATH (sin duplicados y solo rutas existentes) ---
typeset -U path
for _p in "$HOME/.local/bin" "$HOME/.npm-global/bin" "$HOME/.cargo/bin"; do
  [[ -d "$_p" ]] && path=("$_p" $path)
done
unset _p
export PATH

# --- Colores base para completado y listado ---
(( $+commands[dircolors] )) && eval "$(dircolors -b)"

# --- Editor y Pager ---
if (( $+commands[nvim] )); then
  export EDITOR=nvim VISUAL=nvim
else
  export EDITOR=vim VISUAL=vim
fi

export LESS='-R -i'
export LESSHISTFILE=-

# bat con tema "ansi": hereda la paleta dinámica de Matugen en Ghostty
if (( $+commands[bat] )); then
  export BAT_THEME=ansi
  export BAT_STYLE='numbers,changes,header'
  export MANPAGER="sh -c 'col -bx | bat --language=man --plain'"
  export MANROFFOPT='-c'
else
  export LESS_TERMCAP_mb=$'\e[1;35m' LESS_TERMCAP_md=$'\e[1;36m' LESS_TERMCAP_me=$'\e[0m'
  export LESS_TERMCAP_us=$'\e[4;32m' LESS_TERMCAP_ue=$'\e[0m'
  export LESS_TERMCAP_so=$'\e[30;43m' LESS_TERMCAP_se=$'\e[0m'
fi
