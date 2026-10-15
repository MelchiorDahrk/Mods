local camera = require('openmw.camera')
local self = require('openmw.self')
local types = require('openmw.types')
local postprocessing = require('openmw.postprocessing')
local storage = require('openmw.storage')
local settings = storage.playerSection('SettingsUntoDust')
local lists = require('scripts.UntoDust.cellLists')
local lastCell, stableFrames = nil, 0
local checked = false
local expected = true -- The isolated test starts in Andrano Ancestral Tomb.

return {
    engineHandlers = {
        onUpdate = function()
            types.Actor.stats.dynamic.health(self).current = 1000000
            if self.cell ~= lastCell then
                lastCell, stableFrames, checked = self.cell, 0, false
            end
            stableFrames = stableFrames + 1
            if stableFrames < 10 or checked or not self.cell then return end
            local group = storage.playerSection('OmwSettingGroups'):get('SettingsUntoDust')
            assert(group and group.permanentStorage, 'UNTO DUST SMOKE FAILED: MCM group missing')
            assert(group.settings.density.default == 32, 'UNTO DUST SMOKE FAILED: wrong MCM default')
            for _, key in ipairs({ 'whitelist', 'blacklist' }) do
                local control = group.settings[key]
                assert(control and control.renderer == 'UntoDustCells' and control.default,
                    'UNTO DUST SMOKE FAILED: missing cell list control ' .. key)
                local argument = storage.playerSection('SettingsUntoDustArguments'):getCopy(key)
                assert(argument and argument.ready and #argument.cells > 100,
                    'UNTO DUST SMOKE FAILED: complete cell catalogue missing')
                local found = false
                for _, name in ipairs(argument.cells) do
                    if name == "Balmora, Caius Cosades' House" then found = true end
                end
                assert(found, 'UNTO DUST SMOKE FAILED: unvisited interior missing from browser')
            end
            print('UNTO DUST MCM REGISTERED')
            local density = settings:get('density')
            local name = self.cell.name:lower()
            local shouldEnable = density > 0 and expected
            local count = 0
            for _, shader in ipairs(postprocessing.getChain()) do
                if shader.name == 'UntoDust' then
                    assert(shader:isEnabled(), 'UNTO DUST SMOKE FAILED: dust shader did not compile')
                    count = count + 1
                end
            end
            assert(count == (shouldEnable and 1 or 0), 'UNTO DUST SMOKE FAILED: wrong dust shader state in ' .. name)
            print('UNTO DUST SHADER: ' .. (shouldEnable and 'enabled in ' or 'disabled in ') .. name)
            print('UNTO DUST DENSITY: ' .. density)
            print('UNTO DUST LISTS: ' .. (shouldEnable and 'enabled' or 'disabled') .. ' in ' .. name
                .. ' | whitelisted=' .. tostring(lists.contains(settings:getCopy('whitelist'), name))
                .. ' | blacklisted=' .. tostring(lists.contains(settings:getCopy('blacklist'), name)))
            checked = true
        end,
    },
    eventHandlers = {
        UntoDustSmokeExpect = function(value)
            expected = value
            stableFrames, checked = 0, false
        end,
        UntoDustSmokeLists = function(data)
            expected = data.expected
            types.Player.sendMenuEvent(self, 'UntoDustSmokeLists', data)
            stableFrames, checked = 0, false
        end,
        UntoDustSmokeDensity = function(value)
            types.Player.sendMenuEvent(self, 'UntoDustSmokeDensity', { value = value })
            stableFrames, checked = 0, false
        end,
        UntoDustSmokeCheckDensity = function()
            assert(settings:get('density') == 85, 'UNTO DUST SMOKE FAILED: density reset on save/load')
            print('UNTO DUST MCM PERSISTED')
            assert(settings:getCopy('whitelist')["Balmora, Caius Cosades' House"],
                'UNTO DUST SMOKE FAILED: whitelist reset on save/load')
            assert(settings:getCopy('blacklist')['Samarys Ancestral Tomb'],
                'UNTO DUST SMOKE FAILED: blacklist reset on save/load')
            print('UNTO DUST FILTERS PERSISTED')
        end,
        UntoDustSmokeSave = function()
            types.Player.sendMenuEvent(self, 'UntoDustSmokeSave', {})
        end,
        UntoDustSmokeView = function(thirdPerson)
            local mode = thirdPerson and camera.MODE.ThirdPerson or camera.MODE.FirstPerson
            camera.setMode(mode, true)
            stableFrames, checked = 0, false
            print('UNTO DUST SMOKE: camera ' .. (thirdPerson and 'third person' or 'first person'))
        end,
    },
}
