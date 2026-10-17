"""Pixel Panic 0.2: native-resolution original art. Keeps the existing menu artwork.
20 individually composed environments; directional character and enemy animation.
Python + Pillow is used only to generate PNGs, never at game runtime.
"""
from PIL import Image, ImageDraw
from pathlib import Path
import math,random
OUT=Path(__file__).resolve().parents[1]/'assets/combat';OUT.mkdir(exist_ok=True)
W,H,F=1280,720,602
P=[['#090f20','#15243a','#29354a','#524051','#92646c','#dba78a','#a4ddc3'],
 ['#091527','#142c43','#284b64','#3f6c80','#659cab','#b8e5e1','#bfb9f1'],
 ['#0c1022','#1a2038','#34334b','#66496c','#b66498','#f4b6ca','#82e2d0'],
 ['#0d1329','#232c46','#45455f','#70627e','#ad8eaa','#f3ccbb','#a8e2e5'],
 ['#150d20','#2c1b32','#4c2b43','#844558','#c56865','#f3b77d','#a8d1b2']]
# A distinct lighting design per level: daylight, sunset, snow, neon, paradise, magma.
PALETTES=[
 ['#83beb9','#403a39','#775848','#b9764b','#e9ab62','#fff0b3','#c3efb6'],
 ['#e7aa83','#4f3c43','#815354','#b57656','#edb871','#ffe9b0','#c4dd9d'],
 ['#747b9b','#383e56','#5a6273','#85877e','#bdcba6','#f5e4b5','#a4ddc3'],
 ['#b4c18c','#413f35','#66633c','#97934e','#ddbf6c','#fff0bb','#d1e4ae'],
 ['#85c6e5','#31577b','#70a5c5','#a9d5de','#d6f4ee','#ffffff','#b7a3e9'],
 ['#3e518b','#273a62','#526e9b','#8cacc8','#c3e1ee','#f4f7ff','#bdb4ed'],
 ['#3b819f','#274c6b','#569cb1','#7bc9d1','#b1f1ed','#f3ffff','#b5ade6'],
 ['#a2d0e4','#526d93','#93b0ce','#c0d8e9','#e1ecff','#ffffff','#e9c995'],
 ['#343c67','#1c2b45','#48516e','#806c90','#db92b0','#ffe2b8','#97e9c7'],
 ['#605071','#302c4c','#60546b','#a06886','#f3a6be','#ffe6bc','#86e7d5'],
 ['#163c4a','#162f46','#345b6d','#4b8d93','#8ae7cf','#d3fff1','#f0a9d5'],
 ['#282344','#202538','#494665','#8d5d8b','#e09bce','#ffe6ee','#91e5ed'],
 ['#74bde8','#567da6','#a3cae2','#ede4c9','#d3ab55','#fffbea','#c3e1c1'],
 ['#a6d8e8','#5d81a2','#add2e1','#f6ead4','#d0a978','#fff8ec','#a8e4d3'],
 ['#91abe0','#61779d','#b1bddc','#e2dbeb','#cda65a','#fff8de','#c7e4df'],
 ['#e5bb88','#7d7da3','#b5bad7','#eee0c9','#d3a34c','#fff3cc','#c7daed'],
 ['#a34f42','#3e2937','#784033','#be623c','#ffac58','#ffe197','#db8981'],
 ['#713b42','#322d3a','#61413c','#b8633d','#ffba63','#ffebaf','#89b4b2'],
 ['#663d62','#292e43','#51465c','#99576a','#ed8f64','#ffd7a0','#d39ab5'],
 ['#c45b3c','#392c3a','#703d3b','#ce673c','#ffb958','#fff0b3','#e99578']]
def rgb(c):return tuple(int(c[i:i+2],16) for i in (1,3,5))
def mix(a,b,t):return tuple(int(x*(1-t)+y*t) for x,y in zip(rgb(a) if isinstance(a,str) else a,rgb(b) if isinstance(b,str) else b))
def poly(d,pts,c):d.polygon([(round(x),round(y)) for x,y in pts],fill=c)
def line(d,pts,c,w=1):d.line([(round(x),round(y)) for x,y in pts],fill=c,width=w)
def glowstar(d,x,y,c,r=2):d.line((x-r,y,x+r,y),fill=c);d.line((x,y-r,x,y+r),fill=c)
def mountain(d,rng,y,h,col):
 pts=[(-30,H),(-30,y)]+[(x,y-rng.randrange(h)) for x in range(-30,W+60,35)]+[(W+30,H)]
 poly(d,pts,col)
def pine(d,x,y,h,p):
 d.rectangle((x-3,y-h,x+3,y),fill=p[1])
 for k in range(6):
  yy=y-h+k*h/8;ww=9+k*h/22
  poly(d,[(x,yy-24),(x-ww,yy+40),(x-ww*.5,yy+35),(x-ww*1.3,yy+49),(x+ww*1.3,yy+49),(x+ww*.5,yy+35),(x+ww,yy+40)],p[2])
  line(d,[(x,yy-20),(x-ww+3,yy+37)],p[3])
def oak(d,rng,x,y,h,p,dead=False):
 def branch(px,py,angle,length,width,depth):
  end=(px+math.cos(angle)*length,py+math.sin(angle)*length)
  line(d,[(px,py),end],p[1],max(1,int(width)))
  line(d,[(px-width*.18,py), (end[0]-1,end[1])],p[2],max(1,int(width*.2)))
  if depth>0:
   branch(*end,angle-rng.uniform(.24,.60),length*.68,width*.64,depth-1)
   branch(*end,angle+rng.uniform(.28,.68),length*.67,width*.63,depth-1)
  elif not dead:
   for k in range(9):
    cx=end[0]+rng.randint(-23,23);cy=end[1]+rng.randint(-12,12);r=rng.randint(7,17)
    pts=[(cx+math.cos(a*math.pi/4)*r,cy+math.sin(a*math.pi/4)*r*.55) for a in range(8)]
    poly(d,pts,rng.choice([p[2],p[3],p[3],p[4]]))
    for j in range(6):
     xx=int(cx+rng.randint(-r,r));yy=int(cy+rng.randint(-4,4));d.rectangle((xx,yy,xx+2,yy+1),fill=p[4])
 branch(x,y,-math.pi/2,h*.42,h*.1,4)
 for k in range(6):line(d,[(x,y-15),(x+rng.randint(-45,45),y+4)],p[1],3)
