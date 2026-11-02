-- Shared water movement: bounded turning, acceleration, coasting and stroke cadence.
local C=require(script.Parent.Config)
local S={}
function S.turn(from,to,limit)
 local dot=math.clamp(from:Dot(to),-1,1)
 local angle=math.acos(dot)
 if angle<.0001 then return to end
 local axis=from:Cross(to)
 if axis.Magnitude<.0001 then
  axis=from:Cross(math.abs(from.Y)<.9 and Vector3.yAxis or Vector3.xAxis)
 end
 return CFrame.fromAxisAngle(axis.Unit,math.min(angle,limit)):VectorToWorldSpace(from).Unit
end
function S.update(a,dt,now)
 local t=C.Tiers[a.tier]
 local speed=a.velocity.Magnitude
 local strength=math.min(1,a.intent.Magnitude)
 local direction=speed>.01 and a.velocity.Unit or a.facing
 local phase=a.phase or 0
 if strength>.02 then
  local wanted=a.intent.Unit
  local agility=(a.player and 2.9 or 1.75)/(1+(a.tier-1)*.075)
  direction=S.turn(direction,wanted,agility*dt)
  local alignment=math.max(0,direction:Dot(wanted))
  local stroke=1+.075*math.sin(now*4.2+phase)
  local targetSpeed=t.speed*strength*(.58+.42*alignment)*stroke
  local acceleration=a.player and 38 or 24
  speed+=math.clamp(targetSpeed-speed,-acceleration*dt,acceleration*dt)
 else
  speed*=math.exp(-2.2*dt)
  if speed<.025 then speed=0 end
 end
 a.velocity=direction*speed
 local raw=a.pos+a.velocity*dt
 a.pos=C.clampPosition(raw,t.size)
 -- Slide along pond edges rather than accumulating velocity against the wall.
 local correction=raw-a.pos
 if correction.Magnitude>.0001 then
  local normal=correction.Unit
  a.velocity-=normal*math.max(0,a.velocity:Dot(normal))
 end
 if a.velocity.Magnitude>.1 then
  a.facing=S.turn(a.facing,a.velocity.Unit,3.8*dt)
 end
 local turn=a.facing:Cross(direction).Y
 a.bank=(a.bank or 0)+(-turn*.35-(a.bank or 0))*(1-math.exp(-dt*5))
end
-- Tank input: X steers, Y changes depth, Z is signed forward thrust.
-- Heading stays independent of velocity, so reversing never flips the fish.
function S.tank(a,dt)
 local t=C.Tiers[a.tier]
 local steer=math.clamp(a.intent.X,-1,1)
 local thrust=math.clamp(a.intent.Z,-1,1)
 local boosting=(a.boostRemaining or 0)>0
 local boostFraction=dt>0 and math.min(a.boostRemaining or 0,dt)/dt or 0
 a.boostRemaining=math.max(0,(a.boostRemaining or 0)-dt)
 if boosting and math.abs(thrust)<.01 then thrust=1 end
 a.yaw=(a.yaw or math.atan2(-a.facing.X,-a.facing.Z))-steer*2.15/(1+(a.tier-1)*.09)*dt
 local heading=Vector3.new(-math.sin(a.yaw),0,-math.cos(a.yaw))
 local target=(heading*thrust*(thrust<0 and .42 or 1)+Vector3.yAxis*a.intent.Y*.65)
 if target.Magnitude>1 then target=target.Unit end
 target*=t.speed*(1+(C.BoostMultiplier-1)*boostFraction)
 local response=boosting and 8 or a.intent.Magnitude>.01 and 3.8 or 2.2
 a.velocity=a.velocity:Lerp(target,1-math.exp(-response*dt))
 local raw=a.pos+a.velocity*dt
 a.pos=C.clampPosition(raw,t.size)
 local correction=raw-a.pos
 if correction.Magnitude>.0001 then
  local normal=correction.Unit
  a.velocity-=normal*math.max(0,a.velocity:Dot(normal))
 end
 local pitch=math.clamp(a.velocity.Y/t.speed,-.5,.5)
 a.facing=(heading+Vector3.yAxis*pitch).Unit
 a.bank=(a.bank or 0)+(-steer*.18*math.min(1,a.velocity.Magnitude/t.speed)-(a.bank or 0))*(1-math.exp(-5*dt))
end
return S
