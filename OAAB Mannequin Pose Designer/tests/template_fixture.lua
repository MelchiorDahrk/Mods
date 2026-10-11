local v=require("MannequinPoseDesigner.math3d")
local names={
    "Bip01","Bip01 Pelvis","Bip01 Spine",
    "Bip01 L Thigh","Bip01 L Calf","Bip01 L Foot",
    "Bip01 R Thigh","Bip01 R Calf","Bip01 R Foot",
    "Bip01 Spine1","Bip01 Spine2","Bip01 Neck","Bip01 Head",
    "Bip01 L Clavicle","Bip01 L UpperArm","Bip01 L Forearm",
    "Bip01 L Hand","Bip01 L Finger0","Bip01 L Finger01",
    "Bip01 L Finger1","Bip01 L Finger11","Bip01 L Finger2",
    "Bip01 L Finger21","Shield Bone",
    "Bip01 R Clavicle","Bip01 R UpperArm","Bip01 R Forearm",
    "Bip01 R Hand","Bip01 R Finger0","Bip01 R Finger01",
    "Bip01 R Finger1","Bip01 R Finger11","Bip01 R Finger2",
    "Bip01 R Finger21","Weapon Bone",
}
local bones={}
for i,name in ipairs(names) do
    bones[i]={name=name,parent=i==1 and 0 or 1,
        translation={i,i*0.5,60-i},rotation=v.axisAngle({0,0,1},i*0.01),
        scale=1+i*0.0001}
end
return bones
