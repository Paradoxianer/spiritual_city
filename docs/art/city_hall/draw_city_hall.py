# Old German town hall, 7x7 cells of 16 px, 3/4 top-down like the Kenney tiles.
import sys
from PIL import Image, ImageDraw
W=H=112
img=Image.new('RGBA',(W,H),(0,0,0,0)); d=ImageDraw.Draw(img)
OUT=(40,28,30)            # outline
ROOF=(150,52,40); ROOF_D=(112,36,30); ROOF_L=(178,72,52)
WALL=(238,222,184); WALL_D=(210,190,150); WALL_S=(190,168,128)
STONE=(150,140,128); STONE_D=(112,104,96); STONE_L=(176,166,152)
WIN=(54,74,110); WIN_L=(120,160,200); FRAME=(250,246,236)
COPPER=(86,160,132); COPPER_D=(54,112,92); COPPER_L=(130,198,168)
GOLD=(240,196,64); GOLD_D=(180,130,30)
WOOD=(110,64,36); WOOD_D=(78,44,24)
def R(x0,y0,x1,y1,c): d.rectangle([x0,y0,x1,y1],fill=c)
def P(x,y,c): d.point((x,y),fill=c)

# ---- roof (seen from above, top half) ----
R(0,0,111,49,ROOF)
for y in range(1,49,4):                       # tile rows
    d.line([(0,y),(111,y)],fill=ROOF_D)
    off=0 if (y//4)%2 else 3
    for x in range(off,112,6): P(x,y+1,ROOF_D); P(x,y+2,ROOF_D)
R(0,22,111,24,ROOF_D); d.line([(0,22),(111,22)],fill=OUT)   # ridge
d.line([(0,21),(111,21)],fill=ROOF_L)
# dormers on the southern slope
for cx in (36,75):
    R(cx-5,30,cx+5,44,WALL_D); d.polygon([(cx-7,32),(cx,25),(cx+7,32)],fill=ROOF_L,outline=OUT)
    R(cx-3,35,cx+3,42,WIN); R(cx-3,35,cx+3,36,WIN_L); d.rectangle([cx-5,32,cx+5,44],outline=OUT)
# two front-facing stepped gables (Treppengiebel) at the wings
for gx in (15,96):
    levels=[(50,15),(45,13),(40,10),(35,7),(30,4),(26,2)]
    for top,half in levels:
        R(gx-half,top,gx+half,50,WALL)
        d.line([(gx-half,top),(gx+half,top)],fill=STONE_D)
        P(gx-half,top,OUT); P(gx+half,top,OUT)
    for top,half in levels:
        d.line([(gx-half,top),(gx-half,top+5)],fill=OUT); d.line([(gx+half,top),(gx+half,top+5)],fill=OUT)
    R(gx-1,22,gx+1,25,STONE_D)
    d.ellipse([gx-4,36,gx+4,44],fill=FRAME); d.ellipse([gx-3,37,gx+3,43],fill=WIN); P(gx-1,39,WIN_L)
d.line([(0,49),(111,49)],fill=OUT)

# ---- facade ----
R(0,50,111,111,WALL)
R(0,50,111,52,STONE_L); d.line([(0,53),(111,53)],fill=STONE_D)       # cornice
R(0,76,111,77,STONE_L); d.line([(0,78),(111,78)],fill=STONE_D)       # string course
for x in (0,111): d.line([(x,50),(x,111)],fill=OUT)
# corner quoins
for y in range(54,96,6):
    R(1,y,4,y+2,STONE_L); R(107,y,110,y+2,STONE_L)
def window(x,y,w=7,h=11):
    R(x-1,y-1,x+w,y+h,FRAME)
    R(x,y+2,x+w-1,y+h-1,WIN); R(x+1,y,x+w-2,y+1,WIN)               # arched top
    P(x,y+1,FRAME); P(x+w-1,y+1,FRAME)
    d.line([(x+w//2,y),(x+w//2,y+h-1)],fill=FRAME); d.line([(x,y+5),(x+w-1,y+5)],fill=FRAME)
    P(x+1,y+3,WIN_L); P(x+2,y+3,WIN_L)
    R(x-2,y+h,x+w+1,y+h+1,STONE)                                       # sill
for x in (8,22,36,69,83,97): window(x-3,59)
# ground floor arcade: three arches, the door in the middle (column 3 = x 48..63)
R(0,80,111,111,STONE_L)
for y in range(82,104,4):
    for x in range((y//4)%2*4,112,8): d.line([(x,y),(x,y+3)],fill=STONE)
    d.line([(0,y),(111,y)],fill=STONE)
def arch(cx,w,top,bottom,fill):
    d.rectangle([cx-w,top+w,cx+w,bottom],fill=fill)
    d.pieslice([cx-w,top,cx+w,top+2*w],180,360,fill=fill)
    d.arc([cx-w-1,top-1,cx+w+1,top+2*w+1],180,360,fill=OUT)
    d.line([(cx-w-1,top+w),(cx-w-1,bottom)],fill=OUT); d.line([(cx+w+1,top+w),(cx+w+1,bottom)],fill=OUT)
for cx in (16,95): arch(cx,7,83,103,(70,58,56))
for cx in (16,95):
    for y in range(92,103,3): d.line([(cx-6,y),(cx+6,y)],fill=(92,78,74))
arch(55,8,81,103,WOOD)                                                 # main door
d.line([(55,90),(55,103)],fill=WOOD_D)
for y in (92,98): d.line([(48,y),(62,y)],fill=WOOD_D)
P(53,96,GOLD); P(57,96,GOLD)
R(28,86,40,96,FRAME); R(29,87,39,95,WIN); R(71,86,83,96,FRAME); R(72,87,82,95,WIN)
# steps
for i,y in enumerate((104,107,110)):
    R(40-i*3,y,70+i*3,y+2,STONE_L if i%2==0 else STONE); d.line([(40-i*3,y+2),(70+i*3,y+2)],fill=STONE_D)
d.line([(0,103),(39,103)],fill=STONE_D); d.line([(71,103),(111,103)],fill=STONE_D)
R(0,104,37,111,STONE_D); R(74,104,111,111,STONE_D)
# coat of arms above the door
R(51,70,59,75,(200,40,40)); d.rectangle([51,70,59,75],outline=GOLD_D); P(55,72,GOLD); P(55,73,GOLD)

# ---- tower in the middle, over the roof ----
TX0,TX1=46,64
R(TX0,22,TX1,69,WALL); d.rectangle([TX0,22,TX1,69],outline=OUT)
R(TX0+1,22,TX0+2,68,WALL_D); R(TX1-2,22,TX1-1,68,WALL_S)
R(TX0-2,20,TX1+2,23,STONE_L); d.rectangle([TX0-2,20,TX1+2,23],outline=OUT)
cx,cy=55,34
d.ellipse([cx-7,cy-7,cx+7,cy+7],fill=GOLD_D,outline=OUT); d.ellipse([cx-5,cy-5,cx+5,cy+5],fill=FRAME)
for a,b in ((0,-4),(0,4),(-4,0),(4,0)): P(cx+a,cy+b,OUT)
d.line([(cx,cy),(cx,cy-3)],fill=OUT); d.line([(cx,cy),(cx+2,cy+1)],fill=OUT)
window(49,46,5,9); window(57,46,5,9)
d.polygon([(TX0-1,20),(55,1),(TX1+1,20)],fill=COPPER,outline=OUT)
d.polygon([(55,1),(TX1+1,20),(58,20)],fill=COPPER_D)
d.line([(49,18),(55,4)],fill=COPPER_L)
R(52,10,58,15,COPPER); d.rectangle([52,10,58,15],outline=OUT); R(54,12,56,14,WIN)
d.ellipse([53,0,57,3],fill=GOLD,outline=GOLD_D)
# flags left and right on the roof
for fx,col in ((34,(220,40,40)),(72,(240,200,40))):
    d.line([(fx,6),(fx,26)],fill=OUT)
    d.polygon([(fx+1,6),(fx+10,9),(fx+1,13)],fill=col,outline=OUT)
img=img.crop((0,0,W,H))
img.save(sys.argv[1])
img.resize((W*6,H*6),Image.NEAREST).save(sys.argv[2])
