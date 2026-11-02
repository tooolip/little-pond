local C=require(script.Parent.Config)
local B={}
B.ChaseDuration=7
B.StallDuration=2.5
B.IgnoreDuration=14
B.RestDuration=6
local function unit(v,fallback) return v.Magnitude>.001 and v.Unit or fallback end
function B.reset(a)
 a.brain={ignored={},restUntil=0,mode='wander'}
end
local function abandon(brain,now)
 if brain.target then brain.ignored[brain.target.id]=now+B.IgnoreDuration end
 brain.target=nil; brain.restUntil=now+B.RestDuration; brain.food=nil
end
function B.update(a,actors,weeds,now)
 if not a.brain then B.reset(a) end
 local brain=a.brain
 for id,untilTime in pairs(brain.ignored) do if untilTime<=now then brain.ignored[id]=nil end end
 local threat; local threatDistance=42
 for _,other in pairs(actors) do
  if other~=a and other.safe<=now and C.canEat(other,a) then
   local distance=(other.pos-a.pos).Magnitude
   if distance<threatDistance then threat=other; threatDistance=distance end
  end
 end
 local target=brain.target
 if target then
  local distance=(target.pos-a.pos).Magnitude
  if actors[target.id]~=target or target.safe>now or not C.canEat(a,target) or distance>95
    or now-brain.started>=B.ChaseDuration or now-brain.progressAt>=B.StallDuration then
   abandon(brain,now); target=nil
  elseif distance<brain.bestDistance-2 then
   brain.bestDistance=distance; brain.progressAt=now
  end
 end
 local aim; local throttle=.68
 if threat then
  if brain.target then abandon(brain,now) end
  brain.mode='flee'
  aim=a.pos+unit(a.pos-threat.pos,a.facing)*35; throttle=1
 elseif not target and now>=brain.restUntil then
  local nearest=65
  for _,other in pairs(actors) do
   if other~=a and other.safe<=now and not brain.ignored[other.id] and C.canEat(a,other) then
    local distance=(other.pos-a.pos).Magnitude
    if distance<nearest then nearest=distance; target=other end
   end
  end
  if target then
   brain.target=target; brain.started=now; brain.progressAt=now; brain.bestDistance=nearest
  end
 end
 if not threat then
  if target then
   brain.mode='chase'; throttle=.96
   -- A modest lead produces curved interception instead of nose-to-tail pursuit.
   aim=target.pos+target.velocity*.25
  else
   local w=brain.food
   if not w or w.ready>now then
    w=nil; local nearest=75
    for _,candidate in ipairs(weeds) do if candidate.ready<=now then
     local distance=(candidate.pos-a.pos).Magnitude
     if distance<nearest then nearest=distance; w=candidate end
    end end
    brain.food=w
   end
   if w then brain.mode='forage'; aim=w.pos
   else
    brain.mode='wander'
    if not brain.waypoint or now>brain.wanderUntil or (brain.waypoint-a.pos).Magnitude<8 then
     local phase=a.phase or 0
     brain.waypoint=C.clampPosition(a.pos+Vector3.new(math.sin(now*.37+phase)*40,math.sin(now*.19+phase)*8,math.cos(now*.31+phase)*40),C.Tiers[a.tier].size)
     brain.wanderUntil=now+4.5
    end
    aim=brain.waypoint; throttle=.5
   end
  end
 end
 local delta=aim-a.pos; local distance=delta.Magnitude
 local dir=unit(delta,a.facing)
 local side=unit(dir:Cross(Vector3.yAxis),Vector3.xAxis)
 local phase=a.phase or 0
 -- Continuous wandering fades near food, so weaving cannot prevent a bite.
 local weave=math.min(1,distance/14)*(brain.mode=='chase' and .07 or .19)
 dir=unit(dir+side*math.sin(now*1.1+phase)*weave+Vector3.yAxis*math.sin(now*.8+phase)*weave*.25,dir)
 if brain.mode=='forage' or brain.mode=='wander' then throttle*=math.clamp(distance/10,.22,1) end
 local flat=Vector3.new(a.pos.X,0,a.pos.Z)
 local boundary=C.swimRadius(math.atan2(flat.Z,flat.X),C.Tiers[a.tier].size)
 if flat.Magnitude>boundary-18 then
  dir=unit(dir-flat.Unit*math.clamp((flat.Magnitude-(boundary-18))/12,0,1.6),-flat.Unit)
 end
 a.intent=distance>.5 and dir*throttle or Vector3.zero
 return brain.mode
end
return B
