local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local RunService=game:GetService('RunService')
local UIS=game:GetService('UserInputService')
local TweenService=game:GetService('TweenService')
local StarterGui=game:GetService('StarterGui')
local player=Players.LocalPlayer
local C=require(RS:WaitForChild('Pond'):WaitForChild('Config'))
local remotes=RS:WaitForChild('PondRemotes'); local swim=remotes:WaitForChild('Swim')
local fish=workspace:WaitForChild('Fish')
local renderer=require(RS.Pond:WaitForChild('FishRenderer')).new(remotes:WaitForChild('State'),'Player_'..player.UserId)
pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,false); StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health,false); StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat,false) end)
local camera=workspace.CurrentCamera
local gui=Instance.new('ScreenGui'); gui.Name='LittlePond'; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true; gui.Parent=player:WaitForChild('PlayerGui')
local ink=Color3.fromRGB(37,81,78)
local muted=Color3.fromRGB(92,121,107)
local mint=Color3.fromRGB(173,220,168)
local cream=Color3.fromRGB(255,249,228)
local peach=Color3.fromRGB(250,185,151)
local dark=ink
local function create(class,parent,props)
 local obj=Instance.new(class);for k,v in pairs(props) do obj[k]=v end;obj.Parent=parent;return obj
end
local function round(obj,r) create('UICorner',obj,{CornerRadius=UDim.new(0,r or 22)}) end
local function outline(obj) create('UIStroke',obj,{Color=ink,Thickness=2,Transparency=.08,ApplyStrokeMode=Enum.ApplyStrokeMode.Border}) end
local function panel(parent,pos,size)
 local p=create('Frame',parent,{Position=pos,Size=size,BackgroundColor3=cream,BorderSizePixel=0});round(p);outline(p);return p
end
local function label(parent,text,pos,size,fontSize,color,font)
 return create('TextLabel',parent,{BackgroundTransparency=1,Position=pos,Size=size,Text=text,Font=font or Enum.Font.GothamMedium,TextSize=fontSize,TextColor3=color or ink,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center})
end
local function button(parent,text,pos,size,color)
 local b=create('TextButton',parent,{Text=text,Position=pos,Size=size,BackgroundColor3=color or mint,TextColor3=ink,TextSize=16,Font=Enum.Font.FredokaOne,BorderSizePixel=0,AutoButtonColor=true});round(b,18);outline(b);return b
end
local function fishSticker(parent,pos,size,color)
 local f=create('Frame',parent,{Position=pos,Size=UDim2.fromOffset(size,size),BackgroundTransparency=1})
 local tail=create('Frame',f,{Position=UDim2.fromScale(.02,.37),Size=UDim2.fromScale(.3,.3),Rotation=45,BackgroundColor3=color,BorderSizePixel=0});round(tail,5)
 local body=create('Frame',f,{Position=UDim2.fromScale(.17,.2),Size=UDim2.fromScale(.74,.59),BackgroundColor3=color,BorderSizePixel=0});round(body,size/2);outline(body)
 local eye=create('Frame',f,{Position=UDim2.fromScale(.69,.35),Size=UDim2.fromScale(.09,.12),BackgroundColor3=ink,BorderSizePixel=0});round(eye,size)
 local cheek=create('Frame',f,{Position=UDim2.fromScale(.69,.52),Size=UDim2.fromScale(.14,.08),BackgroundColor3=Color3.fromRGB(244,149,141),BorderSizePixel=0});round(cheek,size)
 local bubble=create('Frame',f,{Position=UDim2.fromScale(.95,.12),Size=UDim2.fromScale(.10,.10),BackgroundColor3=cream,BorderSizePixel=0});round(bubble,size);outline(bubble)
 return f,body,tail
