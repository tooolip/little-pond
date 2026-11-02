-- Client-only visuals. Gameplay remains authoritative on the server.
local F=require(script.Parent.FishFactory)
local S=require(script.Parent.Swimming)
local C=require(script.Parent.Config)
local R={}
function R.new(remote,ownId)
 local folder=Instance.new('Folder'); folder.Name='FishVisuals'; folder.Parent=workspace
 local entries={}; local history={}; local input=Vector3.zero
 local function simulate(a,duration)
  -- Bound catch-up after a stalled frame or connection.
  local remaining=math.clamp(duration,0,.25)
  while remaining>0 do local dt=math.min(remaining,1/60); S.tank(a,dt); remaining-=dt end
 end
 remote.OnClientEvent:Connect(function(stamp,packet)
  local now=workspace:GetServerTimeNow(); local present={}
  for _,snapshot in ipairs(packet) do
   local id=snapshot.id; present[id]=true
   local e=entries[id]
   if e and e.generation~=snapshot.generation then e.model:Destroy(); entries[id]=nil; e=nil end
   if not e then
    e={model=F.create(id,snapshot.tier,snapshot.name,snapshot.bot),generation=snapshot.generation,samples={}}
    e.model.Parent=folder; entries[id]=e
   end
   table.insert(e.samples,{time=stamp,state=snapshot})
   while #e.samples>8 do table.remove(e.samples,1) end
   if id==ownId then
    local previous=e.renderPos
    local a=table.clone(snapshot); local cursor=stamp
    -- Replay locally sampled controls since this authoritative snapshot.
    local active=history[1] and history[1].value or input
    for _,command in ipairs(history) do
     if command.time<=stamp then active=command.value
     elseif command.time<=now then
      a.intent=active; simulate(a,command.time-cursor); cursor=command.time; active=command.value
     end
    end
    a.intent=active; simulate(a,now-cursor); e.predicted=a
    e.offset=previous and (previous-a.pos) or Vector3.zero
    if e.offset.Magnitude>12 then e.offset=Vector3.zero; e.renderFacing=nil end
   end
  end
  for id,e in pairs(entries) do if not present[id] then e.model:Destroy(); entries[id]=nil end end
 end)
 function R:update(dt,controls)
  local now=workspace:GetServerTimeNow()
  if controls~=input or #history==0 then input=controls; table.insert(history,{time=now,value=input}) end
  while #history>1 and history[2].time<now-1 do table.remove(history,1) end
  local ownPosition
  for id,e in pairs(entries) do
   local pos,facing,bank,velocity,phase
   if id==ownId and e.predicted then
    local a=e.predicted; a.intent=input; simulate(a,dt)
    e.offset*=math.exp(-dt*12)
    pos=C.clampPosition(a.pos+e.offset,C.Tiers[a.tier].size)
    facing=a.facing; bank=a.bank; velocity=a.velocity; phase=a.phase
   else
    -- Interpolate a short distance behind the server to bridge packet arrivals.
    local renderTime=now-.1; local samples=e.samples; local left=samples[1]; local right=left
    for i=2,#samples do
     right=samples[i]
     if right.time>=renderTime then break end
     left=right
    end
    local a,b=left.state,right.state
    local alpha=right.time>left.time and math.clamp((renderTime-left.time)/(right.time-left.time),0,1) or 0
    pos=a.pos:Lerp(b.pos,alpha); facing=S.turn(a.facing,b.facing,math.acos(math.clamp(a.facing:Dot(b.facing),-1,1))*alpha)
    if renderTime>right.time then pos+=b.velocity*math.min(renderTime-right.time,.1) end
    pos=C.clampPosition(pos,C.Tiers[b.tier].size)
    bank=a.bank+(b.bank-a.bank)*alpha; velocity=b.velocity; phase=b.phase
   end
   e.renderPos=pos
   e.renderFacing=id==ownId and e.renderFacing and S.turn(e.renderFacing,facing,6*dt) or facing
   local up=math.abs(e.renderFacing.Y)>.97 and Vector3.xAxis or Vector3.yAxis
   local sway=math.sin(now*4.2+phase)*.028*math.min(1,velocity.Magnitude/10)
   e.model:PivotTo(CFrame.lookAt(pos,pos+e.renderFacing,up)*CFrame.Angles(0,sway,bank))
   if id==ownId then ownPosition=pos end
  end
  return ownPosition
 end
 return R
end
return R
