# ── 55-git: alias y funciones (con fzf cuando está disponible) ────────────────
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gcane='git commit --amend --no-edit'
alias gco='git checkout'
alias gsw='git switch'
alias gb='git branch'
alias gd='git diff'
alias gds='git diff --staged'
alias gl="git log --graph --pretty=format:'%C(auto)%h%d %s %C(dim)%an, %ar' -20"
alias gla="git log --graph --all --pretty=format:'%C(auto)%h%d %s %C(dim)%an, %ar'"
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpl='git pull --rebase --autostash'
alias gf='git fetch --all --prune'
alias gst='git stash'
alias gstp='git stash pop'
alias grb='git rebase'
alias gcp='git cherry-pick'
alias gundo='git reset --soft HEAD~1'      # deshace el último commit conservando los cambios

# Añadir todo y commitear:  gac "mensaje"      (gacp además hace push)
gac()  { git add -A && git commit -m "$*"; }
gacp() { git add -A && git commit -m "$*" && git push; }

# Ir a la raíz del repo
groot() { cd "$(git rev-parse --show-toplevel)" || return; }

# Clonar y entrar:  gcl https://github.com/usuario/repo.git
gcl() {
  git clone "$@" || return
  local d="${${@[-1]:t}%.git}"
  [[ -d $d ]] && cd "$d"
}

# Borra las ramas locales ya fusionadas (salvo main/master/develop)
gbclean() {
  git branch --merged | grep -vE '^\*|^\s*(main|master|develop)$' | xargs -r git branch -d
}

if (( $+commands[fzf] )); then
  # Cambiar de rama con vista previa del historial
  gcb() {
    local b
    b=$(git for-each-ref --format='%(refname:short)' refs/heads refs/remotes | grep -v '/HEAD$' \
        | fzf --prompt='rama ❯ ' --preview 'git log --oneline --graph --color=always -20 {}') || return
    git switch "${b#origin/}"
  }
  # Explorar el historial (Enter abre el commit)
  glf() {
    git log --oneline --color=always --decorate \
      | fzf --ansi --no-sort --reverse --prompt='commit ❯ ' \
            --preview 'git show --color=always {1}' \
            --bind 'enter:execute(git show --color=always {1} | less -R)'
  }
  # Elegir qué archivos añadir (Tab = varios)
  gaf() {
    git -c color.status=always status --short \
      | fzf -m --ansi --prompt='add ❯ ' --preview 'git diff --color=always -- {2}' \
      | awk '{print $2}' | xargs -r git add
    git status -sb
  }
fi
