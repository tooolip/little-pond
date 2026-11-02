-- Run in Studio command bar: require(game.ServerStorage.PondTests)()
return function()
 local C=require(game.ReplicatedStorage.Pond.Config)
 local count=0
 local function check(ok,msg) assert(ok,msg); count+=1 end
 for i=1,7 do
  check(C.tierFor(C.Tiers[i].threshold)==i,'tier boundary '..i)
  if i>1 then check(C.tierFor(C.Tiers[i].threshold-.001)==i-1,'below tier boundary '..i) end
  for j=1,7 do check(C.canEat({tier=i,score=10},{tier=j,score=10})==(i>j),'tier eating matrix') end
  check(C.reward(i,0)>0,'all fish can eat seaweed')
 end
 check(C.canEat({tier=7,score=11},{tier=7,score=10}),'higher-score whale wins')
 check(not C.canEat({tier=7,score=10},{tier=7,score=11}),'lower-score whale loses')
 check(not C.canEat({tier=7,score=10},{tier=7,score=10}),'equal whales safe')
 check(not C.canEat({tier=2,score=10000},{tier=3,score=0}),'score cannot bypass tiers')
 for tier=2,7 do check(C.reward(tier,0)<C.reward(tier-1,0) or C.reward(tier,0)==.08,'diminishing seaweed') end
 for tier=3,7 do check(C.reward(tier,tier-1)>C.reward(tier,tier-2),'diminishing fish') end
 local p=C.clampPosition(Vector3.new(999,-100,999),15)
 check(Vector3.new(p.X,0,p.Z).Magnitude<=C.swimRadius(math.atan2(p.Z,p.X),15)+.001,'irregular shoreline boundary')
 check(p.Y>=C.floorHeight(p.X,p.Z)+1.2+15*.38-.001,'sculpted floor boundary')
 check(C.clampPosition(Vector3.new(0,999,0),15).Y<=C.Surface-15*.35-2+.001,'surface boundary')
 if workspace:FindFirstChild('Fish') then
  check(#workspace.Fish:GetChildren()==20,'exactly 20 actors')
  check(#workspace.Seaweed:GetChildren()==C.SeaweedCount,'food population')
 end
 local B=require(game.ReplicatedStorage.Pond.BotBrain)
 local S=require(game.ReplicatedStorage.Pond.Swimming)
 local function actor(id,tier,pos)
  return {id=id,tier=tier,score=0,pos=pos,velocity=Vector3.zero,facing=Vector3.new(0,0,-1),intent=Vector3.zero,safe=-1,phase=0,bank=0}
 end
 local hunter=actor('hunter',3,Vector3.new(0,15,0))
 local prey=actor('prey',1,Vector3.new(50,15,0))
 local group={hunter=hunter,prey=prey}
 check(B.update(hunter,group,{},0)=='chase','bot acquires prey')
 for n=1,6 do prey.pos=Vector3.new(50-n*3,15,0); B.update(hunter,group,{},n) end
 check(hunter.brain.started==0,'progress never resets chase deadline')
 B.update(hunter,group,{},7.1)
 check(hunter.brain.target==nil,'bot abandons chase at deadline')
 check(hunter.brain.ignored.prey>7.1,'timed-out prey gets cooldown')
 B.update(hunter,group,{},7.5)
 check(hunter.brain.target==nil,'bot does not immediately reacquire prey')
 B.update(hunter,group,{},14)
 check(hunter.brain.target==nil,'same prey remains ignored after general rest')
 B.update(hunter,group,{},22)
 check(hunter.brain.target==prey,'prey becomes eligible after cooldown')
 B.reset(hunter); B.update(hunter,group,{},30); B.update(hunter,group,{},33)
 check(hunter.brain.target==nil,'unproductive chase ends early')
 local swimmer=actor('swimmer',1,Vector3.new(0,20,0)); swimmer.player={}
 swimmer.velocity=Vector3.new(0,0,-20); swimmer.intent=Vector3.new(0,0,1)
 S.update(swimmer,.05,0)
 check(swimmer.velocity.Z<0,'reversal turns through water instead of snapping')
 check(swimmer.velocity.Magnitude<=22,'acceleration is bounded')
 local before=swimmer.velocity.Magnitude; swimmer.intent=Vector3.zero
 S.update(swimmer,.05,0)
 check(swimmer.velocity.Magnitude>0 and swimmer.velocity.Magnitude<before,'release coasts with drag')
 for _=1,60 do S.update(swimmer,.05,0) end
 check(swimmer.velocity.Magnitude<.1,'coasting eventually settles')
 local turned=S.turn(Vector3.xAxis,-Vector3.xAxis,.1)
 check(turned.X==turned.X and turned.Magnitude>.99,'opposite headings remain finite')
 check(math.acos(math.clamp(turned:Dot(Vector3.xAxis),-1,1))<.101,'turn rate limit')
 local vertical=S.turn(Vector3.yAxis,-Vector3.yAxis,.1)
 check(vertical.Y==vertical.Y,'vertical reversal remains finite')
 for tier=1,7 do
  for n=0,71 do
   local a=n*math.pi/36;local size=C.Tiers[tier].size
   local v=C.clampPosition(Vector3.new(math.cos(a)*1000,-100,math.sin(a)*1000),size)
   check(v.Y>=C.floorHeight(v.X,v.Z)+1.2+size*.38-.002,'all fish clear the bed')
   check(v.Y<=C.Surface-size*.35-2+.002,'all fish remain below surface')
  end
 end
 check(math.abs(C.shoreRadius(0)-C.shoreRadius(math.pi))>10,'asymmetric shoreline')
 check(C.floorHeight(-62,35)<C.floorHeight(106,-74),'deep pocket differs from shallow garden')
 -- Tank steering is independent of the camera and travel direction.
 local tank=actor('tank',1,Vector3.new(0,20,0))
 tank.intent=Vector3.xAxis
 for _=1,60 do S.tank(tank,1/60) end
 check(tank.facing.X>.8,'right input turns nose right')
 check((tank.pos-Vector3.new(0,20,0)).Magnitude<.001,'turning in place does not strafe')
 tank=actor('tank',1,Vector3.new(0,20,0)); tank.intent=Vector3.new(0,0,-1)
 for _=1,60 do S.tank(tank,1/60) end
 check(tank.pos.Z>0 and tank.facing.Z<-.99,'reverse backs up without flipping heading')
 check(tank.velocity.Magnitude<C.Tiers[1].speed*.43,'reverse is gentler than forward')
 tank.intent=Vector3.zero; local speed=tank.velocity.Magnitude
 S.tank(tank,.05)
 check(tank.velocity.Magnitude>0 and tank.velocity.Magnitude<speed,'tank coasts on release')
 tank.intent=Vector3.new(1,1,1)
 for _=1,300 do S.tank(tank,1/60) end
 check(tank.velocity.Magnitude<=C.Tiers[1].speed+.001,'combined inputs cannot exceed swim speed')
 check(tank.pos.Y<=C.Surface-C.Tiers[1].size*.35-2+.001,'tank respects water surface')
 local slow=actor('slow',1,Vector3.new(0,20,0)); local fast=actor('fast',1,slow.pos)
 slow.intent=Vector3.new(.3,0,1); fast.intent=slow.intent
 for _=1,20 do S.tank(slow,.05) end
 for _=1,60 do S.tank(fast,1/60) end
 check((slow.pos-fast.pos).Magnitude<1,'server and render step rates remain close')
 check(slow.facing:Dot(fast.facing)>.999,'tank turn rate independent of frame rate')
 for tier=1,7 do
  local base=C.Tiers[tier].threshold; local cost=C.boostCost(tier)
  local b=actor('boost',tier,Vector3.new(0,20,0)); b.ready=true; b.score=1000; b.growth=base+cost-.001
  check(not C.tryBoost(b),'insufficient progress rejects boost '..tier)
  check(b.growth==base+cost-.001 and not b.boostRemaining,'rejection changes nothing '..tier)
  b.growth=base+cost; b.ready=false
  check(not C.tryBoost(b),'welcome screen cannot boost '..tier)
  b.ready=true
  check(C.tryBoost(b),'exact cost grants boost '..tier)
  check(math.abs(b.growth-base)<.00001 and b.tier==tier and b.score==1000,'cost preserves tier and score '..tier)
  b.growth=base+cost*2
  check(not C.tryBoost(b) and b.growth==base+cost*2,'active boost cannot stack or charge again '..tier)
  for _=1,30 do S.tank(b,1/60) end
  check(b.velocity.Magnitude>C.Tiers[tier].speed*1.6,'boost accelerates even from rest '..tier)
  for _=1,120 do S.tank(b,1/60) end
  check(b.boostRemaining==0 and b.velocity.Magnitude<C.Tiers[tier].speed,'boost expires and coasts '..tier)
  check(C.tryBoost(b),'can boost again with sufficient progress '..tier)
 end
 print('LITTLE POND TESTS PASSED: '..count..' checks')
 return count
end