def crystal(d,x,y,h,p,width=24):
 poly(d,[(x-width,y),(x-width*1.3,y-h*.65),(x,y-h),(x+width,y-h*.72),(x+width*.7,y)],p[2])
 poly(d,[(x,y),(x,y-h),(x+width,y-h*.72),(x+width*.7,y)],p[3])
 line(d,[(x-width,y-6),(x-width*1.3,y-h*.65),(x,y-h),(x+width,y-h*.72)],p[4],2)
 line(d,[(x,y-h+8),(x,y-9)],p[5]);line(d,[(x-width*.9,y-h*.6),(x-2,y-h*.83)],p[5])
def gothic(d,x,y,w,h,p,windows=True):
 d.rectangle((x-w,y-h,x+w,y),fill=p[1]);poly(d,[(x-w-8,y-h),(x,y-h-44),(x+w+8,y-h)],p[1])
 line(d,[(x-w,y-h),(x,y-h-42),(x+w,y-h)],p[3],2)
 for xx in range(x-w+12,x+w-8,22):
  for yy in range(y-h+20,y-12,30):
   if windows:
    d.rectangle((xx,yy,xx+7,yy+16),fill=p[3]);d.rectangle((xx+2,yy+2,xx+4,yy+12),fill=p[4]);line(d,[(xx,yy+7),(xx+7,yy+7)],p[1])
 for yy in range(y-h+12,y,19):line(d,[(x-w,yy),(x-w+9,yy)],p[2])
def arch(d,x,y,w,h,p):
 d.rectangle((x-w,y-h*.65,x-w+16,y),fill=p[2]);d.rectangle((x+w-16,y-h*.65,x+w,y),fill=p[2]);
 for i in range(15):
  a=math.pi+math.pi*i/14;xx=x+math.cos(a)*(w-8);yy=y-h*.65+math.sin(a)*h*.35
  d.rectangle((xx-9,yy-9,xx+9,yy+9),fill=p[3] if i%3 else p[4])
def island(d,x,y,w,p):
 poly(d,[(x-w,y),(x+w,y),(x+w*.6,y+35),(x+15,y+75),(x-10,y+55),(x-w*.5,y+46)],p[1])
 poly(d,[(x-10,y+4),(x+15,y+75),(x+w*.6,y+35),(x+w,y)],p[2]);line(d,[(x-w,y),(x+w,y)],p[4],3)
def moon(d,x,y,r,p,eclipse=False):
 for rr,c in [(r+20,mix(p[1],p[2],.4)),(r+9,p[2]),(r,p[3]),(r-3,p[4])]:d.ellipse((x-rr,y-rr,x+rr,y+rr),fill=c)
 d.ellipse((x-r+6,y-r+3,x+r-5,y+r-7),fill=p[5])
 for dx,dy,rr in [(-22,16,10),(13,-19,8),(22,21,5),(-8,-28,4)]:d.ellipse((x+dx-rr,y+dy-rr,x+dx+rr,y+dy+rr),fill=p[4])
 if eclipse:d.ellipse((x-r*.3,y-r-9,x+r+9,y+r*.5),fill=p[1])
