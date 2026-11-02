#!/usr/bin/env python3
"""Build a self-contained Roblox XML place using only Python's standard library."""
from pathlib import Path
import xml.etree.ElementTree as ET
import math, random
ROOT=Path(__file__).resolve().parents[1]
rng=random.Random(73)
root=ET.Element('roblox',{'version':'4'})
ET.SubElement(root,'External').text='null'; ET.SubElement(root,'External').text='nil'
serial=0
def prop(props,tag,name,value):
    e=ET.SubElement(props,tag,{'name':name})
    if isinstance(value,dict):
        for k,v in value.items(): ET.SubElement(e,k).text=str(v)
    else: e.text=str(value).lower() if isinstance(value,bool) else str(value)
    return e
def item(parent,cls,name):
    global serial
    serial+=1
    e=ET.SubElement(parent,'Item',{'class':cls,'referent':f'RBX{serial}'})
    p=ET.SubElement(e,'Properties'); prop(p,'string','Name',name)
    return e,p
def vec(x,y,z):return {'X':x,'Y':y,'Z':z}
def cf(x,y,z,yaw=0,roll=0):
    c,s=math.cos(yaw),math.sin(yaw); a,b=math.cos(roll),math.sin(roll)
    return {'X':x,'Y':y,'Z':z,'R00':c*a,'R01':-c*b,'R02':s,'R10':b,'R11':a,'R12':0,'R20':-s*a,'R21':s*b,'R22':c}
def color(rgb):return {'R':rgb[0]/255,'G':rgb[1]/255,'B':rgb[2]/255}
def part(parent,name,pos,size,rgb,shape='Block',yaw=0,roll=0,trans=0,material=256):
    e,p=item(parent,'WedgePart' if shape=='Wedge' else 'Part',name)
    prop(p,'Vector3','size',vec(*size));prop(p,'CoordinateFrame','CFrame',cf(*pos,yaw,roll));prop(p,'Color3','Color',color(rgb))
    for n,v in [('Anchored',True),('CanCollide',False),('CanTouch',False)]:prop(p,'bool',n,v)
    prop(p,'float','Transparency',trans);prop(p,'token','Material',material)
    prop(p,'token','TopSurface',0);prop(p,'token','BottomSurface',0)
    if shape!='Wedge':prop(p,'token','shape',{'Block':1,'Ball':0,'Cylinder':2}[shape])
    return e
