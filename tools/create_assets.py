"""Original Pixel Panic pixel art and synthesized audio. No external assets needed.
Run with Python 3 + Pillow. All textures are drawn at their native pixel resolution.
"""
from PIL import Image, ImageDraw
import random, math, wave, struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'assets/art'; AUDIO=ROOT/'assets/audio'
ART.mkdir(parents=True,exist_ok=True); AUDIO.mkdir(parents=True,exist_ok=True)
P=[['#090d19','#131a2b','#282339','#553047','#914653','#cf886d','#afcfc1'],
   ['#091122','#14243b','#244054','#345f76','#6a9eae','#b5d5d7','#baa4d8'],
   ['#0a0c1c','#18172e','#2d233e','#593453','#a24a84','#d995b2','#7dc6b6'],
   ['#0d1023','#1e223c','#373551','#5a527a','#95718d','#d4aa9f','#96c4cf'],
   ['#110a1a','#261225','#491d33','#7d2b3f','#c74a43','#e99e66','#b6c9a4']]

def poly(d,p,c): d.polygon([(int(x),int(y)) for x,y in p], fill=c)
def star(d,x,y,c,s=1):
 d.rectangle((x-s,y,x+s,y),fill=c);d.rectangle((x,y-s,x,y+s),fill=c)
def tree(d,x,y,size,p,rng):
 # angular trunk, layered blocky clusters
 poly(d,[(x-4,y),(x-3,y-size*.62),(x-15,y-size*.83),(x-9,y-size*.85),(x+2,y-size*.62),(x+12,y-size*.83),(x+17,y-size*.83),(x+5,y-size*.48),(x+6,y)],p[1])
 for k in range(30):
  cx=x+rng.randrange(-int(size*.43),int(size*.43)); cy=y-size*.72+rng.randrange(-int(size*.25),int(size*.1)); w=rng.randrange(7,19)
  d.rectangle((cx-w,cy-5,cx+w,cy+6),fill=p[rng.choice([2,3,3,4])])
  if k%3==0:d.line((cx-w,cy-5,cx+w-3,cy-5), fill=p[5],width=1)
def crystal(d,x,y,h,p):
 poly(d,[(x-10,y),(x-16,y-h*.65),(x,y-h),(x+14,y-h*.7),(x+10,y)],p[3]);poly(d,[(x,y),(x,y-h),(x+14,y-h*.7),(x+10,y)],p[4]);d.line((x,y-h,x-12,y-h*.65),fill=p[5],width=2)
def city(d,x,y,h,p,rng):
 d.rectangle((x-14,y-h,x+14,y),fill=p[1]);d.rectangle((x-14,y-h,x+14,y-h+3),fill=p[3])
 for xx in range(x-10,x+12,8):
  for yy in range(y-h+9,y-3,11):
   if rng.random()<.55:d.rectangle((xx,yy,xx+2,yy+4),fill=rng.choice([p[3],p[4],p[6]]))