def background(idx):
 z,part=divmod(idx,4);p=PALETTES[idx];rng=random.Random(8200+idx);im=Image.new('RGB',(W,H),p[0]);d=ImageDraw.Draw(im)
 for y in range(0,F,2):d.rectangle((0,y,W,y+1),fill=mix(p[0],p[5] if z in [0,1,3] else p[2],(y/F)**1.7*.48))
 if idx in [2,5,8,9,10,11,18]:
  for k in range(180):
   x=rng.randrange(W);y=rng.randrange(80,415);glowstar(d,x,y,mix(p[0],p[5],rng.random()*.55),1)
  moon(d,[990,290,1010,650][part],155,48,p)
 elif z!=4 and idx!=6:
  x=[990,290,1010,650][part];d.ellipse((x-54,99,x+54,207),fill=mix(p[0],p[5],.45));d.ellipse((x-45,108,x+45,198),fill=p[5])
 if z in [0,1,3] and idx not in [2,5,6]:
  for k in range(18 if z==3 else 8):
   x=rng.randint(-80,1280);y=rng.randint(160,500);w=rng.randint(50,130)
   col=mix(p[0],p[5],.62 if z==3 else .30)
   for j in range(5):d.ellipse((x+j*w*.33,y-rng.randrange(10,30),x+(j*.33+1)*w,y+24),fill=col)
 for layer in range(3):mountain(d,rng,410+layer*55,85 if layer else 130,mix(p[0],p[2],.3+layer*.17))
 if z==0:
  for x in range(-30,1320,85):oak(d,rng,x,552,rng.randint(100,165),[p[0],p[1],p[2],p[2],p[3],p[4]],True)
  if part==0:
   oak(d,rng,115,598,370,p);oak(d,rng,1190,598,340,p)
   for x in [310,820,930]:oak(d,rng,x,559,175,p)
   for x in [230,410,820,1025]:
    d.rectangle((x-5,548,x+5,587),fill=p[1]);d.ellipse((x-16,535,x+16,551),fill=p[3]);line(d,[(x-11,540),(x+8,538)],p[4],2)
  elif part==1:
   x=880;poly(d,[(x-65,572),(x-39,304),(x+36,304),(x+65,572)],p[1]);gothic(d,x,478,26,140,p)
   for a in [0,.5*math.pi,math.pi,1.5*math.pi]:
    ux,uy=math.cos(a+.3),math.sin(a+.3);vx,vy=-uy,ux
    poly(d,[(x+ux*15+vx*8,339+uy*15+vy*8),(x+ux*142+vx*20,339+uy*142+vy*20),(x+ux*145-vx*6,339+uy*145-vy*6),(x+ux*15-vx*6,339+uy*15-vy*6)],p[3])
    line(d,[(x,339),(x+ux*148,339+uy*148)],p[4],2)
   oak(d,rng,95,592,310,p,True);oak(d,rng,1190,592,255,p)
   for x in range(330,690,18):line(d,[(x,573),(x,555-rng.randint(0,15))],p[3],1)
  elif part==2:
   gothic(d,700,557,96,206,p);arch(d,700,557,43,115,p)
   for x in [60,150,280,440,885,1000,1150,1210]:
    y=579+rng.randint(-12,6);d.rounded_rectangle((x-15,y-40,x+15,y),radius=8,fill=p[2],outline=p[3]);line(d,[(x,y-32),(x,y-12)],p[4],2);line(d,[(x-7,y-25),(x+7,y-25)],p[4],2)
   oak(d,rng,80,600,300,p,True);oak(d,rng,1165,600,340,p,True)
  else:
   oak(d,rng,800,590,540,p,True);poly(d,[(708,594),(737,427),(790,381),(848,429),(878,594)],p[0]);arch(d,796,592,67,198,p)
   for x in [218,370,1025,1140]:
    d.rectangle((x-5,460,x+5,577),fill=p[1]);d.rectangle((x-10,444,x+10,474),fill=p[3]);d.rectangle((x-4,449,x+4,464),fill=p[5])
  for k in range(850):
   x=rng.randrange(W);y=rng.randrange(564,599);d.rectangle((x,y,x+rng.randint(1,4),y+1),fill=rng.choice([p[2],p[3],p[4]]))
 elif z==1:
  for x in range(0,W,120):pine(d,x,557,rng.randint(90,170),p)
  if part==0:
   d.rectangle((0,498,W,590),fill=p[2]);
   for y in range(500,590,3):
    for k in range(12):
     x=rng.randrange(W);line(d,[(x,y),(x+rng.randint(8,95),y)],p[3] if y%2 else p[1])
   for x in [80,1160]:crystal(d,x,592,180,p,39)
   for x in range(210,1090,80):arch(d,x,590,36,57,p)
  elif part==1:
   gothic(d,745,575,110,180,p);d.ellipse((623,261,867,412),fill=p[2],outline=p[4],width=2);d.rectangle((623,338,867,382),fill=p[2]);line(d,[(668,300),(818,216)],p[3],24);line(d,[(674,298),(817,217)],p[4],4)
   for x in [48,156,1070,1190]:crystal(d,x,590,rng.randint(100,180),p)
  elif part==2:
   poly(d,[(0,0),(W,0),(W,195),(1100,178),(990,242),(840,133),(680,201),(490,158),(325,208),(170,151),(0,230)],p[1])
   for x in range(65,1270,100):
    h=rng.randint(60,150);poly(d,[(x-24,151),(x+24,151),(x+3,151+h)],p[3]);line(d,[(x-20,151),(x+3,151+h)],p[4])
   for x in [50,180,390,900,1120,1210]:crystal(d,x,592,rng.randint(70,150),p,rng.randint(17,35))
  else:
   for x,y,h,w in [(450,568,245,60),(625,570,300,75),(820,570,245,70),(985,570,210,45)]:gothic(d,x,y,w,h,p);crystal(d,x,y-h,60,p,20)
   arch(d,625,567,47,138,p)
   for x in [60,140,1140,1230]:crystal(d,x,591,rng.randint(100,170),p)
  for k in range(700):
   x=rng.randrange(W);y=rng.randrange(557,601);d.rectangle((x,y,x+2,y),fill=p[rng.choice([2,3,4])])
 elif z==2:
  for x in range(15,W,68):gothic(d,x,555,27,rng.randint(90,210),[p[0],p[1],p[1],p[2],p[3],p[3]])
  if part==0:
   for x in range(180,1100,160):arch(d,x,565,74,228,p)
   d.rectangle((150,460,1130,547),fill=p[2]);d.rectangle((153,470,1127,511),fill=p[1]);
   for x in range(172,1120,70):d.rectangle((x,473,x+49,503),fill=p[3]);d.rectangle((x+2,476,x+46,480),fill=p[4]);d.ellipse((x+7,536,x+27,556),fill=p[0])
   line(d,[(140,555),(1140,555)],p[4],2)
  elif part==1:
   for x,h in [(110,260),(300,200),(955,225),(1180,300)]:
    gothic(d,x,580,80,h,p);d.rectangle((x-29,580-h+45,x+29,580-h+110),fill=p[0]);d.rectangle((x-26,580-h+48,x+26,580-h+107),outline=p[4],width=2)
    for k in range(4):line(d,[(x-12,580-h+60+k*10),(x+12-k*3,580-h+60+k*10)],p[5],2)
   for x in range(170,1130,80):line(d,[(x,330),(x+70,342)],p[3]);d.ellipse((x+12,334,x+20,347),fill=p[4])
  elif part==2:
   for x in [355,900]:
    d.rounded_rectangle((x-72,280,x+72,580),radius=32,fill=p[1],outline=p[3],width=3)
    for y in range(315,560,40):d.rectangle((x-60,y,x+60,y+4),fill=p[3])
    d.rectangle((x-24,324,x+24,522),fill=p[3]);d.rectangle((x-8,338,x+8,510),fill=p[6])
   for x in [120,1140]:line(d,[(x,580),(x,400),(x+90,400)],p[3],16)
  else:
   gothic(d,850,585,128,350,p);gothic(d,690,585,54,230,p);gothic(d,1045,585,49,240,p)
   for k in range(4):d.ellipse((789+k*6,185+k*6,911-k*6,307-k*6),outline=p[3],width=2)
   line(d,[(0,214),(1280,336)],p[3],2)
  for x in range(0,W,30):line(d,[(x,584),(x+16,584)],p[4],2)
 elif z==3:
  for k in range(8):
   x=rng.randrange(W);y=rng.randrange(340,555);island(d,x,y,rng.randint(35,90),p)
  if part==0:
   # The monumental double door makes paradise immediately recognizable.
   x=656;d.rounded_rectangle((x-115,224,x+115,562),radius=112,fill=p[1],outline=p[5],width=7)
   d.rounded_rectangle((x-98,239,x+98,562),radius=95,fill='#fff4d0',outline=p[4],width=4)
   d.rectangle((x-115,392,x+115,562),fill=p[1]);d.rectangle((x-98,392,x+98,562),fill='#fff4d0',outline=p[4],width=4)
   # Marble relief, stepped threshold and engraved gold work.
   for yy in [565,578,591]:
    half=128+(yy-565)*1.2;d.rectangle((x-half,yy,x+half,yy+9),fill=p[3],outline=p[5],width=1)
   line(d,[(x,246),(x,559)],p[4],3)
   for side in [-1,1]:
    xx=x+side*53
    for yy in [353,435,518]:d.rectangle((xx-28,yy-30,xx+28,yy+25),outline=p[4],width=2)
    for yy in [353,435,518]:
     poly(d,[(xx,yy-16),(xx+8,yy-3),(xx,yy+10),(xx-8,yy-3)],p[4]);line(d,[(xx,yy-12),(xx,yy+6)],p[5])
    d.ellipse((x+side*13-4,460,x+side*13+4,468),fill=p[4])
   for xx in [x-135,x+135]:
    d.rectangle((xx-14,262,xx+14,571),fill=p[3],outline=p[5],width=3);d.rectangle((xx-24,254,xx+24,270),fill=p[4])
    for dx in [-7,0,7]:line(d,[(xx+dx,279),(xx+dx,558)],'#d4cdb8',1)
   d.ellipse((x-38,196,x+38,221),outline=p[5],width=4)
   for x in [150,1090]:island(d,x,499,130,p);arch(d,x,497,47,150,p)
   for x in [130,215,980,1090,1160]:
    line(d,[(x,491),(x+13,440)],p[3],2);d.ellipse((x+3,427,x+24,445),fill=p[4]);glowstar(d,x+14,435,p[5],3)
  elif part==1:
   poly(d,[(470,395),(970,395),(912,454),(558,454)],p[2]);line(d,[(470,395),(970,395)],p[4],3)
   for x in [615,795]:
    line(d,[(x,430),(x,214)],p[3],6);poly(d,[(x+6,230),(x+6,377),(x+121,365)],p[3]);line(d,[(x+9,237),(x+115,362)],p[4])
   for x in [150,1130]:arch(d,x,576,55,151,p)
  elif part==2:
   for x in [260,490,720,950]:arch(d,x,564,100,272,p)
   for x in [200,650,1100]:gothic(d,x,580,35,330,p)
   for x in range(535,748,24):
    h=100+int(65*math.cos((x-640)/110));d.rectangle((x,520-h,x+12,558),fill=p[3],outline=p[4],width=2)
   d.rectangle((525,546,758,562),fill=p[4])
  else:
   for k in range(5):
    r=90+k*20;d.ellipse((760-r,290-r,760+r,290+r),outline=mix(p[4],p[5],k*.13),width=3)
   arch(d,760,565,113,310,p)
   d.rectangle((700,445,820,551),fill=p[3],outline=p[4],width=4)
   poly(d,[(698,445),(707,411),(734,435),(760,402),(786,435),(813,411),(822,445)],p[4])
   for x in [80,240,1060,1200]:island(d,x,560,50,p)
  for y in range(525,585,7):
   x=rng.randrange(W-100);d.rectangle((x,y,x+rng.randint(40,230),y+2),fill=p[2])
 else:
  d.rectangle((0,521,W,600),fill='#e07c3c');
  for y in range(530,600,4):
   for k in range(12):
    x=rng.randrange(W);line(d,[(x,y),(x+rng.randint(10,70),y)],rng.choice(['#fba14b','#ffd58a','#b85639']),2)
  if part==0:
   for x in range(0,W,220):arch(d,x,590,100,130,p)
   for x in [150,1130]:
    line(d,[(x-60,583),(x-32,404),(x+5,388),(x+37,413),(x+63,585)],p[2],20);line(d,[(x-40,488),(x+45,488)],p[3],4)
  elif part==1:
   for x in [190,1090]:
    for y in range(90,460,18):d.ellipse((x-5,y,x+5,y+20),outline=p[3],width=2)
    poly(d,[(x-75,461),(x+75,461),(x+47,489),(x+14,494),(x+14,526),(x+44,543),(x-44,543),(x-14,526),(x-14,494),(x-55,487)],p[2]);line(d,[(x-72,462),(x+72,462)],p[5],3)
   for x in [440,665,855]:arch(d,x,564,70,210,p);d.rectangle((x-40,418,x+40,555),fill=p[3]);d.rectangle((x-20,449,x+20,555),fill=p[4])
  elif part==2:
   for x in [110,270,460,645,850,1060,1210]:gothic(d,x,574,rng.randint(40,65),rng.randint(180,330),p)
   for x in [220,560,985]:crystal(d,x,580,150,p,22)
  else:
   poly(d,[(292,561),(532,263),(597,245),(643,273),(714,239),(786,260),(1020,561)],p[1]);poly(d,[(532,263),(597,245),(643,273),(714,239),(786,260),(760,295),(705,294),(661,332),(603,297),(558,313)],p[4]);
   for x in [583,695,742]:line(d,[(x,285),(x-20,371),(x+12,430),(x-1,543)],p[3],11);line(d,[(x,288),(x-20,371),(x+12,430),(x-1,543)],p[4],3)
   for x in [35,1200]:crystal(d,x,599,290,p,45)
 # Crisp native-pixel stage, with a calm combat silhouette and detailed underside.
 d.rectangle((0,F,W,H),fill=mix(p[1],'#10172c',.2));d.rectangle((0,F,W,F+9),fill=p[3] if z==3 else p[2]);d.line((0,F,W,F),fill=p[5] if z==3 else p[4],width=2)
 for x in range(0,W,16):
  deep=rng.randint(10,28);d.rectangle((x,F+9,x+15,F+deep),fill=p[1]);line(d,[(x,F+9),(x,F+deep)],p[3])
 for row,y in enumerate(range(F+29,H,23)):
  for x in range(-50,W,54):
   xx=x+(row%2)*27;d.rectangle((xx,y,xx+49,y+19),fill=p[1]);line(d,[(xx+2,y),(xx+46,y)],p[2]);line(d,[(xx+2,y+2),(xx+2,y+14)],mix(p[1],p[2],.45))
 for k in range(1400):
  x=rng.randrange(W);y=rng.randrange(F+5,H);d.point((x,y),fill=rng.choice([p[1],p[2],p[3]]))
 im.save(OUT/f'arena_{idx:02}.png',optimize=True)
