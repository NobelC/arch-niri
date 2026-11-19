# ── 05-options: comportamiento del shell ──────────────────────────────────────
setopt AUTO_CD              # escribir una carpeta = cd a ella
setopt AUTO_PUSHD           # cada cd apila la carpeta anterior (usa `dirs -v` y `cd -N`)
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt AUTO_PARAM_SLASH     # añade / al autocompletar variables que apuntan a directorios ($DOTFILES -> $DOTFILES/)
setopt MARK_DIRS            # añade / al final de los directorios resultantes de globs

setopt INTERACTIVE_COMMENTS # permite # comentarios en la línea de comandos
setopt EXTENDED_GLOB        # globs avanzados: **/*(.), ^patrón, (#q...)
setopt GLOB_DOTS            # incluye archivos y carpetas ocultas (.config, .zshrc) en globs sin escribir el punto
setopt NUMERIC_GLOB_SORT    # file2 antes que file10
setopt NO_CLOBBER           # evita sobrescribir archivos existentes con > (usa >| para forzar)

setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
setopt NO_BEEP
setopt NO_FLOW_CONTROL      # libera Ctrl+S / Ctrl+Q
setopt LONG_LIST_JOBS
setopt NOTIFY               # avisa al instante cuando termina un trabajo en segundo plano
