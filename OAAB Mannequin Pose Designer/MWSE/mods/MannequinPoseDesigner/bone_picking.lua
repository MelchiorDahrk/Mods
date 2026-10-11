-- Hover and clicks share the same projected targets, radius and overlap rules.
local M={}
local radiusSquared=18*18

local function pick(s,screen,indices,selectedId)
    if s.handles==false then return end
    local best,distance=nil,radiusSquared
    for _,i in ipairs(indices) do
        local p=screen[i]
        if p then
            local d=(p.x-s.cursor[1])^2+(p.y-s.cursor[2])^2
            if d<distance then best,distance=i,d end
        end
    end
    -- Bip01 and Pelvis share a pivot in stock poses. Retain the selected
    -- marker when subpixel projection differences favor the other bone.
    local selected=screen[selectedId]
    if best and selected then
        local nearest=screen[best]
        if (selected.x-nearest.x)^2+(selected.y-nearest.y)^2<=1 and
            (selected.x-s.cursor[1])^2+(selected.y-s.cursor[2])^2<radiusSquared then
            return selectedId
        end
    end
    return best
end
function M.pick(s,indices)
    return pick(s,s.screen or {},indices or s.selectable or {},s.selected)
end
function M.prop(s)
    local ids={}
    for _,p in ipairs(s.props or {}) do ids[#ids+1]=p.id end
    return pick(s,s.propScreen or {},ids,s.selectedProp)
end
-- The closest node wins; a selected prop retains a shared bone/prop pivot.
function M.target(s,preferBone,indices)
    local bone,prop=M.pick(s,indices),M.prop(s)
    if bone and (preferBone or not prop) then return bone end
    if prop and bone then
        local b,p=s.screen[bone],s.propScreen[prop]
        if (b.x-s.cursor[1])^2+(b.y-s.cursor[2])^2<(p.x-s.cursor[1])^2+(p.y-s.cursor[2])^2
            and not (prop==s.selectedProp and (b.x-p.x)^2+(b.y-p.y)^2<=1) then return bone end
    end
    return nil,prop
end

return M
