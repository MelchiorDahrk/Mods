local M = {}

function M.read(value)
    local result = {}
    if type(value) == 'string' then
        -- Migrate selections from the former text fields without losing them.
        for name in value:gmatch('[^;\r\n]+') do
            name = name:match('^%s*(.-)%s*$')
            if name ~= '' then result[name] = true end
        end
    elseif type(value) == 'table' then
        for name, selected in pairs(value) do
            if type(name) == 'string' and name ~= '' and selected == true then
                result[name] = true
            end
        end
    end
    return result
end

function M.contains(value, name)
    for entry in pairs(M.read(value)) do
        if entry:lower() == name then return true end
    end
    return false
end

return M
