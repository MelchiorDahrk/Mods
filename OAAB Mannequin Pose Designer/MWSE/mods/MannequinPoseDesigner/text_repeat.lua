-- Backspace arrives as a native UI editing event, but the engine may never
-- repeat it. Replay that exact native event while the physical key stays down.
local M={}
local delay,interval=0.4,0.05
local function backspace(e)
    return e.data0==0x80000000 or e.data0==-0x80000000 or e.character=="\b"
end
local function belongsTo(focus,field,menu)
    local found=false
    while focus do
        if focus.visible==false or focus.disabled then return false end
        if focus==field then found=true end
        if focus==menu then return found end
        focus=focus.parent
    end
    return false
end
function M.bind(menu,fields)
    local held,closed
    local function release() held=nil end
    local function erase()
        held.replaying=true
        held.event.source:forwardEvent(held.event)
        held.replaying=false
    end
    local function update(e)
        if closed or not held then return end
        local world=tes3.worldController
        local input=world.inputController
        if not input:isKeyDown(tes3.scanCode.backspace) then release(); return end
        if held.cancelled then return end
        local focus=world.menuController.inputController.textInputFocus
        if not tes3ui.menuMode()
            or input:isControlDown() or input:isAltDown() or input:isSuperDown()
            or not belongsTo(focus,held.field,menu) then
            -- Do not transfer a held key to a different field/menu. A fresh
            -- press after keyUp is required to start another repeat sequence.
            held.cancelled=true
            return
        end
        held.remaining=held.remaining-math.max(0,math.min(e.delta or 0,0.1))
        local changed=false
        while held.remaining<=1e-10 do
            -- forwardEvent preserves the native caret and paragraph editing
            -- semantics without manufacturing a translated keyboard event.
            erase()
            held.remaining=held.remaining+interval
            changed=true
        end
        if changed then menu:updateLayout() end
    end
    local function watch(target,field)
        target:registerBefore(tes3.uiEvent.keyPress,function(e)
            if closed or not backspace(e) then return end
            -- A paragraph's native handler may forward the same editing event
            -- into its text child. Let that nested native dispatch finish.
            if held and held.replaying then return end
            if e.keyData and (e.keyData.isControlDown or e.keyData.isAltDown or e.keyData.isSuperDown) then
                release(); return
            end
            -- Own both the first deletion and subsequent repeats, so engines
            -- that already repeat cannot add extra deletions or reset the delay.
            if held then return false end
            held={field=field,remaining=delay,event={source=e.source,widget=e.widget,
                forwardSource=e.forwardSource,id=e.id,data0=e.data0,data1=e.data1}}
            erase(); menu:updateLayout()
            return false
        end,1001)
    end
    for _,field in pairs(fields) do
        watch(field,field)
        local child=field:findChild("PartParagraphInput_text_input")
        if child then watch(child,field) end
    end
    event.register("enterFrame",update)
    event.register("keyUp",release,{filter=tes3.scanCode.backspace,priority=1001})
    return function()
        if closed then return end
        closed=true; held=nil
        event.unregister("enterFrame",update)
        event.unregister("keyUp",release,{filter=tes3.scanCode.backspace})
    end
end
return M
