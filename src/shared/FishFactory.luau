local C = require(script.Parent.Config)
local F = {}
local function part(model, name, size, cf, color, shape)
 local p=Instance.new(shape=='Wedge' and 'WedgePart' or 'Part')
 p.Name=name; p.Size=size; p.CFrame=cf; p.Color=color
 p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false
 p.Material=Enum.Material.SmoothPlastic
 p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
 if shape=='Ball' then p.Shape=Enum.PartType.Ball end
 p.Parent=model
 return p
end
-- Build a flat-shaded triangle from two wedge prisms: no uploaded meshes needed.
local function triangle(model,a,b,c,color)
 local ab,ac,bc=b-a,c-a,c-b
 if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then c,a=a,c
 elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
 ab,ac,bc=b-a,c-a,c-b
 local right=ac:Cross(ab).Unit; local back=bc.Unit; local up=bc:Cross(right).Unit
 local h=math.abs(ab:Dot(up))
 part(model,'Facet',Vector3.new(.035,h,math.max(.01,math.abs(ab:Dot(back)))),CFrame.fromMatrix((a+b)/2,right,up,back),color,'Wedge')
 part(model,'Facet',Vector3.new(.035,h,math.max(.01,math.abs(ac:Dot(back)))),CFrame.fromMatrix((a+c)/2,-right,up,-back),color,'Wedge')
end
function F.create(id, tier, name, isBot)
 local t=C.Tiers[tier]; local s=t.size
 local m=Instance.new('Model'); m.Name=id
 local color=t.color; local cream=Color3.fromRGB(244,242,205)
 local body=part(m,'Body',Vector3.new(s*.65,s*.72,s*1.5),CFrame.new(),color,'Ball')
 m.PrimaryPart=body; body.Transparency=1
 local width=tier==7 and .41 or .325
 -- A short, rounded snout ring softens the former needle-shaped head.
 for i=0,7 do
  local a=i*math.pi/4; local b=(i+1)*math.pi/4
  local p=Vector3.new(math.cos(a)*s*width,math.sin(a)*s*.36,0)
  local q=Vector3.new(math.cos(b)*s*width,math.sin(b)*s*.36,0)
  local noseWidth=tier==7 and .8 or .58
  local np=Vector3.new(p.X*noseWidth,p.Y*.64,-s*.43)
  local nq=Vector3.new(q.X*noseWidth,q.Y*.64,-s*.43)
  local shade=math.sin((a+b)/2)<-.35 and cream or color:Lerp(cream,(i%3)*.065)
  triangle(m,np,p,q,shade);triangle(m,np,q,nq,shade)
  triangle(m,Vector3.new(0,0,-s*.66),np,nq,shade)
  triangle(m,Vector3.new(0,0,s*.75),q,p,shade)
 end
 local tailColor=color:Lerp(cream,.18)
 if tier==7 then
  for _,side in ipairs({-1,1}) do
   triangle(m,Vector3.new(0,0,s*.7),Vector3.new(side*s*.57,.02,s*1.07),Vector3.new(side*s*.13,.02,s*1.12),tailColor)
  end
 else
  for _,side in ipairs({-1,1}) do
   triangle(m,Vector3.new(0,0,s*.66),Vector3.new(0,side*s*.43,s*1.06),Vector3.new(0,side*s*.04,s*.98),tailColor)
  end
 end
 for _,side in ipairs({-1,1}) do
  part(m,'Fin',Vector3.new(s*.46,s*.09,s*.48),CFrame.new(side*s*.42,-s*.1,s*.1)*CFrame.Angles(0,side*-.42,side*.22),color:Lerp(cream,.2),'Wedge')
  part(m,'EyeWhite',Vector3.new(s*.13,s*.24,s*.24),CFrame.new(side*s*(tier==7 and .36 or .275),s*.10,-s*.26),Color3.new(1,1,1),'Ball')
  part(m,'Eye',Vector3.new(s*.075,s*.13,s*.13),CFrame.new(side*s*(tier==7 and .42 or .335),s*.10,-s*.28),Color3.fromRGB(24,44,61),'Ball')
  part(m,'EyeSparkle',Vector3.new(s*.025,s*.045,s*.045),CFrame.new(side*s*(tier==7 and .457 or .372),s*.13,-s*.30),Color3.new(1,1,1),'Ball')
 end
 for _,side in ipairs({-1,1}) do
  part(m,'Rosy cheek',Vector3.new(s*.035,s*.09,s*.13),CFrame.new(side*s*(tier==7 and .37 or .28),-s*.015,-s*.32),Color3.fromRGB(236,157,139),'Ball')
 end
 if tier>=2 then
  part(m,'Dorsal',Vector3.new(s*.1,s*(tier==5 and .8 or .36),s*.62),CFrame.new(0,s*.43,s*.03),color:Lerp(Color3.fromRGB(25,68,97),.22),'Wedge')
 end
 if tier==2 or tier==3 then
  for z=-1,1 do
   for _,side in ipairs({-1,1}) do
    part(m,'Stripe',Vector3.new(s*.025,s*.42,s*.085),CFrame.new(side*s*(z==0 and .328 or z==1 and .231 or .273),0,z*s*.23)*CFrame.Angles(0,side*(z==1 and -.41 or .29),0),color:Lerp(Color3.fromRGB(29,78,71),.4))
   end
  end
 end
 if tier==5 then part(m,'Bill',Vector3.new(s*.11,s*.1,s*.9),CFrame.new(0,0,-s*1.04),color,'Wedge') end
 if tier==6 then
  for _,side in ipairs({-1,1}) do
   for i=1,3 do part(m,'Gill',Vector3.new(s*.03,s*.2,s*.035),CFrame.new(side*s*.318,0,-s*.12+i*s*.08),Color3.fromRGB(47,79,102)) end
  end
 end
 if tier==7 then
  part(m,'Blowhole',Vector3.new(s*.12,s*.02,s*.14),CFrame.new(0,s*.318,-s*.11),Color3.fromRGB(58,76,119),'Ball')
  for i=-2,2 do part(m,'ThroatPleat',Vector3.new(s*.025,s*.02,s*.58),CFrame.new(i*s*.075,-s*.365,-s*.16),Color3.fromRGB(193,202,227)) end
 end
 local tag=Instance.new('BillboardGui'); tag.Name='Nameplate'; tag.Size=UDim2.fromOffset(190,40)
 tag.StudsOffset=Vector3.new(0,s*.65+1,0); tag.AlwaysOnTop=false; tag.MaxDistance=75; tag.Parent=body
 local txt=Instance.new('TextLabel'); txt.Name='Label'; txt.Size=UDim2.fromScale(1,1); txt.BackgroundTransparency=1
 txt.Font=Enum.Font.GothamBold; txt.TextSize=12; txt.TextColor3=Color3.fromRGB(246,255,249)
 txt.TextStrokeColor3=Color3.fromRGB(23,66,74); txt.TextStrokeTransparency=.3
 txt.Text=name..(isBot and ' · BOT' or ''); txt.Parent=tag
 m:SetAttribute('Tier',tier); m:SetAttribute('Bot',isBot); m:SetAttribute('DisplayName',name)
 return m
end
return F