workspace,wp=item(root,'Workspace','Workspace')
prop(wp,'bool','StreamingEnabled',False);prop(wp,'float','Gravity',0)
world,_=item(workspace,'Model','PondEnvironment')
from landscape import HEIGHTS, STEP, HALF, N, radius, floor_at, write_map
write_map(ROOT/'src/shared/WorldMap.luau')
def sub(a,b):return tuple(x-y for x,y in zip(a,b))
def dot(a,b):return sum(x*y for x,y in zip(a,b))
def cross(a,b):return (a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
def unit(a):
    n=math.sqrt(dot(a,a));return tuple(x/n for x in a)
def triangle(parent,name,a,b,c,rgb,trans=0,material=256):
    ab,ac,bc=sub(b,a),sub(c,a),sub(c,b)
    if dot(ab,ab)>dot(ac,ac) and dot(ab,ab)>dot(bc,bc):c,a=a,c
    elif dot(ac,ac)>dot(bc,bc):a,b=b,a
    ab,ac,bc=sub(b,a),sub(c,a),sub(c,b)
    right=unit(cross(ac,ab));back=unit(bc);up=unit(cross(bc,right));h=abs(dot(ab,up))
    for endpoint,sgn,length in [(b,1,abs(dot(ab,back))),(c,-1,abs(dot(ac,back)))]:
        center=tuple((x+y)/2 for x,y in zip(a,endpoint))
        e=part(parent,name,center,(.06,h,max(.01,length)),rgb,'Wedge',trans=trans,material=material)
        frame=e.find("Properties/CoordinateFrame[@name='CFrame']")
        matrix={**vec(*center),'R00':right[0]*sgn,'R10':right[1]*sgn,'R20':right[2]*sgn,'R01':up[0],'R11':up[1],'R21':up[2],'R02':back[0]*sgn,'R12':back[1]*sgn,'R22':back[2]*sgn}
        for k,v in matrix.items():frame.find(k).text=str(v)
        prop(e.find('Properties'),'bool','CastShadow',trans==0)
        if trans:prop(e.find('Properties'),'float','Reflectance',.025)
# A continuous broad ground mass, with a triangulated basin carved into its center.
part(world,'Earth beneath the meadow',(0,-52,0),(3000,40,3000),(117,132,83))
for x,z,sx,sz in [(0,942,3000,1116),(0,-942,3000,1116),(942,0,1116,768),(-942,0,1116,768)]:
    part(world,'Meadow to the horizon',(x,10,z),(sx,88,sz),(106,152,89))
land,_=item(world,'Folder','Sculpted bed and banks')
for i in range(N-1):
    for j in range(N-1):
        x,z=-HALF+i*STEP,-HALF+j*STEP
        q=math.hypot(x+12,z+12)/radius(math.atan2(z+12,x+12))
        if q<.55:rgb=(158,188,168)
        elif q<.85:rgb=(207,213,166)
        elif q<1.02:rgb=(215,209,151)
        else:rgb=(112,163,100)
        variation=rng.randint(-5,5);rgb=tuple(v+variation for v in rgb)
        a=(x,HEIGHTS[i][j],z);b=(x+STEP,HEIGHTS[i+1][j],z);c=(x,HEIGHTS[i][j+1],z+STEP);d=(x+STEP,HEIGHTS[i+1][j+1],z+STEP)
        triangle(land,'Meadow facet' if q>1 else 'Pond bed facet',a,b,c,rgb)
        triangle(land,'Meadow facet' if q>1 else 'Pond bed facet',d,c,b,rgb)
water,_=item(world,'Folder','PondWater')
for i in range(80):
    a,b=i*math.tau/80,(i+1)*math.tau/80
    triangle(water,'Water',(0,44,0),(math.cos(a)*radius(a),44,math.sin(a)*radius(a)),(math.cos(b)*radius(b),44,math.sin(b)*radius(b)),(103,190,188),.92,256)
    if i%2==0:
        r=radius(a)*.974
        part(water,'Shore glimmer',(math.cos(a)*r,44.13,math.sin(a)*r),(rng.uniform(5,11),.06,.35),(210,250,231),yaw=math.pi/2-a,trans=.52)
for i in range(48):
    a=rng.random()*math.tau;r=math.sqrt(rng.random())*radius(a)*.87
    part(water,'Glint',(math.cos(a)*r,44.19,math.sin(a)*r),(rng.uniform(3,9),.05,.19),(220,255,239),yaw=-.2,trans=.5)
# Varied boulders, pebble gardens, and flowering aquatic plants anchored to the bed.
for i in range(120):
    a=rng.random()*math.tau;r=math.sqrt(rng.random())*radius(a)*.9;x,z=math.cos(a)*r,math.sin(a)*r;y=floor_at(x,z)
    size=rng.uniform(1.5,6.5)
    part(world,'River stone',(x,y+size*.23,z),(size,size*.55,size*.8),(140+rng.randrange(28),161+rng.randrange(24),149),'Ball',yaw=a)
    if i%3==0:
        for k in range(4):
            px,pz=x+k*.85,z+math.sin(k)*1.2;py=floor_at(px,pz)
            part(world,'Aquatic blossom',(px,py+1.5+k*.3,pz),(.7,3+k*.6,.8),(216,143+k*10,148),'Wedge',yaw=k)
# Asymmetric groves; some trees sit close to shore, others recede into the landscape.
for i in range(130):
    a=rng.random()*math.tau;r=radius(a)+rng.uniform(18,250)
    x,z=math.cos(a)*r,math.sin(a)*r;y=floor_at(x,z) if max(abs(x),abs(z))<380 else 54
    h=rng.uniform(12,26)
    part(world,'Willow trunk',(x,y+h*.45,z),(2.6,h,2.6),(127,99,72),yaw=a)
    if i%3==0:
        for k in range(3):
            size=10-k*2.3;bottom=y+h-5+k*5;top=(x,bottom+12,z)
            corners=[(x-size,bottom,z-size),(x+size,bottom,z-size),(x+size,bottom,z+size),(x-size,bottom,z+size)]
            for j in range(4):triangle(world,'Pine facet',corners[j],corners[(j+1)%4],top,(76+j%2*7,128+k*8,91))
    else:
        part(world,'Broadleaf crown',(x,y+h,z),(17,14,16),(92+rng.randrange(28),155+rng.randrange(30),101),'Ball')
        part(world,'Broadleaf crown',(x+5,y+h+3,z+2),(13,11,12),(130,180,108),'Ball')
for i in range(22):
    a=rng.random()*math.tau;r=rng.uniform(550,1100);x,z=math.cos(a)*r,math.sin(a)*r
    part(world,'Distant wooded hill',(x,56,z),(rng.uniform(130,240),rng.uniform(75,160),rng.uniform(140,220)),(98+rng.randrange(22),145+rng.randrange(20),104),'Ball')
# Lily coves cluster instead of forming an evenly spaced ring.
for cx,cz in [(-134,-100),(142,73),(-65,175)]:
    for i in range(14):
        x,z=cx+rng.uniform(-26,26),cz+rng.uniform(-20,20)
        if math.hypot(x,z)>radius(math.atan2(z,x))*.94:continue
        size=rng.uniform(5,10)
        part(world,'Lily pad',(x,44.4,z),(.35,size,size),(69,153,106),'Cylinder',roll=math.pi/2)
        if i%3==0:
            for j in range(5):
                a=j*math.tau/5
                part(world,'Lotus petal',(x+math.cos(a)*1.2,45,z+math.sin(a)*1.2),(2.5,1.1,1.7),(245,162,178),'Wedge',yaw=-a)
            part(world,'Lotus heart',(x,45.5,z),(1.3,.8,1.3),(254,221,123),'Ball')
for i in range(170):
    a=rng.random()*math.tau
    if math.sin(a*3)<-.3:continue
    r=radius(a)*rng.uniform(.96,1.04);x,z=math.cos(a)*r,math.sin(a)*r;y=floor_at(x,z);h=rng.uniform(4,10)
    part(world,'Reed',(x,y+h/2,z),(.45,h,.45),(91,144,88))
    if i%3==0:part(world,'Cattail',(x,y+h,z),(.9,2.3,.9),(132,92,61))
# Three differently composed landmarks, all resting on the local bed.
for x,z in [(-72,42),(98,-62),(-113,-102)]:
    y=floor_at(x,z)
    for dx in [-10,10]:part(world,'Old garden pillar',(x+dx,y+8,z),(4,16,5),(158,174,155))
    part(world,'Mossy arch',(x,y+17,z),(25,5,6),(182,193,165))
    for k in range(3):part(world,'Arch moss',(x-8+k*8,y+20,z),(6,1.2,6),(111,167,111),'Wedge')
    part(world,'Fallen masonry',(x+20,y+2,z+13),(9,4,6),(177,187,160),'Wedge',yaw=.4)
for x,z,a in [(145,115,.7),(-143,-123,-.5),(42,193,1.4)]:
    y=floor_at(x,z)
    part(world,'Fallen driftwood',(x,y+3,z),(6,6,30),(138,103,72),yaw=a)
    part(world,'Driftwood moss',(x,y+6,z),(4,1,21),(112,163,104),yaw=a)
# South-bank dock, stepping stones, and a modest waterside hut.
x,z=34,212
for i in range(10):part(world,'Dock plank',(x,z*0+47,193+i*4),(26,1,3.7),(175,127,86))
for px in [22,46]:
    for pz in [196,224]:
        bed=floor_at(px,pz);part(world,'Dock post',(px,(47+bed)/2,pz),(2,47-bed,2),(112,88,65))
for i in range(8):
    px,pz=34+math.sin(i*.8)*5,234+i*8;py=floor_at(px,pz)
    part(world,'Garden stepping stone',(px,py+.6,pz),(6,1.2,5),(185,184,157),'Cylinder',roll=math.pi/2)
x,z=76,275;y=floor_at(x,z)
part(world,'Boathouse',(x,y+9,z),(27,18,21),(192,158,111))
part(world,'Boathouse roof left',(x-8.5,y+21,z),(28,6,17),(129,100,101),'Wedge',yaw=math.pi/2)
part(world,'Boathouse roof right',(x+8.5,y+21,z),(28,6,17),(147,112,106),'Wedge',yaw=-math.pi/2)
for dx in [-13,13]:part(world,'Painted corner trim',(x+dx,y+9,z-10.8),(1.2,18,.7),(239,216,169))
part(world,'Porch step',(x,y+.6,z-13),(11,1.2,5),(158,130,99))
part(world,'Door knob',(x+2,y+5,z-11),(.5,.5,.5),(228,189,104),'Ball')
part(world,'Door',(x,y+5,z-10.6),(6,10,.3),(84,111,99))
for dx in [-8,8]:part(world,'Window',(x+dx,y+11,z-10.7),(5,5,.3),(150,211,198))

from decorations import build as decorate
decorate(world,item,part,triangle,floor_at)

lighting,lp=item(root,'Lighting','Lighting')
prop(lp,'token','Technology',1);prop(lp,'float','ExposureCompensation',-.1);prop(lp,'float','Brightness',1.6);prop(lp,'float','ClockTime',15.3)
prop(lp,'Color3','Ambient',color((110,140,135)));prop(lp,'Color3','OutdoorAmbient',color((135,157,139)))
prop(lp,'Color3','FogColor',color((120,196,199)));prop(lp,'float','FogStart',300);prop(lp,'float','FogEnd',1600)
prop(lp,'bool','GlobalShadows',True)
cc,cp=item(lighting,'ColorCorrectionEffect','Pond palette');prop(cp,'float','Saturation',.12);prop(cp,'float','Contrast',.04)
at,ap=item(lighting,'Atmosphere','Meadow haze');prop(ap,'float','Density',.13);prop(ap,'float','Offset',.1);prop(ap,'float','Haze',.6);prop(ap,'float','Glare',.12);prop(ap,'Color3','Color',color((220,233,246)));prop(ap,'Color3','Decay',color((172,183,195)))
bloom,bp=item(lighting,'BloomEffect','Soft sunlight');prop(bp,'float','Intensity',.18);prop(bp,'float','Size',22);prop(bp,'float','Threshold',1.1)
rays,rp=item(lighting,'SunRaysEffect','Afternoon rays');prop(rp,'float','Intensity',.045);prop(rp,'float','Spread',.75)
prop(lp,'float','EnvironmentDiffuseScale',.45);prop(lp,'float','EnvironmentSpecularScale',.6)
rs,_=item(root,'ReplicatedStorage','ReplicatedStorage');shared,_=item(rs,'Folder','Pond')
for name in ['Config','FishFactory','Swimming','FishRenderer','BotBrain','WorldMap']:
    e,p=item(shared,'ModuleScript',name);prop(p,'ProtectedString','Source',(ROOT/f'src/shared/{name}.luau').read_text())
server,_=item(root,'ServerScriptService','ServerScriptService')
e,p=item(server,'Script','PondServer');prop(p,'ProtectedString','Source',(ROOT/'src/server/Game.server.luau').read_text())
sp,_=item(root,'StarterPlayer','StarterPlayer');sps,_=item(sp,'StarterPlayerScripts','StarterPlayerScripts')
e,p=item(sps,'LocalScript','PondClient');prop(p,'ProtectedString','Source',(ROOT/'src/client/Game.client.luau').read_text())
e,p=item(sps,'LocalScript','WaterEffects');prop(p,'ProtectedString','Source',(ROOT/'src/client/Water.client.luau').read_text())
ss,_=item(root,'ServerStorage','ServerStorage')
if (ROOT/'tests/Rules.luau').exists():
    e,p=item(ss,'ModuleScript','PondTests');prop(p,'ProtectedString','Source',(ROOT/'tests/Rules.luau').read_text())
players,pp=item(root,'Players','Players');prop(pp,'bool','CharacterAutoLoads',False)
# MaxPlayers is a published place setting; runtime admission guard additionally caps at 20.
cam,p=item(workspace,'Camera','Camera');prop(p,'CoordinateFrame','CFrame',{'X':0,'Y':330,'Z':430,'R00':1,'R01':0,'R02':0,'R10':0,'R11':.763,'R12':.646,'R20':0,'R21':-.646,'R22':.763})
prop(p,'token','CameraType',0);prop(wp,'Ref','CurrentCamera',cam.attrib['referent'])
ET.indent(root)
out=ROOT/'Little Pond.rbxlx';ET.ElementTree(root).write(out,encoding='utf-8',xml_declaration=True)
print(f'Built {out}: {serial} instances, {out.stat().st_size:,} bytes')