for idx in range(20):background(idx)
print('20 unique 1280x720 environment paintings generated.')
# Directional character. Eight frames per action, native 64px, independent gun arm.
INK='#101728';METAL='#37617a';LIT='#9dded4';SKIN='#f1dfb6';RED='#dc6e7f';GOLD='#e9b683'
hero=Image.new('RGBA',(512,384))
for row in range(6):
 for frame in range(8):
  im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im);phase=frame*math.tau/8
  bob=round(math.sin(phase*2)) if row==1 else (frame//4 if row==0 else 0)
  dy=14 if row==3 else 0
  # flowing red scarf behind the character, visibly opposite to facing
  poly(d,[(25,29+dy),(12,27+dy),(3,30+int(math.sin(phase)*2)+dy),(8,33+dy),(2,37+dy),(19,34+dy),(27,35+dy)],INK)
  poly(d,[(24,30+dy),(13,29+dy),(7,31+dy),(12,32+dy),(7,35+dy),(20,32+dy)],RED)
  if row!=3:
   # Back arm, legs and large expressive boots; separate frames rather than position swapping.
   arm_swing=math.sin(phase)*4 if row==1 else 0
   line(d,[(23,36+bob),(17+arm_swing,44+bob),(20+arm_swing,48+bob)],INK,7)
   d.ellipse((16+arm_swing,43+bob,23+arm_swing,50+bob),fill=SKIN,outline=INK,width=1)
   for side in [-1,1]:
    stride=math.sin(phase+(0 if side==1 else math.pi))*9 if row==1 else side*4
    knee=(30+side*4+stride*.45,52-abs(stride)*.18)
    foot=(30+side*4+stride,61-abs(stride)*.25)
    if row==2:knee=(30+side*11,49+side*3);foot=(30+side*14,55+side*2)
    if row==4:knee=(26+side*10,52);foot=(20+side*15,56)
    line(d,[(29+side*3,45+bob),knee,foot],INK,8);line(d,[(29+side*3,46+bob),knee,foot],METAL,4)
    d.rounded_rectangle((foot[0]-4,foot[1]-3,foot[0]+8,foot[1]+1),radius=2,fill=INK);line(d,[(foot[0]-2,foot[1]-2),(foot[0]+5,foot[1]-2)],LIT,2)
  else:
   d.rounded_rectangle((21,54,47,62),radius=3,fill=INK);d.rectangle((23,55,43,59),fill=METAL);line(d,[(25,61),(45,61)],LIT,2)
  # Tailored coat and belt.
  poly(d,[(24,29+dy),(37,29+dy),(42,43+dy*.6),(35,49+dy*.6),(22,47+dy*.6),(20,38+dy)],INK)
  poly(d,[(25,31+dy),(35,31+dy),(38,42+dy*.6),(33,46+dy*.6),(24,44+dy*.6)],METAL)
  line(d,[(25,33+dy),(24,41+dy*.6)],LIT,2);d.rectangle((25,43+dy*.6,37,45+dy*.6),fill=GOLD)
  # Three-quarter face with unmistakable right-facing nose and eye.
  hy=dy+bob
  d.ellipse((17,5+hy,44,31+hy),fill=INK)
  d.ellipse((19,6+hy,43,29+hy),fill=METAL)
  poly(d,[(20,13+hy),(25,7+hy),(37,7+hy),(41,12+hy),(40,15+hy),(25,15+hy),(24,24+hy),(19,21+hy)],'#578d9c')
  line(d,[(24,8+hy),(34,7+hy),(39,10+hy)],LIT,2)
  d.ellipse((27,13+hy,45,29+hy),fill=SKIN)
  poly(d,[(41,19+hy),(48,21+hy),(46,24+hy),(41,24+hy)],INK);poly(d,[(42,20+hy),(46,21+hy),(44,23+hy),(41,23+hy)],GOLD)
  d.ellipse((35,15+hy,40,22+hy),fill=INK);d.point((37,16+hy),fill='#ffffff');line(d,[(34,13+hy),(40,14+hy)],INK)
  line(d,[(38,27+hy),(43,26+hy)],'#9e6265')
  d.ellipse((18,16+hy,25,23+hy),fill=INK);d.ellipse((20,17+hy,24,21+hy),fill=GOLD)
  poly(d,[(24,8+hy),(22,2+hy),(27,4+hy),(30,7+hy)],INK);line(d,[(24,3+hy),(27,6+hy)],LIT,2)
  # Scarf collar, fabric highlights, forward shoulder.
  d.rounded_rectangle((22,28+dy+bob,39,33+dy+bob),radius=2,fill=INK);line(d,[(24,29+dy+bob),(37,30+dy+bob)],RED,3)
  d.ellipse((31,34+dy*.65,40,42+dy*.65),fill=INK);d.ellipse((33,35+dy*.65,39,40+dy*.65),fill=METAL)
  if row==5:
   from PIL import ImageEnhance
   im=ImageEnhance.Brightness(im).enhance(1.45)
  hero.alpha_composite(im,(frame*64,row*64))
hero.save(OUT/'nilo_actions.png')
arm=Image.new('RGBA',(34,18));d=ImageDraw.Draw(arm)
d.rounded_rectangle((0,6,18,13),radius=3,fill=INK);d.rectangle((2,7,12,11),fill=METAL)
d.ellipse((11,4,24,16),fill=INK);d.ellipse((12,5,22,14),fill=SKIN);line(d,[(14,7),(19,7)],'#fff8d8')
d.rectangle((20,3,30,10),fill=INK);d.rectangle((21,4,29,8),fill='#4e9caa');d.rectangle((28,2,32,11),fill=INK);d.rectangle((29,4,32,9),fill=LIT)
arm.save(OUT/'nilo_arm.png')
# Three roles per level, with local costumes and eight animation frames.
for idx,p in enumerate(PALETTES):
 z,part=divmod(idx,4)
 sheet=Image.new('RGBA',(576,216))
 for role in range(3):
  for frame in range(8):
   im=Image.new('RGBA',(72,72));d=ImageDraw.Draw(im);wind=frame in [4,5];attack=frame in [6,7];bob=1 if frame%2 else 0
   ink='#101421';base=mix(p[3],p[4],.4);light=p[5];accent=['#edaa70','#8ce2ee','#f48fc5','#ccb5fa','#f58b6d'][z]
   if role==2 or z==3:
    flap=5 if frame%2 else -3
    for side in [-1,1]:
     poly(d,[(36+side*8,33),(36+side*30,16+flap),(36+side*27,38+flap),(36+side*16,44),(36+side*8,49)],ink)
     poly(d,[(36+side*10,34),(36+side*27,20+flap),(36+side*23,36+flap),(36+side*13,42)],'#fff8e7' if z==3 else base)
     line(d,[(36+side*11,34),(36+side*27,20+flap)],light,2)
     if z==3:
      for k in range(3):line(d,[(36+side*(13+k*4),38-k*2),(36+side*(24+k*2),25+flap+k*3)],'#c3d9e5',1)
   for side in [-1,1]:
    x=36+side*11+(2 if frame%2 else -2)*side
    d.rounded_rectangle((x-6,56+bob,x+6,65+bob),radius=3,fill=ink);line(d,[(x-3,57+bob),(x+3,58+bob)],light,2)
   d.ellipse((17,23+bob,55,63+bob),fill=ink);d.ellipse((20,25+bob,52,60+bob),fill=base)
   d.ellipse((25,32+bob,48,57+bob),fill=p[2]);line(d,[(26,28+bob),(44,28+bob)],accent,2)
   if z==0:
    poly(d,[(19,30),(14,14),(22,20),(26,11),(31,25),(39,24),(47,10),(49,21),(59,15),(53,35)],ink)
    line(d,[(19,26),(17,17),(24,23),(27,15)],accent,2);line(d,[(46,24),(48,15),(49,26),(56,20)],accent,2)
   elif z==1:
    for x in [23,35,47]:crystal(d,x,34,23+(x%4)*3,[p[0],ink,p[2],base,accent,light],5)
   elif z==2:
    d.rounded_rectangle((15,19,57,42),radius=5,fill=ink);d.rectangle((18,22,54,39),fill=base);d.rectangle((31,9,40,17),fill=accent);line(d,[(35,15),(35,22)],light,2)
   elif z==3:
    d.ellipse((20,18,52,45),fill=ink);d.ellipse((22,20,50,43),fill='#f2d7af')
    d.arc((22,18,50,42),180,355,fill='#d5a557',width=6)
    poly(d,[(23,44),(49,44),(54,60),(18,60)],'#fff4df');line(d,[(23,47),(48,47)],'#d5a557',3)
    d.ellipse((24,5,49,14),outline='#614c48',width=3);d.ellipse((25,5,48,12),outline='#ffe8a0',width=2)
   else:
    poly(d,[(20,34),(9,13),(15,5),(23,22),(30,29),(44,29),(51,22),(57,5),(63,13),(53,36)],ink);line(d,[(21,28),(13,14),(16,9)],accent,3);line(d,[(51,28),(59,14),(56,9)],accent,3)
   # Local headgear changes silhouette, beyond the palette.
   if part==1:
    if z in [0,1,4]:
     poly(d,[(13,24),(25,12),(41,13),(53,24)],ink);d.rectangle((18,22,54,27),fill=p[4]);line(d,[(25,16),(39,16)],light,2)
    elif z==2:d.rectangle((16,15,55,25),fill=ink);d.rectangle((19,18,52,23),fill=accent)
    else:d.rectangle((25,15,47,20),fill='#fff3d2');line(d,[(25,20),(47,20)],'#4f83aa',2)
   elif part==2:
    for x in [22,35,48]:poly(d,[(x-4,26),(x,13),(x+4,26)],p[4])
   elif part==3:
    poly(d,[(20,26),(18,13),(28,19),(35,9),(43,19),(54,13),(51,26)],ink)
    poly(d,[(23,23),(22,17),(29,22),(35,14),(42,22),(50,18),(48,23)],'#e6bc6b')
   # Contrasting eyes and an open attack mouth read against light or dark scenery.
   eye='#fff0a9' if not wind else '#ff9e5c'
   d.ellipse((23,30+bob,32,39+bob),fill=ink);d.ellipse((40,30+bob,49,39+bob),fill=ink)
   d.rectangle((25,32+bob,30,35+bob),fill=eye);d.rectangle((42,32+bob,47,35+bob),fill=eye)
   d.point((28,32+bob),fill='#ffffff');d.point((45,32+bob),fill='#ffffff')
   d.rounded_rectangle((28,44+bob,44,54+bob if attack else 49+bob),radius=2,fill=ink)
   if attack:d.rectangle((32,47+bob,41,51+bob),fill=accent)
   elif z==3:line(d,[(31,46+bob),(40,46+bob)],'#926147',2)
   else:line(d,[(30,44+bob),(32,46+bob),(35,44+bob),(38,46+bob),(41,44+bob)],light)
   if role==0:
    line(d,[(54,36),(60,60)],ink,7);line(d,[(54,36),(60,59)],accent,3);d.ellipse((47,25,61,39),fill=ink);d.ellipse((50,28,58,36),fill='#ffd69a' if wind else accent)
   if role==1:
    for x in [16,53]:d.rounded_rectangle((x-7,42,x+7,54),radius=4,fill=ink);d.rectangle((x-4,43,x+4,49),fill=accent)
   sheet.alpha_composite(im,(frame*72,role*72))
 sheet.save(OUT/f'inhabitants_{idx:02}.png')
def celestial_object(d,n):
 ink='#313650';gold='#d7aa51';white='#fff7df';blue='#93cbea'
 if n in [1,15]:
  # Grand piano / pipe organ, keys, feet and raised lid, readable in 48 pixels.
  d.rounded_rectangle((3,17,44,36),radius=3,fill=ink,outline=gold,width=2)
  poly(d,[(5,16),(35,3),(44,10),(44,17)],gold);line(d,[(7,15),(34,6),(41,10)],white,2)
  d.rectangle((5,27,42,34),fill=white)
  for x in range(8,41,5):line(d,[(x,28),(x,33)],ink)
  for x in [10,15,25,30,35]:d.rectangle((x,27,x+2,30),fill=ink)
  for x in [8,36]:line(d,[(x,36),(x-2,43)],ink,3)
  if n==15:
   for x in range(9,43,6):d.rectangle((x,5+(x%5)*2,x+3,24),fill=gold,outline=ink)
 elif n in [2,10]:
  line(d,[(4,24),(37,24)],ink,7);line(d,[(5,24),(37,24)],gold,3)
  poly(d,[(32,15),(46,24),(32,33)],ink);poly(d,[(35,19),(42,24),(35,29)],white)
  for x in [5,10,15]:line(d,[(x,23),(x-3,16)],blue,3);line(d,[(x,25),(x-3,32)],white,3)
 elif n in [0,8]:
  poly(d,[(7,39),(12,15),(28,3),(41,8),(39,24),(17,39)],ink)
  poly(d,[(11,35),(16,16),(29,7),(37,10),(35,23),(17,35)],white if n==0 else gold)
  line(d,[(8,42),(32,12)],gold if n==0 else white,2)
  for k in range(4):line(d,[(16+k*4,32-k*5),(28+k*3,29-k*5)],blue)
 elif n in [3,11]:
  d.ellipse((18,4,29,13),outline=ink,width=2);poly(d,[(16,12),(32,12),(35,29),(42,34),(42,38),(6,38),(6,34),(13,29)],ink)
  poly(d,[(18,15),(30,15),(33,31),(38,34),(10,34),(15,31)],gold)
  line(d,[(21,16),(19,29)],white,3);d.ellipse((20,37,28,43),fill=gold)
  if n==11:line(d,[(18,4),(11,0)],gold);line(d,[(29,4),(36,0)],gold)
 elif n in [4,12]:
  pts=[(24+math.cos(-math.pi/2+k*math.pi/5)*(22 if k%2==0 else 10),24+math.sin(-math.pi/2+k*math.pi/5)*(22 if k%2==0 else 10)) for k in range(10)]
  poly(d,pts,ink);poly(d,[(24+(x-24)*.83,24+(y-24)*.83) for x,y in pts],gold)
  line(d,[(24,9),(23,23),(13,27)],white,2)
 elif n==5:
  poly(d,[(5,15),(12,15),(15,23),(29,23),(40,12),(44,13),(44,37),(40,38),(29,28),(12,28)],ink)
  poly(d,[(8,18),(10,18),(13,25),(30,25),(41,16),(41,34),(30,26),(13,26)],gold)
  line(d,[(16,22),(16,17),(23,17),(23,22)],white,2)
 elif n==6:
  d.rectangle((12,6,36,11),fill=gold,outline=ink);d.rectangle((16,12,32,36),fill=white,outline=ink);d.rectangle((10,37,38,43),fill=gold,outline=ink)
  for x in [20,25,29]:line(d,[(x,14),(x,34)],blue)
 elif n==7:
  poly(d,[(25,2),(10,27),(23,27),(19,46),(41,18),(28,18),(35,2)],ink);poly(d,[(26,7),(16,24),(27,24),(24,35),(36,21),(24,21),(30,7)],gold)
 elif n==9:
  poly(d,[(8,7),(35,5),(42,13),(34,39),(14,43),(8,35)],ink);line(d,[(11,10),(33,8),(38,14),(31,36),(16,39),(11,33),(11,10)],gold,4)
  for k in range(5):line(d,[(15+k*4,11),(15+k*3,35)],white)
 elif n==13:
  poly(d,[(41,3),(39,25),(25,42),(8,39),(4,28),(12,17)],ink);poly(d,[(38,8),(33,27),(23,37),(11,35),(9,27),(17,20)],blue);d.ellipse((9,23,25,38),fill=gold);d.ellipse((11,25,22,34),fill=white)
 else:
  d.ellipse((5,5,43,43),fill=ink);d.ellipse((8,8,40,40),fill=gold);d.ellipse((12,12,36,36),fill=white)
  line(d,[(24,15),(24,25),(31,28)],ink,2)

# Clearly outlined hazards: sixteen named objects per region, 48px cells.
for z,p in enumerate(P):
 sheet=Image.new('RGBA',(768,48))
 for n in range(16):
  im=Image.new('RGBA',(48,48));d=ImageDraw.Draw(im);a=['#f4b17d','#9de4ed','#f3a0cf','#d1b9ef','#ffa883'][z] if n<8 else '#edc99e';b='#fff2ce';ink='#191b2e';kind=n%8
  if kind in [0,2,7]:
   pts=[(8,32),(14,10),(26,5),(40,13),(35,29),(22,42)] if kind==0 else [(10,39),(18,7),(27,19),(35,3),(40,33),(28,43)] if kind==7 else [(8,38),(15,9),(38,5),(32,29),(20,42)]
   poly(d,pts,ink);poly(d,[(24+(x-24)*.83,24+(y-24)*.83) for x,y in pts],a);line(d,[(18,32),(28,13)],b,2);line(d,[(22,33),(33,18)],p[3],2)
  elif kind==1:
   for i in range(8):
    angle=i*math.tau/8;cx=24+math.cos(angle)*15;cy=24+math.sin(angle)*15
    poly(d,[(cx-4,cy-4),(24+math.cos(angle)*22,24+math.sin(angle)*22),(cx+4,cy+4)],ink)
   d.ellipse((7,7,41,41),fill=ink);d.ellipse((10,10,38,38),fill=a);d.arc((12,12,36,36),190,270,fill=b,width=2);d.ellipse((18,19,25,26),fill=p[3])
  elif kind==3:
   d.ellipse((8,11,39,40),fill=ink);d.ellipse((11,14,36,37),fill=a);d.rectangle((15,21,20,26),fill=ink);d.rectangle((28,21,33,26),fill=ink);line(d,[(18,31),(29,31)],ink,2);line(d,[(25,12),(30,5),(35,7)],b,2);glowstar(d,35,6,'#ffd187',3)
  elif kind==4:
   poly(d,[(8,12),(20,12),(25,6),(29,13),(40,14),(34,33),(24,42),(12,32)],ink);poly(d,[(12,16),(24,12),(36,17),(31,30),(24,37),(16,29)],a);line(d,[(14,18),(21,16)],b,2);line(d,[(25,16),(29,29)],p[3],2)
  elif kind==5:
   poly(d,[(3,24),(10,7),(20,18),(29,18),(39,7),(45,24),(33,38),(15,38)],ink);poly(d,[(7,23),(11,13),(20,23),(28,23),(38,13),(41,23),(31,33),(17,33)],a);d.rectangle((18,24,22,27),fill=b);d.rectangle((27,24,31,27),fill=b)
  else:
   d.rounded_rectangle((10,6,38,42),radius=4,fill=ink);d.rectangle((13,10,35,38),fill=a);d.rectangle((14,11,34,14),fill=b);d.rectangle((19,20,29,30),fill=p[3]);line(d,[(25,18),(21,25),(27,25),(23,32)],b,2)
  if z==3:
   im=Image.new('RGBA',(48,48));d=ImageDraw.Draw(im);celestial_object(d,n)
  elif z==4 and n==14:
   im=Image.new('RGBA',(48,48));d=ImageDraw.Draw(im)
   poly(d,[(3,11),(44,11),(39,21),(29,25),(29,33),(37,39),(37,43),(11,43),(11,39),(19,33),(19,25),(10,22)],ink)
   poly(d,[(7,14),(40,14),(36,19),(27,22),(27,34),(32,39),(16,39),(21,34),(21,22),(12,19)],'#b57565');line(d,[(8,14),(39,14)],'#ffd694',3)
  elif n>=8:glowstar(d,38,7,'#ffd18e',3)
  sheet.alpha_composite(im,(n*48,0))
 sheet.save(OUT/f'threats_{z}.png')
# Large expressive bosses, four poses. All characters are original.
for z,p in enumerate(P):
 p=PALETTES[z*4+3]
 sheet=Image.new('RGBA',(768,192))
 for frame in range(4):
  im=Image.new('RGBA',(192,192));d=ImageDraw.Draw(im);ink='#101222';accent=p[4];light=p[5];wind=frame==2;attack=frame==3
  poly(d,[(39,169),(29,113),(43,66),(69,36),(98,27),(131,44),(154,78),(164,123),(151,170),(119,182),(68,182)],ink)
  poly(d,[(46,165),(39,112),(52,70),(73,47),(99,38),(125,52),(145,83),(154,125),(143,164),(116,174),(72,174)],'#f7e9cc' if z==3 else p[2])
  poly(d,[(50,113),(60,76),(89,54),(100,54),(84,88),(79,144),(99,170),(70,165)],p[3])
  if z==0:
   for x,side in [(59,-1),(134,1)]:
    line(d,[(x,70),(x+side*8,34),(x+side*27,14)],ink,12);line(d,[(x,66),(x+side*8,34),(x+side*27,14)],accent,5);line(d,[(x+side*8,34),(x-side*5,12)],accent,4)
   for k in range(35):
    angle=k*math.pi/35+math.pi;xx=96+math.cos(angle)*50;yy=75+math.sin(angle)*34;d.ellipse((xx-5,yy-2,xx+6,yy+3),fill=p[3 if k%2 else 4])
  elif z==1:
   for x,h in [(54,40),(75,55),(99,66),(125,51),(145,35)]:crystal(d,x,79,h,[p[0],ink,p[2],p[3],accent,light],10)
  elif z==2:
   d.rounded_rectangle((29,55,164,129),radius=9,fill=ink,outline=accent,width=3);d.rectangle((37,63,156,118),fill=p[2]);line(d,[(96,52),(96,22)],accent,4);d.ellipse((85,10,108,29),fill=ink,outline=light,width=2)
   for y in range(68,116,5):line(d,[(41,y),(152,y)],p[3])
  elif z==3:
   for side in [-1,1]:
    for k in range(5):
     poly(d,[(96+side*46,79+k*7),(96+side*90,24+k*16),(96+side*83,70+k*13),(96+side*42,124)],ink)
     poly(d,[(96+side*49,80+k*7),(96+side*87,30+k*16),(96+side*80,69+k*13),(96+side*45,119)],'#fff7e1');line(d,[(96+side*49,80+k*7),(96+side*87,30+k*16)],accent,2)
   d.ellipse((64,9,129,28),outline=light,width=3)
  else:
   for side in [-1,1]:
    poly(d,[(96+side*26,68),(96+side*53,49),(96+side*70,11),(96+side*83,25),(96+side*76,56),(96+side*45,89)],ink)
    poly(d,[(96+side*34,66),(96+side*58,47),(96+side*69,20),(96+side*75,29),(96+side*69,51),(96+side*44,78)],accent)
    line(d,[(96+side*70,23),(96+side*61,46)],light,2)
  for x in [60,111]:
   d.ellipse((x-4,84,x+28,108),fill=ink);d.rectangle((x,89,x+23,98),fill='#ffb17c' if wind else light);d.rectangle((x+9,88,x+13,99),fill='#ffffff');line(d,[(x-5,80),(x+28,87)],ink,5)
  d.rounded_rectangle((68,126,125,159 if attack else 147),radius=7,fill=ink)
  for x in range(75,121,11):poly(d,[(x,127),(x+7,127),(x+4,136)],light)
  if attack:d.ellipse((82,145,115,158),fill=accent)
  for x,y in [(49,123),(139,120),(70,162),(118,164)]:line(d,[(x,y),(x+7,y+3)],accent,2)
  sheet.alpha_composite(im,(frame*192,0))
 sheet.save(OUT/f'guardian_{z}.png')
print('Animated Nilo, gun arm, 60 local enemy costumes, 80 threats and five expressive bosses generated.')
