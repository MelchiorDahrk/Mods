-- Small, engine-independent math layer. Matrices are row-major, vectors columns.
local M = {}
function M.add(a, b) return {a[1]+b[1], a[2]+b[2], a[3]+b[3]} end
function M.sub(a, b) return {a[1]-b[1], a[2]-b[2], a[3]-b[3]} end
function M.scale(a, s) return {a[1]*s, a[2]*s, a[3]*s} end
function M.dot(a, b) return a[1]*b[1]+a[2]*b[2]+a[3]*b[3] end
function M.cross(a, b) return {a[2]*b[3]-a[3]*b[2], a[3]*b[1]-a[1]*b[3], a[1]*b[2]-a[2]*b[1]} end
function M.length(a) return math.sqrt(M.dot(a,a)) end
function M.unit(a, fallback)
    local length = M.length(a)
    if length < 1e-8 then return fallback or {1,0,0} end
    return M.scale(a, 1/length)
end
function M.clamp(x, lo, hi) return math.max(lo, math.min(hi, x)) end
function M.identity() return {1,0,0, 0,1,0, 0,0,1} end
function M.transpose(a) return {a[1],a[4],a[7], a[2],a[5],a[8], a[3],a[6],a[9]} end
function M.orthonormalize(a)
    local x=M.unit({a[1],a[2],a[3]})
    local y={a[4],a[5],a[6]}
    y=M.sub(y,M.scale(x,M.dot(x,y)))
    if M.length(y)<1e-8 then
        local fallback=math.abs(x[1])<0.8 and {1,0,0} or {0,1,0}
        y=M.sub(fallback,M.scale(x,M.dot(x,fallback)))
    end
    y=M.unit(y)
    local z=M.unit(M.cross(x,y))
    y=M.cross(z,x)
    return {x[1],x[2],x[3],y[1],y[2],y[3],z[1],z[2],z[3]}
end
function M.mul(a, b)
    local out = {}
    for r=0,2 do for c=1,3 do
        out[r*3+c] = a[r*3+1]*b[c]+a[r*3+2]*b[c+3]+a[r*3+3]*b[c+6]
    end end
    return out
end
function M.transform(a, v)
    return {a[1]*v[1]+a[2]*v[2]+a[3]*v[3], a[4]*v[1]+a[5]*v[2]+a[6]*v[3], a[7]*v[1]+a[8]*v[2]+a[9]*v[3]}
end
function M.axisAngle(axis, angle)
    local v = M.unit(axis)
    local x,y,z = v[1],v[2],v[3]
    local c,s = math.cos(angle),math.sin(angle)
    local t=1-c
    return {t*x*x+c,t*x*y-s*z,t*x*z+s*y, t*x*y+s*z,t*y*y+c,t*y*z-s*x, t*x*z-s*y,t*y*z+s*x,t*z*z+c}
end
function M.between(a, b)
    a,b = M.unit(a),M.unit(b)
    local d = M.clamp(M.dot(a,b), -1,1)
    local axis = M.cross(a,b)
    local sine=M.length(axis)
    if sine < 1e-8 then
        if d >= 0 then return M.identity() end
        axis = M.cross(a, math.abs(a[1]) < 0.8 and {1,0,0} or {0,1,0})
        return M.axisAngle(axis,math.pi)
    end
    return M.axisAngle(axis, math.atan2(sine,d))
end
function M.quaternion(a)
    local w,x,y,z
    local trace=a[1]+a[5]+a[9]
    if trace > 0 then
        local s=math.sqrt(trace+1)*2
        w,x,y,z=s/4,(a[8]-a[6])/s,(a[3]-a[7])/s,(a[4]-a[2])/s
    elseif a[1] > a[5] and a[1] > a[9] then
        local s=math.sqrt(1+a[1]-a[5]-a[9])*2
        w,x,y,z=(a[8]-a[6])/s,s/4,(a[2]+a[4])/s,(a[3]+a[7])/s
    elseif a[5] > a[9] then
        local s=math.sqrt(1+a[5]-a[1]-a[9])*2
        w,x,y,z=(a[3]-a[7])/s,(a[2]+a[4])/s,s/4,(a[6]+a[8])/s
    else
        local s=math.sqrt(1+a[9]-a[1]-a[5])*2
        w,x,y,z=(a[4]-a[2])/s,(a[3]+a[7])/s,(a[6]+a[8])/s,s/4
    end
    local n=math.sqrt(w*w+x*x+y*y+z*z)
    return {w/n,x/n,y/n,z/n}
end
-- Quaternions use NIF's {w,x,y,z} order. Follow the shortest arc; normalize
-- the near-identical fallback to avoid instability when sin(theta) is tiny.
function M.slerp(a,b,t)
    local dot=0
    for i=1,4 do dot=dot+a[i]*b[i] end
    local sign=dot<0 and -1 or 1
    dot=M.clamp(dot*sign,0,1)
    local left,right=1-t,t
    if dot<0.9995 then
        local angle=math.acos(dot)
        local sine=math.sin(angle)
        left,right=math.sin((1-t)*angle)/sine,math.sin(t*angle)/sine
    end
    local out,n={},0
    for i=1,4 do out[i]=left*a[i]+right*sign*b[i]; n=n+out[i]^2 end
    n=math.sqrt(n)
    for i=1,4 do out[i]=out[i]/n end
    return out
end
function M.quaternionMatrix(q)
    local w,x,y,z=unpack(q)
    return {
        1-2*(y*y+z*z),2*(x*y-w*z),2*(x*z+w*y),
        2*(x*y+w*z),1-2*(x*x+z*z),2*(y*z-w*x),
        2*(x*z-w*y),2*(y*z+w*x),1-2*(x*x+y*y),
    }
end
function M.copy(a) local b={} for i,v in ipairs(a) do b[i]=v end return b end

-- Analytic, length-preserving two-bone IK. Pole is a point, not an angle.
-- Clamp both unreachable and fully folded targets; never stretch or divide by zero.
function M.twoBone(root, target, pole, upperLength, lowerLength)
    assert(upperLength > 1e-6 and lowerLength > 1e-6, "Zero-length IK segment")
    local delta=M.sub(target,root)
    local direction=M.unit(delta, {0,0,-1})
    local distance=M.clamp(M.length(delta), math.abs(upperLength-lowerLength)+1e-5, upperLength+lowerLength-1e-5)
    local bend=M.sub(pole,root)
    bend=M.sub(bend,M.scale(direction,M.dot(bend,direction)))
    if M.length(bend)<1e-6 then
        bend=M.cross(direction,math.abs(direction[3])<0.8 and {0,0,1} or {0,1,0})
    end
    bend=M.unit(bend)
    local along=(upperLength^2-lowerLength^2+distance^2)/(2*distance)
    local height=math.sqrt(math.max(0,upperLength^2-along^2))
    return M.add(root,M.add(M.scale(direction,along),M.scale(bend,height))), M.add(root,M.scale(direction,distance))
end
return M