end
local root=create('Frame',gui,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1})
local logo=panel(root,UDim2.fromOffset(20,65),UDim2.fromOffset(190,52))
fishSticker(logo,UDim2.fromOffset(6,2),46,mint)
label(logo,'little pond',UDim2.fromOffset(58,4),UDim2.fromOffset(128,44),23,ink,Enum.Font.FredokaOne)
local bookButton=button(root,'Pond book',UDim2.new(1,-147,0,65),UDim2.fromOffset(127,46),cream)
local progress=panel(root,UDim2.new(.5,-190,1,-123),UDim2.fromOffset(380,101));progress.Visible=false
local badge,fishBody,fishTail=fishSticker(progress,UDim2.fromOffset(12,15),68,mint)
local tierLabel=label(progress,'Little minnow',UDim2.fromOffset(92,9),UDim2.fromOffset(270,28),22,ink,Enum.Font.FredokaOne)
local nextLabel=label(progress,'A perch in the making',UDim2.fromOffset(93,39),UDim2.fromOffset(266,18),12,muted)
local track=create('Frame',progress,{Position=UDim2.fromOffset(93,65),Size=UDim2.new(1,-113,0,14),BackgroundColor3=Color3.fromRGB(226,232,202),BorderSizePixel=0});round(track,7)
local fill=create('Frame',track,{Size=UDim2.fromScale(0,1),BackgroundColor3=mint,BorderSizePixel=0});round(fill,7)
local hint=label(root,'',UDim2.new(.5,-200,1,-191),UDim2.fromOffset(400,25),13,cream,Enum.Font.GothamBold);hint.TextXAlignment=Enum.TextXAlignment.Center;hint.TextStrokeColor3=ink;hint.TextStrokeTransparency=.15
local toastPanel=panel(root,UDim2.new(.5,-215,0,135),UDim2.fromOffset(430,65));toastPanel.BackgroundColor3=peach;toastPanel.Visible=false
local toast=label(toastPanel,'',UDim2.fromOffset(12,5),UDim2.new(1,-24,1,-10),20,ink,Enum.Font.FredokaOne);toast.TextWrapped=true;toast.TextXAlignment=Enum.TextXAlignment.Center
local toastUntil=0
local boostButton=button(progress,'Nibble to zoom!',UDim2.fromOffset(93,89),UDim2.new(1,-113,0,32),mint)
local gain=label(root,'',UDim2.new(.5,-90,.55,0),UDim2.fromOffset(180,40),28,cream,Enum.Font.FredokaOne);gain.TextXAlignment=Enum.TextXAlignment.Center;gain.TextStrokeColor3=ink;gain.TextStrokeTransparency=.1
local gainUntil=0
-- Optional book: information is available without surrounding the player with numbers.
local book=panel(root,UDim2.new(.5,-220,.5,-205),UDim2.fromOffset(440,410));book.Visible=false
label(book,'The pond book',UDim2.fromOffset(24,12),UDim2.fromOffset(325,36),27,ink,Enum.Font.FredokaOne)
local closeBook=button(book,'×',UDim2.new(1,-55,0,12),UDim2.fromOffset(36,36),peach)
local pages={}
for _,name in ipairs({'Tips','Friends','Map'}) do pages[name]=create('Frame',book,{Position=UDim2.fromOffset(24,103),Size=UDim2.fromOffset(392,280),BackgroundTransparency=1,Visible=name=='Tips'}) end
local tabs={}
local function showPage(name)
 for key,page in pairs(pages) do page.Visible=key==name;tabs[key].BackgroundColor3=key==name and mint or cream end
end
for i,name in ipairs({'Tips','Friends','Map'}) do
 local b=button(book,name,UDim2.fromOffset(24+(i-1)*132,62),UDim2.fromOffset(124,32),name=='Tips' and mint or cream);tabs[name]=b;b.Activated:Connect(function() showPage(name) end)
