local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local RunService=game:GetService('RunService')
local C=require(RS.Pond.Config)
local Swimming=require(RS.Pond.Swimming)
local BotBrain=require(RS.Pond.BotBrain)
Players.CharacterAutoLoads=false
local remotes=Instance.new('Folder'); remotes.Name='PondRemotes'; remotes.Parent=RS
local input=Instance.new('RemoteEvent'); input.Name='Swim'; input.Parent=remotes
local begin=Instance.new('RemoteEvent'); begin.Name='Begin'; begin.Parent=remotes
local boost=Instance.new('RemoteEvent'); boost.Name='Boost'; boost.Parent=remotes
local state=Instance.new('RemoteEvent'); state.Name='State'; state.Parent=remotes
local notice=Instance.new('RemoteEvent'); notice.Name='Notice'; notice.Parent=remotes
local fish=Instance.new('Folder'); fish.Name='Fish'; fish.Parent=workspace
local food=Instance.new('Folder'); food.Name='Seaweed'; food.Parent=workspace
local actors={}; local weeds={}; local serial=0; local elapsed=0
local rng=Random.new(81723)
local botNames={'Bubbles','Pickle','Nori','Pebble','Waffles','Sprout','Pip','Miso','Doodle','Clover','Bean','Mochi','Puddle','Olive','Noodle','Biscuit','Tofu','Guppy','Pesto','Finley'}
local function randomPosition(bottom)
 local a=rng:NextNumber(0,math.pi*2); local r=math.sqrt(rng:NextNumber())*(C.shoreRadius(a)*.87-18)
 local x,z=math.cos(a)*r,math.sin(a)*r
 local bed=C.floorHeight(x,z)
 return Vector3.new(x,bottom and bed+4 or rng:NextNumber(bed+5,math.max(bed+6,32)),z)
end
local function sync(a)
 if a.player then a.player:SetAttribute('BoostUntil',a.boostUntil or 0) end
 a.model:SetAttribute('Score',a.score); a.model:SetAttribute('Growth',a.growth)
 a.model:SetAttribute('Protected',a.safe>elapsed)
 if a.player then
  a.player:SetAttribute('Tier',a.tier); a.player:SetAttribute('Growth',a.growth); a.player:SetAttribute('Score',a.score)
  a.player.leaderstats.Score.Value=math.floor(a.score)
  a.player.leaderstats.Fish.Value=C.Tiers[a.tier].name
 end
end
local function build(a)
 if a.model then a.model:Destroy() end
 a.generation=(a.generation or 0)+1
 -- Only one invisible position marker replicates; detailed art is rendered locally.
 a.model=Instance.new('Model'); a.model.Name=a.id
 local body=Instance.new('Part'); body.Name='Body'; body.Size=Vector3.one
 body.Anchored=true; body.Transparency=1; body.CanCollide=false; body.CanTouch=false; body.CanQuery=false
 body.Parent=a.model; a.model.PrimaryPart=body
 a.model:SetAttribute('Tier',a.tier); a.model:SetAttribute('Bot',a.player==nil)
 a.model:SetAttribute('DisplayName',a.name); a.model.Parent=fish
 a.model:PivotTo(CFrame.lookAt(a.pos,a.pos+a.facing)); sync(a)
end
local function safePosition()
 local best=randomPosition(true); local bestDistance=-1
 for _=1,24 do
  local p=randomPosition(true); local nearest=math.huge
  for _,a in pairs(actors) do if a.tier>1 then nearest=math.min(nearest,(a.pos-p).Magnitude) end end
  if nearest>bestDistance then best=p; bestDistance=nearest end
 end
 return best
