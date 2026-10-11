for _,file in ipairs(arg) do assert(loadfile(file)) end
print("PASS: compiled "..#arg.." Lua files without executing them")
