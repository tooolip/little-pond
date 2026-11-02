-- Shared balancing rules. Score lasts for the session; growth resets when eaten.
local C = {}
local Map=require(script.Parent.WorldMap)
C.Capacity = 20
C.Radius = 310
C.Surface = 44
C.SeaweedCount = 300
C.SeaweedRespawn = 11
C.SpawnProtection = 5
C.Tiers = {
 {name='Minnow', threshold=0, size=2.5, speed=25, color=Color3.fromRGB(108,218,195)},
 {name='Perch', threshold=8, size=3.8, speed=27, color=Color3.fromRGB(255,191,85)},
 {name='Bass', threshold=30, size=5.3, speed=29, color=Color3.fromRGB(118,181,111)},
 {name='Tuna', threshold=75, size=7, speed=30, color=Color3.fromRGB(90,167,224)},
 {name='Marlin', threshold=160, size=9, speed=32, color=Color3.fromRGB(146,134,226)},
 {name='Shark', threshold=310, size=11.5, speed=29, color=Color3.fromRGB(105,142,173)},
 {name='Whale', threshold=550, size=15, speed=25, color=Color3.fromRGB(108,119,208)},
}
C.BoostDuration=1.2
C.BoostMultiplier=1.8
C.BoostCostFraction=.2
function C.progressSpan(tier)
 return tier<#C.Tiers and C.Tiers[tier+1].threshold-C.Tiers[tier].threshold
  or C.Tiers[tier].threshold-C.Tiers[tier-1].threshold
end
function C.boostCost(tier) return C.progressSpan(tier)*C.BoostCostFraction end
function C.canBoost(a)
 return a.ready and (a.boostRemaining or 0)<=0
  and a.growth-C.Tiers[a.tier].threshold>=C.boostCost(a.tier)
end
function C.tryBoost(a)
 if not C.canBoost(a) then return false end
 a.growth-=C.boostCost(a.tier)
 a.boostRemaining=C.BoostDuration
 return true
end
function C.tierFor(growth)
 local tier=1
 for i,t in ipairs(C.Tiers) do if growth >= t.threshold then tier=i end end
 return tier
end
function C.canEat(a,b)
 return a.tier > b.tier or (a.tier == 7 and b.tier == 7 and a.score > b.score)
end
function C.reward(predatorTier, preyTier)
 -- Seaweed is tier zero. Immediately lower prey always has the best return.
 if preyTier == 0 then return math.max(0.08, 0.48^(predatorTier-1)) end
 return 8 * 1.45^(preyTier-1) * 0.48^math.max(0,predatorTier-preyTier-1)
end
C.floorHeight=Map.floorHeight
C.shoreRadius=Map.radius
function C.swimRadius(angle,size)
 local radius=Map.radius(angle)*.94-size-3
 local ceiling=C.Surface-size*.35-2
 local clearance=1.2+size*.38
 local x,z=math.cos(angle),math.sin(angle)
 if Map.floorHeight(x*radius,z*radius)+clearance>ceiling then
  local low,high=0,radius
  for _=1,14 do
   local mid=(low+high)/2
   if Map.floorHeight(x*mid,z*mid)+clearance<=ceiling-.05 then low=mid else high=mid end
  end
  radius=low
 end
 return radius
end
function C.clampPosition(v, size)
 local r=C.swimRadius(math.atan2(v.Z,v.X),size)
 local flat=Vector3.new(v.X,0,v.Z)
 if flat.Magnitude > r then flat=flat.Unit*r end
 local floor=Map.floorHeight(flat.X,flat.Z)+1.2+size*.38
 local ceiling=C.Surface-size*.35-2
 return Vector3.new(flat.X, math.clamp(v.Y,math.min(floor,ceiling),ceiling),flat.Z)
end
return C
