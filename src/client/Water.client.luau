-- Lightweight local water effects. These decorative parts never affect gameplay.
local RS=game:GetService('ReplicatedStorage')
local RunService=game:GetService('RunService')
local C=require(RS:WaitForChild('Pond'):WaitForChild('Config'))
local water=workspace:WaitForChild('PondEnvironment'):WaitForChild('PondWater')
local glints={}
for _,p in ipairs(water:GetChildren()) do
 if p.Name=='Glint' then table.insert(glints,{part=p,base=p.CFrame}) end
end
local folder=Instance.new('Folder');folder.Name='LocalWaterEffects';folder.Parent=workspace
local tint=Instance.new('ColorCorrectionEffect');tint.Name='Underwater tint';tint.Parent=workspace.CurrentCamera
local rng=Random.new(143)
local bubbles={}; local flecks={}
local function cosmetic(name,size,color)
 local p=Instance.new('Part');p.Name=name;p.Size=size;p.Color=color;p.Anchored=true
 p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Material=Enum.Material.Neon
 p.Parent=folder;return p
end
for i=1,40 do
 local a=rng:NextNumber(0,math.pi*2);local r=math.sqrt(rng:NextNumber())*C.shoreRadius(a)*.86
 local x,z=math.cos(a)*r,math.sin(a)*r;local floor=C.floorHeight(x,z)
 local p=cosmetic('Drifting bubble',Vector3.one*rng:NextNumber(.15,.4),Color3.fromRGB(191,239,223));p.Shape=Enum.PartType.Ball;p.Transparency=.6
 table.insert(bubbles,{part=p,x=x,z=z,floor=floor,phase=rng:NextNumber(0,35),speed=rng:NextNumber(1,2.2)})
end
for i=1,100 do
 local a=rng:NextNumber(0,math.pi*2);local r=math.sqrt(rng:NextNumber())*C.shoreRadius(a)*.84
 local x,z=math.cos(a)*r,math.sin(a)*r
 local p=cosmetic('Dappled light',Vector3.new(rng:NextNumber(2,5),.04,.3),Color3.fromRGB(218,245,188))
 p.CFrame=CFrame.new(x,C.floorHeight(x,z)+.14,z)*CFrame.Angles(0,rng:NextNumber(0,math.pi),0);p.Transparency=.85
 table.insert(flecks,p)
end
local accumulator=0
RunService.Heartbeat:Connect(function(dt)
 accumulator+=dt;if accumulator<.1 then return end;accumulator=0
 local now=time()
 for i,g in ipairs(glints) do
  g.part.CFrame=g.base+Vector3.new(math.sin(now*.55+i)*1.3,math.sin(now*.8+i)*.045,0)
  g.part.Transparency=.62+.24*math.sin(now*.9+i*.7)
 end
 for i,b in ipairs(bubbles) do
  local height=math.max(2,C.Surface-b.floor-2)
  local y=b.floor+1+(now*b.speed+b.phase)%height
  b.part.Position=Vector3.new(b.x+math.sin(now*.6+i)*.5,y,b.z+math.cos(now*.5+i)*.5)
 end
 for i,p in ipairs(flecks) do p.Transparency=.83+.12*math.sin(now*1.3+i*.7) end
 local depth=math.clamp((C.Surface-workspace.CurrentCamera.CFrame.Position.Y)/22,0,1)
 tint.TintColor=Color3.new(1,1,1):Lerp(Color3.fromRGB(177,227,225),depth*.2)
 tint.Saturation=-depth*.06;tint.Contrast=depth*.025
end)