def background(z):
 p=P[z]; rng=random.Random(511+z); im=Image.new('RGB',(640,360),p[0]);d=ImageDraw.Draw(im)
 # Deliberately stepped color bands: no smooth gradients or shaders.
 for y in range(24,292,6):
  t=(y/310)*.8; a=tuple(int(p[0][i:i+2],16) for i in (1,3,5));b=tuple(int(p[2][i:i+2],16) for i in (1,3,5))
  c=tuple(int(a[i]*(1-t)+b[i]*t) for i in range(3));d.rectangle((0,y,639,y+5),fill=c)
 for _ in range(95):
  x=rng.randrange(640); y=rng.randrange(10,225);star(d,x,y,p[rng.choice([2,3,5])],0 if rng.random()<.8 else 1)
 # celestial focal point
 mx,my=(464,77) if z!=4 else (450,103)
 d.ellipse((mx-43,my-43,mx+43,my+43),fill=p[2]);d.ellipse((mx-34,my-34,mx+34,my+34),fill=p[4]);d.ellipse((mx-29,my-32,mx+29,my+26),fill=p[5])
 if z in (0,2):d.ellipse((mx-8,my-40,mx+39,my+15),fill=p[1])
 if z==4:
  for y in range(my-25,my+25,7):d.rectangle((mx-30,y,mx+30,y+2),fill=p[3])
 for layer in range(3):
  base=196+layer*31
  pts=[(-20,300),(-20,base)]
  for x in range(-20,681,30):pts.append((x,base-rng.randrange(9,67)))
  pts.extend([(680,300)]);poly(d,pts,p[1 if layer==0 else 2])
  if layer==0:
   for i in range(10):
    x=rng.randrange(640); y=base-rng.randrange(20,50); d.rectangle((x,y,x+24,y+2),fill=p[3])
 # atmosphere bands and drifting distant clouds
 for _ in range(12):
  x=rng.randrange(-40,600); y=rng.randrange(86,238);w=rng.randrange(30,110)
  d.rectangle((x,y,x+w,y+2),fill=p[2]);d.rectangle((x+8,y-2,x+w-9,y),fill=p[2])
 if z==0:
  for x,y,s in [(55,281,146),(154,280,90),(610,280,155),(520,281,86)]:tree(d,x,y,s,p,rng)
  for _ in range(85):
   x=rng.randrange(640);y=rng.randrange(240,285);d.rectangle((x,y,x+3,y+1),fill=rng.choice(p[3:6]))
 elif z==1:
  for x,h in [(30,96),(86,47),(155,62),(517,76),(582,140),(623,57)]:crystal(d,x,288,h,p)
  for x in range(10,640,18):
   y=272+rng.randrange(12);d.rectangle((x,y,x+7,y+2),fill=p[3])
 elif z==2:
  for x in [35,82,130,501,550,600]:city(d,x,285,rng.randrange(50,140),p,rng)
  d.line((0,170,640,210),fill=p[3]);d.line((0,167,640,207),fill=p[1]);
  for x in range(15,640,60):d.rectangle((x,172+x//16,x+4,179+x//16),fill=p[6])
 elif z==3:
  for x in [27,110,528,604]:
   y=165+rng.randrange(50);d.rectangle((x-8,y,x+8,290),fill=p[2]);d.rectangle((x-12,y-7,x+12,y),fill=p[4]);d.rectangle((x-10,y-7,x+9,y-5),fill=p[5]);d.line((x-3,y+5,x-3,280),fill=p[3],width=2)
  for x,y in [(75,203),(240,232),(416,215),(560,189)]:
   for j in range(5):d.rectangle((x+j*9-22,y-abs(2-j)*3,x+j*9+24,y+10),fill=p[3])
 else:
  for x,h in [(28,150),(92,70),(570,127),(620,170)]:
   poly(d,[(x-20,288),(x-14,288-h*.6),(x,288-h),(x+8,288-h*.6),(x+23,288)],p[1]);d.line((x,288-h+10,x+5,277),fill=p[3],width=3)
  for x in range(0,640,3):
   y=270+int(math.sin(x*.04)*6);d.rectangle((x,y,x+2,290),fill=p[3]);d.rectangle((x,y,x+2,y+2),fill=p[4])
 # Gothic scenery: angular silhouettes, broken stone, and dim runes.
 # Everything here is baked into the texture, so the detail has no runtime cost.
 if z==0:
  # Twisted dead trees frame the clearing; pale cuts suggest old bark.
  for tx,mirror in [(19,1),(625,-1)]:
   poly(d,[(tx-10,293),(tx-3,239),(tx-12*mirror,206),(tx-7*mirror,175),(tx-3*mirror,207),(tx+7*mirror,239),(tx+9,293)],p[0])
   poly(d,[(tx+3,239),(tx+25*mirror,216),(tx+33*mirror,185),(tx+28*mirror,222),(tx+8,252)],p[0])
   poly(d,[(tx-4,220),(tx-20*mirror,199),(tx-26*mirror,167),(tx-17*mirror,195),(tx+1,209)],p[0])
   d.line((tx+3,255,tx+1,287),fill=p[2],width=2)
  for tx,yy in [(83,282),(114,287),(500,285),(542,280)]:
   d.rectangle((tx-7,yy-17,tx+7,yy),fill=p[1]);d.rectangle((tx-5,yy-20,tx+5,yy),fill=p[1]);d.line((tx-5,yy-19,tx+4,yy-19),fill=p[3]);d.line((tx,yy-15,tx,yy-5),fill=p[2],width=2);d.line((tx-3,yy-12,tx+3,yy-12),fill=p[2])
  # Suspended lanterns and a ruined spire, away from the playable plane.
  poly(d,[(336,240),(336,173),(345,153),(354,173),(354,240)],p[1]);d.rectangle((342,178,348,192),fill=p[3]);d.rectangle((344,180,346,188),fill=p[4])
  for tx,yy in [(63,207),(579,196)]:
   d.line((tx,yy-31,tx,yy),fill=p[0]);d.rectangle((tx-5,yy,tx+5,yy+12),fill=p[0]);d.rectangle((tx-3,yy+3,tx+3,yy+8),fill=p[4]);d.line((tx,yy+3,tx,yy+9),fill=p[1])
 elif z==1:
  # The frozen cemetery remains visible under the ice.
  for tx in [73,143,510,570]:
   yy=280;d.rectangle((tx-3,yy-31,tx+3,yy),fill=p[1]);d.rectangle((tx-10,yy-24,tx+10,yy-19),fill=p[1]);d.line((tx-8,yy-24,tx+9,yy-24),fill=p[3])
  for tx in [285,337,390]:
   poly(d,[(tx-9,247),(tx-9,208),(tx,197),(tx+9,208),(tx+9,247)],p[1]);d.line((tx,207,tx,234),fill=p[2])
 elif z==2:
  for tx in [39,590]:
   d.rectangle((tx-12,214,tx+12,243),fill=p[0]);d.rectangle((tx-9,217,tx+9,238),fill=p[3]);d.rectangle((tx-6,222,tx-2,225),fill=p[5]);d.rectangle((tx+2,222,tx+6,225),fill=p[5]);d.line((tx-4,231,tx+5,231),fill=p[1],width=2)
  for tx in [265,324,385]:
   poly(d,[(tx-14,255),(tx-14,199),(tx-5,182),(tx,167),(tx+5,182),(tx+14,199),(tx+14,255)],p[1]);d.rectangle((tx-2,202,tx+2,223),fill=p[3])
 elif z==3:
  for tx in [272,339,402]:
   poly(d,[(tx-11,252),(tx-11,208),(tx-18,208),(tx,183),(tx+18,208),(tx+11,208),(tx+11,252)],p[1]);d.rectangle((tx-2,212,tx+2,238),fill=p[2])
  for tx,yy in [(75,194),(558,185)]:
   d.line((tx,yy,tx,yy+46),fill=p[2],width=2)
   for sy in range(yy,yy+46,6):d.rectangle((tx-2,sy,tx+2,sy+4),outline=p[3])
 else:
  # Black cathedral silhouette and skull-shaped ruins.
  for tx in [275,332,390]:
   poly(d,[(tx-13,265),(tx-13,212),(tx-8,212),(tx-8,185),(tx,163),(tx+8,185),(tx+8,212),(tx+13,212),(tx+13,265)],p[1]);d.rectangle((tx-2,211,tx+2,240),fill=p[3])
  for tx in [62,556]:
   d.rectangle((tx-12,265,tx+12,283),fill=p[2]);d.rectangle((tx-9,261,tx+9,282),fill=p[2]);d.rectangle((tx-8,267,tx-3,272),fill=p[0]);d.rectangle((tx+3,267,tx+8,272),fill=p[0]);d.rectangle((tx-4,278,tx+4,283),fill=p[0])
 # Sparse mist bands and native-pixel texture add depth without hiding hazards.
 for j in range(9):
  yy=245+j*4;xx=(j*137+z*67)%580;d.rectangle((xx,yy,xx+48+(j%3)*26,yy+1),fill=p[2])
 for j in range(140):
  xx=rng.randrange(640);yy=rng.randrange(200,289)
  if rng.random()<.4:d.rectangle((xx,yy,xx+1,yy),fill=p[2])
 # foreground mossy stone shelf; playfield covers uppermost strip
 d.rectangle((0,294,639,359),fill=p[0]);d.rectangle((0,294,639,299),fill=p[4]);d.line((0,294,639,294),fill=p[5],width=2)
 for x in range(0,640,8):
  deep=rng.randrange(5,16);d.rectangle((x,299,x+7,299+deep),fill=p[2]);d.rectangle((x,299,x+2,299+deep-3),fill=p[3])
 for row,y in enumerate(range(319,360,16)):
  for x in range(-20,660,35):
   xx=x+(row%2)*16;d.rectangle((xx,y,xx+31,y+12),fill=p[1]);d.line((xx+2,y,xx+28,y),fill=p[2])
 for _ in range(65):
  x=rng.randrange(640);y=rng.randrange(311,359);d.rectangle((x,y,x+1,y+1),fill=p[3])
 im.save(ART/f'zone_{z}.png')
for z in range(5):background(z)
# 32 x 40 animated guardian sprites; rich palette but small actual textures.
for pose in ['idle','run1','run2','jump','duck','hurt']:
 im=Image.new('RGBA',(32,40));d=ImageDraw.Draw(im)
 ink='#15182b';metal='#264c64';light='#92cfcb';skin='#f7dba8';red='#f16d68';gold='#f9bb72'
 dy=10 if pose=='duck' else 0
 def r(box,c):d.rectangle((box[0],box[1]+dy,box[2],box[3]+dy),fill=c)
 # antenna and hood ears
 r((9,1,11,6),ink);r((8,0,10,3),light);r((23,3,25,8),ink);r((24,1,26,4),gold)
 r((6,6,26,8),ink);r((4,9,28,22),ink);r((6,7,26,20),metal);r((8,7,24,8),light);r((5,10,7,18),'#477e8c')
 r((8,11,25,20),skin);r((10,10,23,10),gold);r((10,13,12,17),ink);r((21,13,23,17),ink);r((10,13,10,14),'#ffffff');r((21,13,21,14),'#ffffff');r((15,18,18,18),'#c47e73')
 # red scarf blowing left
 poly(d,[(8,22+dy),(1,20+dy),(0,24+dy),(7,26+dy),(1,28+dy),(10,27+dy)],red)
 r((8,22,25,25),ink);r((8,22,25,23),red);r((12,24,22,25),'#a84153')
 if pose!='duck':
  r((9,26,24,33),ink);r((11,26,22,31),metal);r((12,26,15,30),light);r((10,32,23,33),gold)
  r((5,26,8,31),ink);r((6,26,8,28),light);r((25,26,28,31),ink);r((25,26,27,29),gold)
  off=2 if pose=='run1' else -2 if pose=='run2' else 0
  r((9+off,34,14+off,38),ink);r((18-off,34,23-off,38),ink);r((8+off,37,14+off,38),light);r((19-off,37,25-off,38),light)
 else:
  d.rectangle((9,35,26,39),fill=ink);d.rectangle((11,35,23,37),fill=metal);d.rectangle((9,39,15,39),fill=light)
 if pose=='hurt':
  # baked flash used after receiving a hit
  pix=im.load()
  for y in range(40):
   for x in range(32):
    if pix[x,y][3]:pix[x,y]=(255,229,210,255)
 im.save(ART/f'hero_{pose}.png')
icon=Image.new('RGBA',(64,64),'#101321')
icon_draw=ImageDraw.Draw(icon)
icon_draw.rectangle((2,2,61,61),outline='#6c495e',width=2)
icon.alpha_composite(Image.open(ART/'hero_idle.png'),(16,13))
icon.save(ART/'icon.png')
# Distinct 16-object sheets per biome, eight silhouettes and two material variants.
for z,p in enumerate(P):
 im=Image.new('RGBA',(16*24,24));d=ImageDraw.Draw(im);rng=random.Random(z)
 for n in range(16):
  x=n*24; a=p[4 if n<8 else 6];b=p[5];c=p[1]; k=n%8
  if k==0: # leaf, shard, glass, feather, ember
   poly(d,[(x+4,5),(x+13,2),(x+21,8),(x+17,17),(x+9,21),(x+3,13)],c);poly(d,[(x+5,6),(x+13,4),(x+19,9),(x+15,16),(x+9,18),(x+5,12)],a);d.line((x+8,16,x+15,7),fill=b,width=2)
  elif k==1: # thorned seed, frost ball, gear, storm orb, meteor
   d.ellipse((x+4,4,x+20,20),fill=c);d.ellipse((x+6,6,x+18,18),fill=a);d.rectangle((x+8,7,x+12,9),fill=b)
   for dx,dy in [(0,-9),(9,0),(0,9),(-9,0)]:d.rectangle((x+11+dx,11+dy,x+13+dx,13+dy),fill=a)
  elif k==2: # blade
   poly(d,[(x+3,18),(x+7,4),(x+20,2),(x+18,16),(x+10,22)],c);poly(d,[(x+6,16),(x+9,5),(x+18,4),(x+16,14),(x+10,19)],a);d.line((x+10,17,x+15,6),fill=b,width=2)
  elif k==3: # small explosive creature
   d.rectangle((x+4,8,x+20,18),fill=c);d.rectangle((x+6,6,x+18,17),fill=a);d.rectangle((x+8,9,x+10,12),fill=b);d.rectangle((x+14,9,x+16,12),fill=b);d.line((x+12,6,x+16,2),fill=b,width=2);d.rectangle((x+8,17,x+16,19),fill=c)
  elif k==4:
   poly(d,[(x+3,6),(x+10,6),(x+12,2),(x+14,7),(x+21,7),(x+18,16),(x+12,21),(x+5,16)],c);poly(d,[(x+5,8),(x+12,6),(x+19,8),(x+16,14),(x+12,18),(x+8,14)],a);d.rectangle((x+8,9,x+10,11),fill=b)
  elif k==5:
   poly(d,[(x+2,12),(x+5,5),(x+10,10),(x+14,10),(x+19,5),(x+22,12),(x+16,19),(x+8,19)],c);poly(d,[(x+4,12),(x+6,8),(x+10,12),(x+14,12),(x+18,8),(x+20,12),(x+15,17),(x+9,17)],a);d.rectangle((x+10,13,x+14,14),fill=b)
  elif k==6:
   d.rectangle((x+5,3,x+19,20),fill=c);d.rectangle((x+7,5,x+17,18),fill=a);d.rectangle((x+7,5,x+17,7),fill=b);d.rectangle((x+10,10,x+14,15),fill=c)
  else:
   poly(d,[(x+4,16),(x+8,4),(x+12,9),(x+17,2),(x+20,17),(x+12,22)],c);poly(d,[(x+7,15),(x+9,8),(x+12,13),(x+16,6),(x+17,17),(x+12,19)],a);d.line((x+12,16,x+15,11),fill=b,width=2)
  if n>=8:star(d,x+18,4,p[6],2)
 im.save(ART/f'hazards_{z}.png')
# Boss portraits: original silhouettes, 96px each.
for z,p in enumerate(P):
 im=Image.new('RGBA',(96,96));d=ImageDraw.Draw(im)
 # base shadow / cloak
 poly(d,[(20,82),(15,53),(26,28),(47,17),(71,27),(81,52),(76,82),(63,91),(31,91)],p[0])
 poly(d,[(23,78),(21,49),(31,31),(48,23),(66,32),(75,51),(72,78),(60,86),(34,86)],p[2])
 if z==0:
  for x,sgn in [(28,-1),(68,1)]:
   poly(d,[(x,38),(x+sgn*5,18),(x+sgn*18,9),(x+sgn*11,5),(x+sgn*2,13),(x-sgn*4,5),(x-sgn*7,7),(x-sgn*5,26)],p[4])
  for x,y in [(25,31),(37,21),(57,21),(68,31)]:d.rectangle((x-7,y-4,x+6,y+4),fill=p[3]);d.line((x-7,y-4,x+6,y-4),fill=p[5])
 elif z==1:
  for x,h in [(24,22),(40,32),(55,29),(70,20)]:crystal(d,x,39,h,p)
 elif z==2:
  d.rectangle((17,32,79,68),fill=p[3]);d.rectangle((22,37,74,63),fill=p[0]);d.rectangle((31,19,64,23),fill=p[6]);d.rectangle((47,23,49,34),fill=p[4])
 elif z==3:
  for s in [-1,1]:
   for k in range(3):poly(d,[(48+s*23,43+k*8),(48+s*46,22+k*13),(48+s*43,44+k*10),(48+s*20,64)],p[4-k%2])
  d.ellipse((26,9,70,21),outline=p[5],width=3)
 else:
  poly(d,[(24,38),(8,18),(14,4),(26,23),(35,28)],p[4]);poly(d,[(61,27),(70,23),(82,4),(88,18),(72,38)],p[4])
 # glowing face
 d.rectangle((27,43,41,53),fill=p[0]);d.rectangle((55,43,69,53),fill=p[0]);d.rectangle((29,45,40,49),fill=p[5]);d.rectangle((56,45,67,49),fill=p[5]);d.rectangle((34,45,37,49),fill=p[6]);d.rectangle((59,45,62,49),fill=p[6]);poly(d,[(35,65),(42,69),(54,69),(62,64),(58,76),(39,76)],p[0]);d.rectangle((42,68,46,71),fill=p[5]);d.rectangle((53,68,57,71),fill=p[5])
 d.rectangle((38,80,59,83),fill=p[3]);d.rectangle((43,80,54,81),fill=p[5])
 im.save(ART/f'boss_{z}.png')
# Pixel logo, deliberately drawn from a bitmap alphabet.
letters={'P':['11110','10001','10001','11110','10000','10000','10000'],'I':['111','010','010','010','010','010','111'],'X':['10001','10001','01010','00100','01010','10001','10001'],'E':['11111','10000','10000','11110','10000','10000','11111'],'L':['10000','10000','10000','10000','10000','10000','11111'],'A':['01110','10001','10001','11111','10001','10001','10001'],'N':['10001','11001','11001','10101','10011','10011','10001'],'C':['01111','10000','10000','10000','10000','10000','01111']}
im=Image.new('RGBA',(278,119));d=ImageDraw.Draw(im)
for text,y,scale in [('PIXEL',4,6),('PANIC',61,7)]:
 total=sum(len(letters[c][0])+1 for c in text)*scale-scale;x=(278-total)//2
 for c in text:
  for yy,row in enumerate(letters[c]):
   for xx,v in enumerate(row):
    if v=='1':d.rectangle((x+xx*scale+2,y+yy*scale+4,x+(xx+1)*scale+1,y+(yy+1)*scale+3),fill='#361b35')
  for yy,row in enumerate(letters[c]):
   for xx,v in enumerate(row):
    if v=='1':d.rectangle((x+xx*scale,y+yy*scale,x+(xx+1)*scale-1,y+(yy+1)*scale-1),fill=['#e1decc','#d2c6ae','#bba89c','#b28a8c','#ae6875','#994c68','#733b59'][yy])
  x+=(len(letters[c][0])+1)*scale
im.save(ART/'logo.png')
# Island map, miniature native-pixel landscapes.
im=Image.new('RGB',(640,360),'#090e1c');d=ImageDraw.Draw(im);rng=random.Random(121)
for _ in range(140):
 x=rng.randrange(640);y=rng.randrange(25,260);star(d,x,y,rng.choice(['#263952','#374b62','#769185']),0 if rng.random()<.9 else 1)
for z,cx in enumerate([76,198,320,442,564]):
 p=P[z];cy=[164,144,164,144,164][z]
 poly(d,[(cx-53,cy),(cx-41,cy+18),(cx-31,cy+35),(cx-10,cy+48),(cx+5,cy+62),(cx+24,cy+37),(cx+42,cy+20),(cx+54,cy)],p[1]);poly(d,[(cx-32,cy+12),(cx-13,cy+44),(cx+5,cy+62),(cx+7,cy+18)],p[2]);poly(d,[(cx+13,cy+16),(cx+5,cy+62),(cx+24,cy+37),(cx+42,cy+20)],p[0]);d.rectangle((cx-50,cy-5,cx+50,cy+2),fill=p[3]);d.line((cx-45,cy-7,cx+45,cy-7),fill=p[5],width=2)
 if z==0:tree(d,cx-22,cy-9,49,p,rng);tree(d,cx+31,cy-9,35,p,rng)
 elif z==1:crystal(d,cx-22,cy-8,44,p);crystal(d,cx+25,cy-8,31,p)
 elif z==2:city(d,cx-22,cy-7,42,p,rng);city(d,cx+26,cy-7,30,p,rng)
 elif z==3:
  for xx in [cx-28,cx+28]:d.rectangle((xx,cy-42,xx+8,cy-8),fill=p[3]);d.rectangle((xx-3,cy-45,xx+11,cy-40),fill=p[5])
 else:poly(d,[(cx-40,cy-8),(cx-12,cy-51),(cx+1,cy-47),(cx+38,cy-8)],p[2]);poly(d,[(cx-12,cy-51),(cx+1,cy-47),(cx+7,cy-29),(cx-6,cy-39),(cx-13,cy-25)],p[4])
 for _ in range(10):
  x=cx+rng.randrange(-40,40);y=cy+rng.randrange(8,23);d.rectangle((x,y,x+2,y+2),fill=p[3])
im.save(ART/'map.png')
# Original synthesized chiptune. Short PCM clips, no heavy audio processing at runtime.
RATE=22050
def save_audio(name,values):
 with wave.open(str(AUDIO/(name+'.wav')),'wb') as w:
  w.setnchannels(1);w.setsampwidth(2);w.setframerate(RATE);w.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,v))*28000)) for v in values))
