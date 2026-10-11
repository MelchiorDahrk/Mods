-- Model native effect attachment/propagation separately from scene visibility.
local M={lights={}}
local function remove(list,value)
    for i=#list,1,-1 do if list[i]==value then table.remove(list,i) end end
end
local function add(list,value)
    for _,entry in ipairs(list) do if entry==value then return end end
    list[#list+1]=value
end
function M.vector(x,y,z)
    return {x=x,y=y,z=z,copy=function(self) return M.vector(self.x,self.y,self.z) end,
        distance=function(self,other)
            return math.sqrt((self.x-other.x)^2+(self.y-other.y)^2+(self.z-other.z)^2)
        end}
end
function M.node(value)
    value.worldBoundOrigin=M.vector(0,0,70)
    value.worldBoundRadius=100
    value.effectList={}
    function value:attachEffect(light) add(self.effectList,light) end
    function value:detachEffect(light) remove(self.effectList,light) end
    function value:updateEffects()
        self.effectUpdates=(self.effectUpdates or 0)+1
        self.renderEffects={}
        for _,light in ipairs(self.effectList) do add(self.renderEffects,light) end
    end
    return value
end
niColor={new=function(r,g,b) return {r=r,g=g,b=b} end}
niPointLight={new=function()
    local light={affectedNodes={}}
    function light:attachAffectedNode(value) add(self.affectedNodes,value) end
    function light:detachAffectedNode(value) remove(self.affectedNodes,value) end
    function light:setRadius(radius)
        self.radius=radius
        self.specular=niColor.new(radius,radius,radius)
        self.constantAttenuation=0; self.linearAttenuation=1/radius; self.quadraticAttenuation=0
    end
    function light:update(args)
        assert(args.controllers==false,"Focus lighting must not advance simulation")
        self.worldPosition=self.translation:copy()
    end
    M.lights[#M.lights+1]=light
    return light
end}
return M
