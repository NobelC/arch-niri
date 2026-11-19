# ── 70-prompt ─────────────────────────────────────────────────────────────────
#  ┌─ usuario@equipo │ ~/carpeta │  rama ⇡1 +2 !3 ?1 │ venv
#  └─ ❯                                              ✘ 127  󰔟 12s  14:32
#
# - Los colores son índices de la paleta ANSI del terminal: cambian solos con el tema de Aether.
# - Git: UNA sola llamada (`git status --porcelain=v2 --branch`) por prompt.
#     ⇡/⇣ commits por enviar/recibir · = conflictos · + preparados (staged) · ! modificados · ? sin seguimiento · ✔ limpio
# - El prompt se construye como texto fijo (sin PROMPT_SUBST): un nombre de rama con `$(...)` no puede ejecutar nada.
# - Ajustes (ponlos en ~/.config/zsh/local.zsh):
#     PROMPT_GIT=0              desactiva la info de git (repos enormes)
#     PROMPT_SPACING=0          sin línea en blanco entre prompts
#     PROMPT_DURATION_MIN=3     segundos a partir de los cuales se muestra la duración
#     PROMPT_C_USER/HOST/DIR/GIT/SEP = índice de color 0-15

autoload -Uz add-zsh-hook
zmodload zsh/datetime 2>/dev/null     # EPOCHREALTIME

: ${PROMPT_GIT:=1}
: ${PROMPT_SPACING:=1}
: ${PROMPT_DURATION_MIN:=3}
: ${PROMPT_C_USER:=4}
: ${PROMPT_C_HOST:=5}
: ${PROMPT_C_DIR:=6}
: ${PROMPT_C_GIT:=5}
: ${PROMPT_C_SEP:=8}

typeset -g _p_rc=0 _p_start= _p_seen= _p_git= _p_dur=

# Debe ser el PRIMER precmd: guarda el código de salida del comando anterior
_prompt_capture() { _p_rc=$?; }
_prompt_preexec() { _p_start=$EPOCHREALTIME; }

# Escapa % para que el texto dinámico no se interprete como secuencia del prompt
_p_esc() { REPLY=${1//\%/%%}; }

_prompt_git() {
  _p_git=
  [[ $PROMPT_GIT == 1 ]] || return
  local out
  out=$(command git --no-optional-locks status --porcelain=v2 --branch 2>/dev/null) || return

  local line oid= branch= ab
  local -i ahead=0 behind=0 staged=0 changed=0 untracked=0 conflicts=0
  for line in "${(@f)out}"; do
    case $line in
      '# branch.oid '*)  oid=${line#'# branch.oid '} ;;
      '# branch.head '*) branch=${line#'# branch.head '} ;;
      '# branch.ab '*)   ab=(${=${line#'# branch.ab '}}); ahead=${ab[1]#+}; behind=${ab[2]#-} ;;
      '1 '*|'2 '*)       [[ ${line[3]} != . ]] && (( staged++ )); [[ ${line[4]} != . ]] && (( changed++ )) ;;
      'u '*)             (( conflicts++ )) ;;
      '? '*)             (( untracked++ )) ;;
    esac
  done
  [[ $branch == '(detached)' ]] && branch="${oid[1,7]}"
  _p_esc "$branch"; branch=$REPLY

  local g=" %F{$PROMPT_C_SEP}│%f %F{$PROMPT_C_GIT}"$''" ${branch}%f"
  (( ahead ))     && g+=" %F{2}⇡${ahead}%f"
  (( behind ))    && g+=" %F{1}⇣${behind}%f"
  (( conflicts )) && g+=" %F{1}=${conflicts}%f"
  (( staged ))    && g+=" %F{2}+${staged}%f"
  (( changed ))   && g+=" %F{3}!${changed}%f"
  (( untracked )) && g+=" %F{6}?${untracked}%f"
  (( !conflicts && !staged && !changed && !untracked )) && g+=" %F{2}✔%f"
  _p_git=$g
}

_prompt_precmd() {
  # Duración del último comando
  _p_dur=
  if [[ -n $_p_start ]]; then
    local -F d=$(( EPOCHREALTIME - _p_start )); _p_start=
    if (( d >= PROMPT_DURATION_MIN )); then
      local -i s=$d
      if   (( s >= 3600 )); then _p_dur="$(( s/3600 ))h$(( s%3600/60 ))m"
      elif (( s >= 60 ));   then _p_dur="$(( s/60 ))m$(( s%60 ))s"
      else                       _p_dur="${s}s"
      fi
    fi
  fi

  _prompt_git

  # Segmentos opcionales
  local extra=
  local venv=${VIRTUAL_ENV:t}; [[ -z $venv ]] && venv=$CONDA_DEFAULT_ENV
  if [[ -n $venv ]]; then _p_esc "$venv"; extra+=" %F{$PROMPT_C_SEP}│%f %F{3}${REPLY}%f"; fi
  [[ -n $SSH_CONNECTION ]] && extra+=" %F{$PROMPT_C_SEP}│%f %F{1}ssh%f"

  local arrow user
  if (( _p_rc == 0 )); then arrow="%F{$PROMPT_C_USER}"; else arrow='%F{1}'; fi
  user="%(!.%F{1}.%F{$PROMPT_C_USER})%n%F{$PROMPT_C_SEP}@%F{$PROMPT_C_HOST}%m%f"

  PROMPT="%F{$PROMPT_C_SEP}┌─%f ${user} %F{$PROMPT_C_SEP}│%f %F{$PROMPT_C_DIR}%(5~|%-1~/…/%3~|%~)%f${_p_git}${extra}"$'\n'"%F{$PROMPT_C_SEP}└─%f ${arrow}%(!.#.❯)%f "

  # Derecha (en la línea de ❯): error · duración · trabajos en segundo plano · hora
  local r=
  (( _p_rc != 0 )) && r+="%F{1}✘ ${_p_rc}%f  "
  [[ -n $_p_dur ]] && r+="%F{3}"$''" ${_p_dur}%f  "
  r+="%(1j.%F{6}✦%j%f  .)%F{$PROMPT_C_SEP}%T%f"
  RPROMPT=$r

  # Línea en blanco entre prompts (no antes del primero)
  [[ $PROMPT_SPACING == 1 && -n $_p_seen ]] && print
  _p_seen=1
}

PROMPT2="%F{$PROMPT_C_SEP}  ∙%f "
ZLE_RPROMPT_INDENT=0
setopt TRANSIENT_RPROMPT            # la hora/duración desaparecen del historial de pantalla

add-zsh-hook preexec _prompt_preexec
add-zsh-hook precmd  _prompt_precmd
precmd_functions=(_prompt_capture ${precmd_functions:#_prompt_capture})