end
local tips=label(pages.Tips,'',UDim2.fromOffset(0,0),UDim2.fromOffset(392,98),16,ink);tips.TextWrapped=true;tips.TextYAlignment=Enum.TextYAlignment.Top
local controlText=UIS.TouchEnabled and 'Left / right: turn. Forward / back: paddle.\nUp for a peek. Down for a snack.' or UIS.GamepadEnabled and 'Left stick: steer / paddle  •  Right stick: look\nShoulder buttons: rise / dive' or 'A / D: turn   •   W / S: forward / reverse\nSpace / E: rise   •   Q: dive\nRight mouse: look   •   Scroll: zoom'
label(pages.Tips,'A little fin-holding',UDim2.fromOffset(0,114),UDim2.fromOffset(392,28),21,ink,Enum.Font.FredokaOne)
label(pages.Tips,controlText,UDim2.fromOffset(0,148),UDim2.fromOffset(392,75),14,muted)
label(pages.Tips,'Tab opens this book. Close it to keep swimming.',UDim2.fromOffset(0,248),UDim2.fromOffset(392,24),11,muted)
local scoreLabel=label(pages.Friends,'',UDim2.fromOffset(0,0),UDim2.fromOffset(392,28),19,ink,Enum.Font.FredokaOne)
local populationLabel=label(pages.Friends,'',UDim2.fromOffset(0,32),UDim2.fromOffset(392,24),12,muted)
label(pages.Friends,'Big appetites around here',UDim2.fromOffset(0,70),UDim2.fromOffset(392,24),16,ink,Enum.Font.FredokaOne)
local rows={}
for i=1,5 do rows[i]=label(pages.Friends,'',UDim2.fromOffset(0,102+(i-1)*29),UDim2.fromOffset(392,25),14,ink) end
local map=create('Frame',pages.Map,{Position=UDim2.fromOffset(91,0),Size=UDim2.fromOffset(210,210),BackgroundColor3=Color3.fromRGB(203,231,211),BorderSizePixel=0});round(map,28)
for i=0,47 do
 local a,b=i*math.pi/24,(i+1)*math.pi/24
 local x1,z1=math.cos(a)*C.shoreRadius(a),math.sin(a)*C.shoreRadius(a)
 local x2,z2=math.cos(b)*C.shoreRadius(b),math.sin(b)*C.shoreRadius(b)
 local dx,dz=(x2-x1)*210/(C.Radius*2),(z2-z1)*210/(C.Radius*2)
 create('Frame',map,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5+(x1+x2)/2/(C.Radius*2),.5+(z1+z2)/2/(C.Radius*2)),Size=UDim2.fromOffset(math.sqrt(dx*dx+dz*dz)+1,2),Rotation=math.deg(math.atan2(dz,dx)),BackgroundColor3=ink,BorderSizePixel=0})
end
local legend=label(pages.Map,'Dark dot: you   •   Coral: watch out!\nGreen dots: pond pals. Map shows position, not depth.',UDim2.fromOffset(0,224),UDim2.fromOffset(392,50),12,muted);legend.TextXAlignment=Enum.TextXAlignment.Center;legend.TextWrapped=true
local dots={}
local playing=false
local function toggleBook()
 if not playing then return end
 book.Visible=not book.Visible
end
bookButton.Activated:Connect(toggleBook);closeBook.Activated:Connect(function() book.Visible=false end)
local tutorial=panel(root,UDim2.new(.5,-210,.5,-175),UDim2.fromOffset(420,350))
fishSticker(tutorial,UDim2.fromOffset(161,5),98,mint)
local greeting=label(tutorial,'Small fry. Big dreams.',UDim2.fromOffset(20,111),UDim2.fromOffset(380,40),29,ink,Enum.Font.FredokaOne);greeting.TextXAlignment=Enum.TextXAlignment.Center
local intro=label(tutorial,'Find a leafy snack on the pond floor.\nNibble, grow, and see who you become!',UDim2.fromOffset(24,163),UDim2.fromOffset(372,54),16,muted);intro.TextXAlignment=Enum.TextXAlignment.Center
local start=button(tutorial,'Let’s make a splash!',UDim2.fromOffset(32,243),UDim2.fromOffset(356,52),mint)
local foot=label(tutorial,'Bigger fish are hungry too. Little fins, keep moving!',UDim2.fromOffset(20,309),UDim2.fromOffset(380,22),11,muted);foot.TextXAlignment=Enum.TextXAlignment.Center
local function requestBoost()
 if playing and not book.Visible then remotes.Boost:FireServer() end
