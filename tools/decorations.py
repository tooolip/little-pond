"""Small, composed pond landmarks rather than uniformly scattered filler."""
import math, random

def build(world, item, part, triangle, floor_at):
    rng=random.Random(619)
    def model(name):return item(world,'Model',name)[0]
    def leaf(parent,x,y,z,size,color,angle=0):
        # Four facets form a broad leaf with a visible central ridge.
        a=(x,y,z-size*.5);b=(x+size*.35*math.cos(angle),y,z);c=(x,y,z+size*.5);d=(x-size*.35*math.cos(angle),y,z);m=(x,y+.35,z)
        for p,q in [(a,b),(b,c),(c,d),(d,a)]:triangle(parent,'Leaf facet',p,q,m,color)
    def stone(parent,x,z,size):
        y=floor_at(x,z)
        part(parent,'Rounded pebble',(x,y+size*.22,z),(size,size*.65,size*.85),(162,179,160),'Ball')
        part(parent,'Sunlit stone facet',(x,y+size*.47,z),(size*.66,size*.13,size*.55),(186,197,177),'Wedge',yaw=rng.random()*3)
    # An oversized garden pot makes a recognisable underwater hideout.
    pot=model('The forgotten flowerpot');x,z=-32,-52;y=floor_at(x,z)
    for i in range(12):
        a=i*math.tau/12
        part(pot,'Terracotta stave',(x+math.cos(a)*7,y+5,z+math.sin(a)*7),(1.6,10,3.9),(187+i%3*7,123+i%3*5,96),yaw=-a)
        part(pot,'Pot rim',(x+math.cos(a)*7.5,y+10,z+math.sin(a)*7.5),(2.3,1.7,4.2),(222,155,115),yaw=-a)
    part(pot,'Dark pot interior',(x,y+.4,z),(.6,12.5,12.5),(108,107,81),'Cylinder',roll=math.pi/2)
    for dx,dz in [(-9,3),(11,1),(3,11)]:stone(pot,x+dx,z+dz,3)
    for i in range(5):leaf(pot,x-12+i*2,y+3+i*.5,z-7,4,(131,173,122),i*.3)
    # Hollow log with a polygonal bark shell and pale growth rings at either end.
    log=model('The hollow willow');x,z=102,116;y=floor_at(x,z)
    for i in range(10):
        a=i*math.tau/10
        part(log,'Bark segment',(x+math.cos(a)*6,y+6+math.sin(a)*6,z),(2.5,3.8,27),(112+i%3*9,88+i%3*6,64),roll=a)
        for end in [-1,1]:part(log,'Pale end grain',(x+math.cos(a)*5.7,y+6+math.sin(a)*5.7,z+end*13.6),(2.3,3.3,.5),(195,162,112),roll=a)
    for i in range(5):part(log,'Moss cushion',(x+i*2-4,y+12,z+i*3-6),(5,1.3,5),(112,164+i*3,103),'Ball')
    # Three small shell gardens with subtle ribs, pearls and polished pebbles.
    for cx,cz in [(-93,5),(66,-111),(155,37)]:
        shell=model('Shell garden')
        for k in range(4):
            x,z=cx+rng.uniform(-9,9),cz+rng.uniform(-9,9);y=floor_at(x,z);size=rng.uniform(2.3,4)
            for i in range(5):
                a=(i-2)*.28
                part(shell,'Shell rib',(x+math.sin(a)*size*.55,y+.65,z+math.cos(a)*size*.25),(.55,1.1,size),(238,201+i*5,178+i*6),'Ball',yaw=a)
            part(shell,'Pearl',(x,y+1.05,z-size*.26),(.7,.7,.7),(250,242,214),'Ball')
        for k in range(5):stone(shell,cx+rng.uniform(-15,15),cz+rng.uniform(-15,15),rng.uniform(1.5,3))
    # Tall ribbon plants form two distinct, readable underwater gardens.
    for cx,cz,colors in [(-132,64,[(79,148,130),(114,178,143)]),(73,152,[(143,156,173),(178,160,174)])]:
        plants=model('Ribbon garden')
        for i in range(14):
            x,z=cx+rng.uniform(-15,15),cz+rng.uniform(-12,12);y=floor_at(x,z);h=rng.uniform(6,12)
            for k in range(3):
                part(plants,'Ribbon blade',(x+math.sin(k+i)*.7,y+h*(k+.5)/3,z),(.35,h/3+1,1.9),colors[i%2],'Wedge',yaw=i*.65,roll=math.sin(k+i)*.17)
    # Little land vignettes: mushroom patches, daisies and tiny benches.
    for cx,cz in [(-211,121),(153,-229),(136,262)]:
        patch=model('Mushroom and daisy patch')
        for i in range(9):
            x,z=cx+rng.uniform(-13,13),cz+rng.uniform(-12,12);y=floor_at(x,z);s=rng.uniform(.8,1.6)
            part(patch,'Mushroom stem',(x,y+1.3*s,z),(.55*s,2.6*s,.55*s),(239,224,183))
            part(patch,'Mushroom cap',(x,y+2.6*s,z),(3*s,1.1*s,3*s),(205,121+i%3*12,112),'Ball')
            for dx,dz in [(-.6,0),(.5,.4),(0,-.6)]:part(patch,'Cap spot',(x+dx*s,y+3.08*s,z+dz*s),(.35*s,.14*s,.35*s),(255,238,206),'Ball')
        for i in range(7):
            x,z=cx+rng.uniform(-15,15),cz+rng.uniform(-15,15);y=floor_at(x,z)
            part(patch,'Daisy stem',(x,y+1.5,z),(.15,3,.15),(109,151,85))
            for j in range(5):
                a=j*math.tau/5;part(patch,'Daisy petal',(x+math.cos(a)*.7,y+3,z+math.sin(a)*.7),(1,.22,.6),(250,236,205),'Ball',yaw=-a)
            part(patch,'Daisy heart',(x,y+3.2,z),(.6,.3,.6),(241,195,95),'Ball')
    bench=model('Waterside bench');x,z=112,257;y=floor_at(x,z)
    for dx in [-5,5]:part(bench,'Bench leg',(x+dx,y+2,z),(1,4,3),(110,95,74))
    for dz in [-1.1,1.1]:part(bench,'Seat plank',(x,y+4,z+dz),(14,.7,1.9),(198,159,108))
    for dx in [-5,5]:part(bench,'Back support',(x+dx,y+5.5,z+2),(1,5,1),(110,95,74))
    part(bench,'Bench back',(x,y+7,z+2),(14,2.5,.7),(193,149,99))
    # A toy-like rowboat near the dock, above the surface with a contrasting interior.
    boat=model('Little rowboat');x,z=10,208
    part(boat,'Hull',(x,45,z),(9,2,18),(194,129,92))
    for dx in [-4.3,4.3]:part(boat,'Gunwale',(x+dx,46.5,z),(.8,2,18),(226,177,120))
    for dz in [-8.5,8.5]:part(boat,'End board',(x,46.5,z+dz),(8.5,2,.8),(214,158,111))
    part(boat,'Boat floor',(x,46.05,z),(7.3,.2,16),(107,139,123))
    for dz in [-4,4]:part(boat,'Seat',(x,47,z+dz),(8.3,.65,2.1),(230,188,134))
    part(boat,'Oar',(x+2,47.8,z),(1,.35,17),(141,105,73),yaw=.35)
    part(boat,'Oar blade',(x+4.6,47.8,z+7.2),(2.3,.35,4),(179,136,88),yaw=.35)
