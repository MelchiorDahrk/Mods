package.path="./MWSE/mods/?.lua;"..package.path
local count=0
local function check(ok,why) assert(ok,why); count=count+1 end
local saved

local function start(apiVersion)
    for _,name in ipairs({"config","logger","mcm","main"}) do
        package.loaded["MannequinPoseDesigner."..name]=nil
    end
    local callbacks,lines={},{}
    local template
    local buttons={}
    local pages={}
    local propRuntime={}
    package.loaded["OAAB.Mannequins.poses"]={apiVersion=apiVersion or 6}
    package.loaded["OAAB.Mannequins.pose_props"]=propRuntime
    package.loaded["MannequinPoseDesigner.session"]={register=function() end}
    package.loaded["MannequinPoseDesigner.library_menu"]={update=function() end,close=function() end}
    event={register=function(name,callback) callbacks[name]=callback end}
    mwse={
        log=function(format,...) lines[#lines+1]=string.format(format,...) end,
        loadConfig=function(path,defaults)
            check(path=="MannequinPoseDesigner" and defaults.debugMode==false and defaults.focusModeByDefault==false,
                "Startup uses the mod's config and off defaults")
            return saved or defaults
        end,
        saveConfig=function(path,config)
            check(path=="MannequinPoseDesigner","MCM saves to the same config loaded at startup")
            saved={debugMode=config.debugMode,focusModeByDefault=config.focusModeByDefault}
        end,
        mcm={createTemplate=function(data)
            template=data
            function template:saveOnClose(path,config)
                self.onClose=function() mwse.saveConfig(path,config) end
            end
            function template:createPage(data)
                pages[#pages+1]=data
                return {createOnOffButton=function(_,data) buttons[data.configKey]=data end}
            end
            function template:register() self.registered=true end
            return template
        end},
    }
    require("MannequinPoseDesigner.main")
    local config=require("MannequinPoseDesigner.config")
    local log=require("MannequinPoseDesigner.logger")
    check(callbacks.modConfigReady and not template,"MCM creation waits for modConfigReady")
    callbacks.modConfigReady()
    check(template.registered and template.config==config and buttons.debugMode,
        "MCM button edits the live logger preference")
    check(buttons.focusModeByDefault and buttons.focusModeByDefault.label=="Enter Focus Mode by default",
        "Settings exposes the Focus Mode default toggle bound to the shared config")
    check(#pages==2 and pages[1].label=="Settings" and pages[2].label=="Poses"
        and pages[2].noScroll and type(pages[2].postCreate)=="function",
        "MCM exposes a pose page that loads its browser only when opened")
    callbacks.initialized()
    return config,log,lines,template,propRuntime
end

local config,log,lines,template,runtime=start()
check(not config.debugMode,"Debug mode defaults to off")
check(not config.focusModeByDefault,"Focus Mode by default starts off")
log("[OAAB Pose Designer] Preview %s: %d","test.nif",3)
runtime.debugLog("[OAAB Mannequins Props] Applied %d embedded props",2)
check(#lines==0,"Designer and embedded-prop diagnostics are silent by default")
config.debugMode=true
log("[OAAB Pose Designer] Preview %s: %d","test.nif",3)
runtime.debugLog("[OAAB Mannequins Props] Applied %d embedded props",2)
check(#lines==2 and lines[1]=="[OAAB Pose Designer] Preview test.nif: 3"
    and lines[2]=="[OAAB Mannequins Props] Applied 2 embedded props","Enabling debug immediately preserves diagnostic text and arguments")
template.onClose()
config,log,lines,template=start()
check(config.debugMode,"Enabled preference survives a restart")
log("After restart")
check(#lines==1,"Saved enabled preference logs after startup")
config.debugMode=false
log("Disabled again")
check(#lines==1,"Disabling debug stops logging immediately")
template.onClose()
config,log,lines=start()
check(not config.debugMode,"Disabled preference survives a restart")
log("Still disabled")
check(#lines==0,"Saved disabled preference is quiet after startup")
saved={debugMode="false"}
config,log,lines=start()
check(not config.debugMode,"Non-boolean saved values cannot accidentally enable logging")
saved=nil
config,log,lines,template=start(5)
check(#lines==0 and template.registered,"A dependency failure stays quiet and still exposes the debug MCM")
saved={debugMode=true}
config,log,lines=start(5)
check(#lines==1 and lines[1]:find("Requires OAAB_Data pose API v6",1,true),"Debug mode includes startup failure diagnostics")
check(not config.focusModeByDefault,"Existing debug-only configs keep Focus Mode by default off")
saved=nil
config,log,lines,template=start()
config.focusModeByDefault=true
template.onClose()
config,log,lines,template=start()
check(config.focusModeByDefault and not config.debugMode,"The enabled Focus Mode default survives restart independently of debug mode")
config.focusModeByDefault=false
template.onClose()
config,log,lines=start()
check(not config.focusModeByDefault,"The disabled Focus Mode default survives restart")
for _,value in ipairs({"true","false",1}) do
    saved={debugMode=false,focusModeByDefault=value}
    config,log,lines=start()
    check(not config.focusModeByDefault,"Non-boolean saved values cannot enable Focus Mode by default")
end
print("PASS: "..count.." debug logging, MCM settings and preference persistence assertions")