end
boostButton.Activated:Connect(requestBoost)
local function begin() if playing then return end;playing=true;tutorial.Visible=false;progress.Visible=true;remotes.Begin:FireServer() end
start.Activated:Connect(begin)
local keys={}; local touch={}; local stick=Vector2.zero; local orbit=0; local zoom=1; local dragging=false
UIS.InputBegan:Connect(function(i,processed)
 if processed then return end
 keys[i.KeyCode]=true
 if i.KeyCode==Enum.KeyCode.LeftShift or i.KeyCode==Enum.KeyCode.RightShift or i.KeyCode==Enum.KeyCode.ButtonX then requestBoost() end
 if i.KeyCode==Enum.KeyCode.Tab or i.KeyCode==Enum.KeyCode.ButtonY then toggleBook() end
 if i.KeyCode==Enum.KeyCode.Return or i.KeyCode==Enum.KeyCode.ButtonA then begin() end
 if i.UserInputType==Enum.UserInputType.MouseButton2 then dragging=true end
end)
UIS.InputEnded:Connect(function(i)
 keys[i.KeyCode]=nil
 if i.UserInputType==Enum.UserInputType.MouseButton2 then dragging=false end
end)
UIS.WindowFocusReleased:Connect(function() keys={}; touch={}; stick=Vector2.zero; dragging=false end)
UIS.InputChanged:Connect(function(i)
 if i.UserInputType==Enum.UserInputType.MouseWheel then zoom=math.clamp(zoom-i.Position.Z*.08,.65,1.9) end
 if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then orbit-=i.Delta.X*.007 end
 if i.KeyCode==Enum.KeyCode.Thumbstick1 then stick=Vector2.new(i.Position.X,i.Position.Y); if stick.Magnitude<.15 then stick=Vector2.zero end end
 if i.KeyCode==Enum.KeyCode.Thumbstick2 then orbit-=i.Position.X*.055 end
end)
local function held(...) for _,k in ipairs({...}) do if keys[k] then return 1 end end return 0 end
if UIS.TouchEnabled then
 local touchPanel=create('Frame',root,{Position=UDim2.new(0,20,1,-300),Size=UDim2.fromOffset(180,150),BackgroundTransparency=1})
 for _,spec in ipairs({{'↑',60,0,'forward'},{'↓',60,96,'back'},{'←',5,48,'left'},{'→',115,48,'right'}}) do
  local b=create('TextButton',touchPanel,{Position=UDim2.fromOffset(spec[2],spec[3]),Size=UDim2.fromOffset(52,48),Text=spec[1],TextSize=24,BackgroundColor3=cream,TextColor3=ink,BackgroundTransparency=.2,BorderSizePixel=0}); round(b,14)
  b.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then touch[spec[4]]=true end end)
  b.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then touch[spec[4]]=nil end end)
 end
 for n,spec in ipairs({{'RISE','up'},{'DIVE','down'}}) do
  local b=create('TextButton',root,{Position=UDim2.new(1,-98,1,-320+n*62),Size=UDim2.fromOffset(72,54),Text=spec[1],TextSize=12,Font=Enum.Font.GothamBold,BackgroundColor3=dark,TextColor3=mint,BorderSizePixel=0}); round(b,16)
  b.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then touch[spec[2]]=true end end)
  b.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then touch[spec[2]]=nil end end)
 end
