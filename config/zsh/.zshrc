# ~/.zshrc  ->  enlace a <repo>/config/zsh/zshrc  (lo crea scripts/zsh-link.sh)
#
# Todo vive en módulos ordenados dentro de ~/.config/zsh/conf.d/ (enlace al repo):
#   00-env  05-options  10-history  20-completion  30-plugins  40-keybinds
#   50-aliases  55-git  60-functions  70-prompt  90-syntax-highlighting
# Lo propio de esta máquina (y que NO se sube al repo) va en ~/.config/zsh/local.zsh.
#
# Medir qué tarda en arrancar:   ZSH_PROF=1 zsh -i -c exit

[[ -n $ZSH_PROF ]] && zmodload zsh/zprof

ZSHCONF="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

for _f in "$ZSHCONF"/conf.d/*.zsh(N); do
  source "$_f"
done
unset _f

[[ -r $ZSHCONF/local.zsh ]] && source "$ZSHCONF/local.zsh"

[[ -n $ZSH_PROF ]] && zprof
true

# >>> project-picker >>>
[ -r "/home/nobelc/.config/project-picker/pp.sh" ] && . "/home/nobelc/.config/project-picker/pp.sh"
# <<< project-picker <<<
export PATH="$HOME/.local/bin:$PATH"