def tone(freq,t,kind='square'):
 if kind=='tri':return 1-4*abs((freq*t)%1-.5)
 return 1 if math.sin(2*math.pi*freq*t)>0 else -1
for name,freq,dur in [('jump',540,.12),('shoot',820,.07),('hit',130,.2),('pickup',960,.22),('dash',330,.13),('click',710,.05),('warning',230,.16),('win',660,.65),('lose',180,.65)]:
 values=[]
 for i in range(int(RATE*dur)):
  t=i/RATE;env=(1-t/dur)**2;f=freq*(1+t/dur*.7 if name in ['jump','pickup','win'] else 1-t/dur*.65);values.append(tone(f,t)*env*.19)
 save_audio(name,values)
# Nonverbal, descending mocking chuckle; can be disabled with the taunt setting.
values=[]
for i in range(int(RATE*.8)):
 t=i/RATE;beat=int(t/.16);phase=t%.16;env=max(0,1-phase/.1);values.append(tone(280-beat*24,t,'tri')*env*.27)
save_audio('laugh',values)
for z in range(5):
 bpm=[112,98,128,108,138][z];step=60/bpm/2;duration=step*32;root=[196,220,174.61,261.63,164.81][z];notes=[0,7,12,7,3,10,12,10,5,12,15,12,3,10,7,3]*2
 samples=[];rng=random.Random(2026+z)
 for i in range(int(RATE*duration)):
  t=i/RATE;n=int(t/step);ph=(t%step)/step;f=root*2**(notes[n%32]/12);mel=tone(f,t,'tri')*.105*(1-ph*.8);bass=tone(root*.5*2**([0,3,5,3][n//8%4]/12),t)*.035*(1-ph)
  kick=math.sin((80*math.exp(-ph*13)+35)*t*2*math.pi)*math.exp(-ph*16)*.12 if n%2==0 else 0
  hat=(rng.random()*2-1)*math.exp(-ph*35)*.035
  samples.append(mel+bass+kick+hat)
 save_audio(f'music_{z}',samples)
print('Created original pixel artwork and audio.')