end
remotes.Notice.OnClientEvent:Connect(function(message,kind)
 if not playing then return end
 if kind=='eat' then
  local words={'nom nom!','delish!','nice nibble!','yum!'}
  gain.Text=words[math.random(1,#words)];gainUntil=time()+.7
 else
  toast.Text=kind=='respawn' and 'Oops! Little fins, fresh start.' or 'Look at you grow! Hello, '..C.Tiers[player:GetAttribute('Tier') or 1].name..'!'
  toastPanel.Visible=true;toastUntil=time()+3.5
 end
end)
local uiTimer=0;local sendTimer=0;local focus=nil;local lastProgress=-1
local nicknames={'Little minnow','Peppy perch','Lovely bass','Zoomy tuna','Dashing marlin','Cheeky shark','Wonderful whale'}
local function updateUI(m)
 local tier=player:GetAttribute('Tier') or 1;local growth=player:GetAttribute('Growth') or 0;local score=player:GetAttribute('Score') or 0
 tierLabel.Text=nicknames[tier];fishBody.BackgroundColor3=C.Tiers[tier].color;fishTail.BackgroundColor3=C.Tiers[tier].color
 local fraction=math.clamp((growth-C.Tiers[tier].threshold)/C.progressSpan(tier),0,1)
 local boosting=(player:GetAttribute('BoostUntil') or 0)>workspace:GetServerTimeNow()
 local available=growth-C.Tiers[tier].threshold>=C.boostCost(tier)
 local shortcut=UIS.TouchEnabled and '' or UIS.GamepadEnabled and ' · X' or ' · Shift'
 boostButton.Text=boosting and 'Whoooosh!' or available and ('Zoom! '..shortcut) or 'Nibble to zoom!'
 boostButton.BackgroundColor3=available and mint or Color3.fromRGB(226,232,202)
 boostButton.AutoButtonColor=available and not boosting
 boostButton.Active=available and not boosting
 if tier<7 then
  local base=C.Tiers[tier].threshold;local goal=C.Tiers[tier+1].threshold
  fraction=math.clamp((growth-base)/(goal-base),0,1)
  nextLabel.Text=fraction>.8 and 'Nearly a '..C.Tiers[tier+1].name:lower()..'! Keep nibbling.' or 'Next little adventure: '..C.Tiers[tier+1].name
 else
  nextLabel.Text='Whale power: '..math.floor(score)..' • higher score wins'
 end
 if math.abs(fraction-lastProgress)>.001 then
  lastProgress=fraction;TweenService:Create(fill,TweenInfo.new(.25),{Size=UDim2.fromScale(fraction,1)}):Play()
 end
 scoreLabel.Text='Your happy haul: '..math.floor(score)..' points'
 populationLabel.Text='A pond full of pals. Dots after names mean bots.'
 tips.Text=tier==1 and 'Leafy snacks first! Swim down and brush past the green seaweed to grow.' or tier==7 and 'Big fish energy! You can eat whales with fewer points than you. Equal scores? Swim as pals.' or 'Smaller fish are on the menu! Swim into them for a snack. Tiny bites and seaweed help a little less.'
 tips.Text..='\n\nZoom spends a little bar. Your tier and points stay!' 
 if book.Visible then
  local all=fish:GetChildren();table.sort(all,function(a,b) return (a:GetAttribute('Score') or 0)>(b:GetAttribute('Score') or 0) end)
  for i,row in ipairs(rows) do
   local a=all[i];row.Text=a and string.format('%s%s     %d',string.sub(a:GetAttribute('DisplayName') or '',1,19),a:GetAttribute('Bot') and ' ·' or '',math.floor(a:GetAttribute('Score') or 0)) or ''
  end
  for id,d in pairs(dots) do if not fish:FindFirstChild(id) then d:Destroy();dots[id]=nil end end
  for _,a in ipairs(all) do if a.PrimaryPart then
   local d=dots[a.Name]
   if not d then d=create('Frame',map,{Size=UDim2.fromOffset(6,6),BorderSizePixel=0,AnchorPoint=Vector2.new(.5,.5)});round(d,5);dots[a.Name]=d end
   local p=a.PrimaryPart.Position;d.Position=UDim2.fromScale(.5+p.X/(C.Radius*2),.5+p.Z/(C.Radius*2))
   d.BackgroundColor3=a==m and ink or C.canEat({tier=a:GetAttribute('Tier') or 1,score=a:GetAttribute('Score') or 0},{tier=tier,score=score}) and Color3.fromRGB(226,116,106) or Color3.fromRGB(93,164,112)
   d.Size=UDim2.fromOffset(a==m and 9 or 5,a==m and 9 or 5)
  end end
 end
 hint.Text=not playing and '' or m and m:GetAttribute('Protected') and 'A little breathing room. You’re safe for a moment.' or tier==1 and 'Psst… the leafy snacks are down below.' or ''
 hint.Visible=not book.Visible;progress.Visible=playing and not book.Visible;bookButton.Visible=playing
 local w,h=root.AbsoluteSize.X,root.AbsoluteSize.Y
 local width=math.min(380,w-28);progress.Size=UDim2.fromOffset(width,137);progress.Position=UDim2.new(.5,-width/2,1,-159)
 tierLabel.Size=UDim2.fromOffset(width-108,28);tierLabel.TextSize=width<340 and 19 or 22
 nextLabel.Size=UDim2.fromOffset(width-108,18);nextLabel.TextSize=width<340 and 10 or 12
 for _,spec in ipairs({{tutorial,420,350},{book,440,410},{toastPanel,430,65}}) do
  local panel,sw,sh=spec[1],spec[2],spec[3]
  local scale=math.min(1,(w-28)/sw,(h-110)/sh)
  local u=panel:FindFirstChildOfClass('UIScale') or create('UIScale',panel,{Scale=scale});u.Scale=scale
  if panel==toastPanel then panel.Position=UDim2.new(.5,-sw*scale/2,0,130)
  else panel.Position=UDim2.new(.5,-sw*scale/2,.5,-sh*scale/2+20) end
 end
 hint.Size=UDim2.fromOffset(math.min(w-28,400),25);hint.Position=UDim2.new(.5,-math.min(w-28,400)/2,1,-191)
end
RunService.RenderStepped:Connect(function(dt)
 camera=workspace.CurrentCamera; camera.CameraType=Enum.CameraType.Scriptable
  local x=held(Enum.KeyCode.D,Enum.KeyCode.Right)-held(Enum.KeyCode.A,Enum.KeyCode.Left)+(touch.right and 1 or 0)-(touch.left and 1 or 0)+stick.X
  local z=held(Enum.KeyCode.W,Enum.KeyCode.Up)-held(Enum.KeyCode.S,Enum.KeyCode.Down)+(touch.forward and 1 or 0)-(touch.back and 1 or 0)+stick.Y
  local y=held(Enum.KeyCode.Space,Enum.KeyCode.E,Enum.KeyCode.ButtonR1)-held(Enum.KeyCode.Q,Enum.KeyCode.LeftControl,Enum.KeyCode.ButtonL1)+(touch.up and 1 or 0)-(touch.down and 1 or 0)
  local v=Vector3.new(math.clamp(x,-1,1),math.clamp(y,-1,1),math.clamp(z,-1,1))
  local controls=playing and not book.Visible and v or Vector3.zero
  sendTimer+=dt
  if sendTimer>=.05 then sendTimer=0; swim:FireServer(controls) end
 local renderPosition=renderer:update(dt,controls)
 local m=fish:FindFirstChild('Player_'..player.UserId)
 if m and m.PrimaryPart then
  local p=renderPosition or m.PrimaryPart.Position
  focus=p
  local size=C.Tiers[player:GetAttribute('Tier') or 1].size
  local distance=(37+size*1.7)*zoom
  local offset=Vector3.new(math.sin(orbit)*distance,distance*.9,math.cos(orbit)*distance)
  camera.CFrame=CFrame.lookAt(focus+offset,focus); camera.FieldOfView=62

 end
 uiTimer+=dt; if uiTimer>.15 then uiTimer=0; updateUI(m) end
 if time()>toastUntil then toastPanel.Visible=false end
 if time()>gainUntil then gain.Text='' end
end)
print('LITTLE POND: client ready. Keyboard, touch and gamepad controls online.')
