local markup = require('openmw.markup')
local types = require('openmw.types')
local vfs = require('openmw.vfs')
local world = require('openmw.world')

local szudzik = require('scripts.WS.szudzik')

local WS_PREFIX = '[ MD\'S WHITE SURAN ]:'
local MISSING_MESH_ERROR = [[
Requested model %s to replace %s on object %s, but the mesh was not found!
White Suran MD edition was not properly installed!
]]

local TICKS_TO_DELETE = 3

local USE_GLOBAL_FUNCTIONS = true

---@alias SzudzikCoord integer
---@alias GameObject userdata

---@type table <string, string>
local meshesToReplace = {}

---@type table <string, boolean>
local ignoreList = {}

---@type table <string, boolean>
local overrideList = {}

---@type table <SzudzikCoord, boolean>
local globalCells = {}

---@type table <GameObject, integer>
local objectDeleteQueue = {}

---@type table <string, boolean>
local replaceNames = {}

---@alias RecordId string
---@alias OriginalModel RecordId
---@alias ReplacedRecordId RecordId
---@alias ReplacementMap table < OriginalModel, ReplacedRecordId >

---@type ReplacementMap
local overrideRecords = {}

---Function to normalize path separators in a string
---@param path string
---@return string normalized path
local function normalizePath(path)
  local normalized, _ = path:gsub("\\", "/"):gsub("([^:])//+", "%1/")
  return normalized:lower()
end

---@param message string
local function WSLog(message)
  return string.format("%s %s", WS_PREFIX, message)
end

---@param modelPath string
---@param originalModel string
---@param recordId string
---@return boolean whether the mesh exists or not
local function assertMeshExists(modelPath, originalModel, recordId)
  if vfs.fileExists(modelPath) then return true end
  print(WSLog(string.format(MISSING_MESH_ERROR, modelPath, originalModel, recordId)))
  return false
end

---@param object userdata
---@return boolean whether the object can be replaced or not
local function canReplace(object)
  local cell = object.cell
  local isInReplaceableExterior = globalCells[szudzik.getIndex(cell.gridX, cell.gridY)]

  local isInReplaceableNamedCell = false
  for _, replaceString in ipairs(replaceNames) do
    if cell.name:lower():match(replaceString) then
      isInReplaceableNamedCell = true
      break
    end
  end

  return isInReplaceableExterior or isInReplaceableNamedCell or overrideList[object.id]
end

---@param object GameObject
---@return userdata Object record data
local function Record(object)
  return object.type.records[object.recordId]
end

local function createReplacementRecord(object, oldModel, newModel)
  if overrideRecords[oldModel] then return end

  local newRecord = { model = newModel }

  if object.type == types.Activator then
    local oldRecord = Record(object)
    if oldRecord.name then newRecord.name = oldRecord.name end
    if oldRecord.script then newRecord.script = oldRecord.script end
  end

  overrideRecords[oldModel] = world.createRecord(types.Activator.createRecordDraft(newRecord)).id
end

---@param path string Path to check for the `meshes/` prefix
---@return string original path, but with `meshes/` prepended
local function getMeshPath(path)
  -- print(path)
  path = path:gsub("^[/\\]+", "")

  if not path:match("^meshes/") then
    path = "meshes/" .. path
  end

  return path
end

---@param object userdata
local function replaceObject(object)
  local objectRecord = Record(object)
  if not objectRecord.model then return end

  local oldModel = normalizePath(objectRecord.model)

  if not meshesToReplace[oldModel] or ignoreList[oldModel] then return end

  local newModel = meshesToReplace[normalizePath(getMeshPath(oldModel))]
  print(newModel)

  if not assertMeshExists(newModel, oldModel, object.recordId) then return end

  createReplacementRecord(object, oldModel, meshesToReplace[oldModel])

  local replacement = world.createObject(overrideRecords[oldModel])
  replacement:setScale(object.scale)
  replacement:teleport(object.cell.name, object.position, object.rotation)

  objectDeleteQueue[#objectDeleteQueue + 1] = { object = object, ticks = TICKS_TO_DELETE }
end

for meshReplacementsPath in vfs.pathsWithPrefix('meshreplacer') do
  local meshReplacementsFile = vfs.open(meshReplacementsPath)
  local meshReplacementsText = meshReplacementsFile:read('*all')
  local meshReplacementsTable = markup.decodeYaml(meshReplacementsText)

  for  _, replaceString in ipairs(meshReplacementsTable.replace_names or {}) do
    replaceNames[#replaceNames + 1] = replaceString
  end

  for oldMesh, newMesh in pairs(meshReplacementsTable.replace_meshes or {}) do
    meshesToReplace[normalizePath(getMeshPath(oldMesh))] = normalizePath(getMeshPath(newMesh))
  end

  for _, meshPath in ipairs(meshReplacementsTable.ignore_meshes or {}) do
    ignoreList[normalizePath(getMeshPath(meshPath))] = true
  end

  for _, objectRef in ipairs(meshReplacementsTable.overrides or {}) do
    overrideList[objectRef] = true
  end

  for _, cellGrid in ipairs(meshReplacementsTable.exterior_cells or {}) do
    globalCells[szudzik.getIndex(cellGrid.x, cellGrid.y)] = true
  end

  meshReplacementsFile:close()
end

return {
  engineHandlers = {
    onPlayerAdded = function()
      if not USE_GLOBAL_FUNCTIONS then return end

      for _, cell in ipairs(world.cells) do
        if cell.isExterior then
          local szudzikTest = globalCells[szudzik.getIndex(cell.gridX, cell.gridY)]
          if szudzikTest then
            for _, object in ipairs(cell:getAll()) do
              if canReplace(object) then
                replaceObject(object)
              end
            end
          end
        end
      end
    end,
    onUpdate = function()
      local i = 1
      while i <= #objectDeleteQueue do
        local objectInfo = objectDeleteQueue[i]
        if objectInfo.ticks > 0 then
          objectInfo.ticks = objectInfo.ticks - 1
          i = i + 1
        else
          objectInfo.object:remove()
          table.remove(objectDeleteQueue, i)
        end
      end
    end,
    onObjectActive = function(object)
      if object.cell.isExterior and USE_GLOBAL_FUNCTIONS then
        return
      elseif canReplace(object) then
        replaceObject(object)
      end
    end,
    onSave = function()
      return {
        overrideRecords = overrideRecords,
        objectDeleteQueue = objectDeleteQueue,
      }
    end,
    onLoad = function(data)
      if data then
        for k, v in pairs(data.overrideRecords) do
          overrideRecords[k] = v
        end
        for k, v in ipairs(data.objectDeleteQueue) do
          objectDeleteQueue[k] = v
        end
      end
    end,
  }
}
