--- @sync entry
return {
    entry = function()
        local h = cx.active.current.hovered
        if not h then return end

        if h.cha.is_dir then
            ya.emit("cd", { h.url })
            ya.emit("quit", {})
        else
            local mime = h:mime() or ""
            ya.emit("open", {})
            if mime:find("^video/") or mime:find("^audio/") then
                ya.emit("quit", {})
            end
        end
    end,
}
