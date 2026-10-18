local lfs = require('lfs')
local files = require('customweather.regionfiles')
local M = {}
local root = 'Data Files/'

function M.export(region, preset)
    local text = files.export(region, preset)
    local directory = root
    for part in files.directory:gmatch('[^/]+') do
        directory = directory .. part .. '/'
        if not lfs.directoryexists(directory) then
            local ok, err = lfs.mkdir(directory)
            assert(ok, err)
        end
    end
    local filename = files.filename(region)
    local path, n = directory .. filename, 1
    while lfs.attributes(path) do
        n = n + 1
        path = directory .. filename:sub(1, -5) .. '_' .. n .. '.lua'
    end
    local handle, err = io.open(path, 'wb')
    assert(handle, err)
    local ok, writeError = handle:write(text)
    local closed, closeError = handle:close()
    assert(ok, writeError)
    assert(closed, closeError)
    return path
end

return M
