-- Bordes exteriores rígidos a 90° (sin esquinas redondeadas)
require("full-border"):setup {
    set = ui.Border.PLAIN,
}

-- Etiqueta industrial japonesa en la cabecera (izquierda)
Header:children_add(function()
    return ui.Line {
        ui.Span(" 記録 // FILES "):reverse():bold(),
        ui.Span(" "),
    }
end, 500, Header.LEFT)
