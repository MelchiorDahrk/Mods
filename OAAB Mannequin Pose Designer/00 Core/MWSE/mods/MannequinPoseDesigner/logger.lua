local config=require("MannequinPoseDesigner.config")

return function(format,...)
    if config.debugMode then mwse.log(format,...) end
end