end
local function spawn(id,player,tier)
 local growth=C.Tiers[tier or 1].threshold
 local a={id=id,player=player,name=player and player.DisplayName or botNames[(serial-1)%#botNames+1],tier=tier or 1,
  growth=growth,score=growth,pos=C.clampPosition(safePosition(),C.Tiers[tier or 1].size),facing=Vector3.new(0,0,-1),velocity=Vector3.zero,
  phase=rng:NextNumber(0,math.pi*2),boostRemaining=0,boostUntil=0,boostPacketAt=-1,bank=0,ready=player==nil,intent=Vector3.zero,lastInput=0,packetAt=-1,safe=elapsed+C.SpawnProtection,think=0}
 actors[id]=a; build(a); return a
end
local function population()
 local count=0; for _ in pairs(actors) do count+=1 end
 workspace:SetAttribute('Population',count)
 workspace:SetAttribute('Humans',#Players:GetPlayers())
end
local function fillBots()
 local count=0; for _ in pairs(actors) do count+=1 end
 while count<C.Capacity do
  serial+=1; local tier=1
  -- Maintain an approachable ecosystem, including a few advanced fish.
  if serial%20==0 then tier=7 elseif serial%13==0 then tier=6 elseif serial%9==0 then tier=5 elseif serial%7==0 then tier=4 elseif serial%4==0 then tier=3 elseif serial%3==0 then tier=2 end
  spawn('Bot_'..serial,nil,tier); count+=1
 end
 population()
end
local function addPlayer(p)
 if actors['Player_'..p.UserId] then return end
 local humanCount=0; for _,a in pairs(actors) do if a.player then humanCount+=1 end end
 if humanCount>=C.Capacity then p:Kick('This pond is full. Please join another server.'); return end
 for id,a in pairs(actors) do if not a.player then a.model:Destroy(); actors[id]=nil; break end end
 local stats=Instance.new('Folder'); stats.Name='leaderstats'; stats.Parent=p
 local score=Instance.new('IntValue'); score.Name='Score'; score.Parent=stats
 local tier=Instance.new('StringValue'); tier.Name='Fish'; tier.Parent=stats
 spawn('Player_'..p.UserId,p,1); fillBots()
end
local function reward(a,preyTier)
 local gain=C.reward(a.tier,preyTier)
 a.score+=gain; a.growth+=gain
 local tier=C.tierFor(a.growth)
 if tier==#C.Tiers then a.growth=math.min(a.growth,C.Tiers[tier].threshold+C.progressSpan(tier)) end
 if tier~=a.tier then
  a.tier=tier; a.pos=C.clampPosition(a.pos,C.Tiers[tier].size); build(a)
  if a.player then notice:FireClient(a.player,'EVOLVED INTO '..string.upper(C.Tiers[tier].name),'evolve') end
 end
 sync(a)
 if a.player then notice:FireClient(a.player,'+'..string.format('%.1f',gain), 'eat') end
end
local function eaten(a,by)
 if a.player then notice:FireClient(a.player,by.name..' ate you! Back to minnow — score kept.','respawn') end
 a.tier=1; a.growth=0; a.pos=safePosition(); a.velocity=Vector3.zero; a.intent=Vector3.zero
 a.boostRemaining=0; a.boostUntil=0
 a.yaw=nil; a.facing=Vector3.new(0,0,-1)
 a.safe=elapsed+C.SpawnProtection; a.bank=0; BotBrain.reset(a); build(a)
end
for i=1,C.SeaweedCount do
 local seed=randomPosition(true)
 local pos=Vector3.new(seed.X,C.floorHeight(seed.X,seed.Z)+2.7,seed.Z)
 local model=Instance.new('Model'); model.Name='Seaweed_'..i
 for j=-1,1 do
  local p=Instance.new('WedgePart'); p.Name='Leaf'; p.Anchored=true; p.CanCollide=false; p.CanTouch=false
  p.Size=Vector3.new(.5,2.7+math.abs(j)*.5,1.25); p.Color=j==0 and Color3.fromRGB(162,220,105) or Color3.fromRGB(60,172,127)
  p.Material=Enum.Material.SmoothPlastic; p.CFrame=CFrame.new(pos+Vector3.new(j*.65,-1.3,0))*CFrame.Angles(0,j*.9,j*-.3); p.Parent=model
 end
 model.Parent=food; weeds[i]={pos=pos,model=model,ready=0}
end
local function setFood(w,visible)
 for _,p in ipairs(w.model:GetChildren()) do p.Transparency=visible and 0 or 1 end
end
begin.OnServerEvent:Connect(function(p)
 local a=actors['Player_'..p.UserId]
 if a and not a.ready then a.ready=true; a.safe=elapsed+C.SpawnProtection end
end)
input.OnServerEvent:Connect(function(p,v)
 local a=actors['Player_'..p.UserId]; if not a or typeof(v)~='Vector3' then return end
 if v.X~=v.X or v.Y~=v.Y or v.Z~=v.Z or math.abs(v.X)>1.01 or math.abs(v.Y)>1.01 or math.abs(v.Z)>1.01 then return end
 if elapsed-a.packetAt<.035 then return end
 a.packetAt=elapsed; a.intent=a.ready and v or Vector3.zero; a.lastInput=elapsed
end)
boost.OnServerEvent:Connect(function(p)
 local a=actors['Player_'..p.UserId]
 if not a or elapsed-a.boostPacketAt<.15 then return end
 a.boostPacketAt=elapsed
 if C.tryBoost(a) then
  a.boostUntil=workspace:GetServerTimeNow()+C.BoostDuration
  sync(a); notice:FireClient(p,'Whoooosh!','boost')
 end
end)
local function botThink(a)
 BotBrain.update(a,actors,weeds,elapsed)
 a.model:SetAttribute('Behavior',a.brain.mode)
end
local function canContact(a,b)
 return (a.pos-b.pos).Magnitude < (C.Tiers[a.tier].size+C.Tiers[b.tier].size)*.52
end
local function resolveContact(a,b)
 if a.safe<=elapsed and b.safe<=elapsed and canContact(a,b) then
  if C.canEat(a,b) then local tier=b.tier; eaten(b,a); reward(a,tier)
  elseif C.canEat(b,a) then local tier=a.tier; eaten(a,b); reward(b,tier) end
 end
end
local accumulator=0
local function step(dt)
 elapsed+=dt
 local list={}; for _,a in pairs(actors) do table.insert(list,a) end
 for _,a in ipairs(list) do
  if not a.ready then a.safe=elapsed+C.SpawnProtection end
  if not a.player then
   a.think-=dt; if a.think<=0 then a.think=.25+rng:NextNumber(0,.15); botThink(a) end
  elseif elapsed-a.lastInput>.6 then a.intent=Vector3.zero end
  if a.player then Swimming.tank(a,dt) else Swimming.update(a,dt,elapsed) end
  -- Avoid lookAt degeneracy for exactly vertical swimming.
  local up=math.abs(a.facing.Y)>.97 and Vector3.xAxis or Vector3.yAxis
  local sway=math.sin(elapsed*4.2+a.phase)*.028*math.min(1,a.velocity.Magnitude/10)
  a.model:PivotTo(CFrame.lookAt(a.pos,a.pos+a.facing,up)*CFrame.Angles(0,sway,a.bank))
  a.model:SetAttribute('Protected',a.safe>elapsed)
 end
 for _,w in ipairs(weeds) do
  if w.ready>0 and w.ready<=elapsed then w.ready=0; setFood(w,true) end
  if w.ready==0 then
   for _,a in ipairs(list) do
    if a.ready and (a.pos-w.pos).Magnitude<C.Tiers[a.tier].size*.55+2 then
     w.ready=elapsed+C.SeaweedRespawn; setFood(w,false); reward(a,0); break
    end
   end
  end
 end
 for i=1,#list-1 do for j=i+1,#list do
  local a,b=list[i],list[j]
  resolveContact(a,b)
 end end
 -- Timestamped full snapshots also handle joins, respawns and tier changes.
 local packet={}
 for _,a in pairs(actors) do
  table.insert(packet,{id=a.id,name=a.name,bot=a.player==nil,tier=a.tier,generation=a.generation,
   pos=a.pos,velocity=a.velocity,facing=a.facing,yaw=a.yaw,bank=a.bank,phase=a.phase,boostRemaining=a.boostRemaining})
 end
 state:FireAllClients(workspace:GetServerTimeNow(),packet)
end
Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(function(p)
 local id='Player_'..p.UserId; local a=actors[id]
 if a then a.model:Destroy(); actors[id]=nil end
 task.defer(fillBots)
end)
for _,p in ipairs(Players:GetPlayers()) do addPlayer(p) end
fillBots()
RunService.Heartbeat:Connect(function(dt)
 accumulator+=math.min(dt,.2)
 while accumulator>=.05 do accumulator-=.05; step(.05) end
end)
if RunService:IsStudio() then
 require(game.ServerStorage.PondTests)()
 -- Engine integration checks exercise the real mutation and collision code.
 local bots={}; for _,a in pairs(actors) do if not a.player then table.insert(bots,a) end end
 if #bots>=2 then
  local a,b=bots[1],bots[2]; local savedA,savedB=table.clone(a),table.clone(b)
  a.tier=1; a.growth=0; a.score=0
  for _=1,8 do reward(a,0) end
  assert(a.tier==2 and a.growth==8,'eight seaweeds evolve minnow')
  eaten(a,b); assert(a.tier==1 and a.growth==0 and a.score==8,'respawn preserves accumulated score')
  a.tier=7; a.growth=550; a.score=1000; a.safe=-1; a.pos=Vector3.new(0,20,0); build(a)
  b.tier=7; b.growth=550; b.score=1000; b.safe=-1; b.pos=a.pos; build(b)
  resolveContact(a,b); assert(a.tier==7 and b.tier==7,'equal whales cannot eat each other')
  a.score=1001; b.safe=elapsed+5; resolveContact(a,b); assert(b.tier==7,'spawn protection blocks predation')
  b.safe=-1; resolveContact(a,b); assert(b.tier==1 and b.score==1000 and a.score>1001,'higher-score whale eats lower whale')
  a.tier=1; a.growth=0; a.score=0; a.safe=elapsed+5; a.pos=weeds[1].pos; a.intent=Vector3.zero; a.velocity=Vector3.zero; a.think=1e6; build(a)
  step(0); assert(a.growth>=1 and weeds[1].ready>elapsed,'contact eats seaweed')
  a.pos=Vector3.new(0,20,0); a.intent=Vector3.xAxis; a.velocity=Vector3.zero; step(.05)
  assert(a.velocity.Magnitude>0 and (a.pos-Vector3.new(0,20,0)).Magnitude>0,'server integrates swimming')
  for k,v in pairs(savedA) do if k~='model' then a[k]=v end end
  for k,v in pairs(savedB) do if k~='model' then b[k]=v end end
  build(a); build(b)
  for _,w in ipairs(weeds) do w.ready=0; setFood(w,true) end
  local id=b.id; b.model:Destroy(); actors[id]=nil; fillBots()
  assert(#fish:GetChildren()==20,'bot replacement restores population')
  print('LITTLE POND INTEGRATION PASSED: evolution, score retention, whale collision, ties, protection, feeding, movement, bot replacement')
 end
end
print('LITTLE POND: server ready. '..C.Capacity..' fish, authoritative swimming, infinite ecosystem.')
