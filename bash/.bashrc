 __build_prompt() {

  local last=$?


  # Paleta de colores

  local c_reset='\[\e[0m\]'

  local c_gray='\[\e[90m\]'

  local c_user='\[\e[1;32m\]'

  local c_host='\[\e[1;36m\]'

  local c_path='\[\e[1;34m\]'

  local c_git='\[\e[0;35m\]'

  local c_ok='\[\e[1;32m\]'

  local c_err='\[\e[1;31m\]'


  # Segmento git: rama + '*' si hay cambios sin commitear

  local git_seg='' branch mark=''

  branch=$(git symbolic-ref --short HEAD 2>/dev/null)

  if [[ -n $branch ]]; then

    [[ -n $(git status --porcelain 2>/dev/null) ]] && mark='*'

    git_seg=" ${c_gray}│${c_git} $branch$mark${c_reset}"

  fi


  # Símbolo de estado: ❯ verde si ok, ✗ rojo si el último comando falló

  local sym="${c_ok}❯${c_reset}"

  ((last != 0)) && sym="${c_err}✗${c_reset}"


  PS1="\n${c_gray}┌─ ${c_user}\u${c_gray}@${c_host}\h ${c_gray}│ ${c_path}\w${git_seg}${c_reset}\n${c_gray}└─ ${sym} "

}


PROMPT_COMMAND='__build_prompt' 
