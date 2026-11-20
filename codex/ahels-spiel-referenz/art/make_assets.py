"""Erzeugt die gezeichneten Pixel-Sprites, Arenen und Sounds mit Python + Pillow."""
from pathlib import Path
import json
import math
from random import Random
import struct
import wave

from PIL import Image, ImageDraw
from portraits import portrait

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'assets'
ART = ASSETS / 'pixel'
AUDIO = ASSETS / 'audio'
for directory in (ART, AUDIO, ROOT / 'data'):
    directory.mkdir(parents=True, exist_ok=True)

# Auf Basis der gelieferten Portraits gezeichnet. Die Funktionsnamen und Stärken
# sind Vorschläge für den Spieltest und können unabhängig vom Sprite getauscht werden.
# Name, Stärke, Typ, Akzent, Haare, Schnitt, Kleidung, Haut, Brille/Details.
PROFILES = [
    ('Tempo', 'Startschuss', 'dash', '#ff8b7a', '#422a22', 'sweep', '#ede8e2', '#e5ab86', 'collar'),
    ('Takt', 'Metronom', 'guard', '#89e2e1', '#52392a', 'crop', '#2d394b', '#e6ae8e', 'polo'),
    ('Feder', 'Sprungfeder', 'rise', '#f8c972', '#5a3829', 'fade', '#383646', '#e4ae95', 'hood'),
    ('Drift', 'Kurve', 'dash', '#b9a6fa', '#3e2b25', 'fringe', '#343044', '#e7b89a', ''),
    ('Echo', 'Schallkreis', 'burst', '#fa9eb9', '#6e402b', 'wave', '#615063', '#f3b49d', 'jacket'),
    ('Glut', 'Doppelfunke', 'echo', '#ffa76c', '#873a25', 'curl', '#303e3b', '#f5bd9f', 'goatee'),
    ('Wind', 'Aufwind', 'rise', '#9fe5bf', '#694834', 'messy', '#7e929d', '#e6b08d', ''),
    ('Kompass', 'Reichweite', 'long', '#ffcf87', '#4c3229', 'part', '#835047', '#edb590', 'polo'),
    ('Wirbel', 'Kreisel', 'burst', '#9bc0ff', '#69412a', 'curl', '#68564f', '#edb29a', 'jacket'),
    ('Fokus', 'Impulslinie', 'bolt', '#9ee4eb', '#77513a', 'curl', '#526680', '#edbd99', 'round'),
    ('Plan', 'Schutzfeld', 'guard', '#b6befe', '#493326', 'messy', '#303b69', '#eab095', 'square'),
    ('Knoten', 'Sprungband', 'rise', '#e6dc85', '#4d3527', 'quiff', '#e4dad3', '#e4a784', 'hood'),
    ('Spur', 'Durchzug', 'dash', '#a2d5a0', '#352720', 'fringe', '#393542', '#dba581', 'stubble'),
    ('Tinte', 'Komet', 'bolt', '#ccb1fa', '#30231f', 'wave_up', '#343141', '#e3ad86', ''),
    ('Blitz', 'Funkenflug', 'echo', '#faca78', '#805b37', 'side', '#353448', '#f0c1a2', ''),
    ('Linse', 'Distanzblick', 'long', '#8cc4ff', '#644434', 'side', '#302d44', '#efbc9d', 'round'),
    ('Anker', 'Fester Stand', 'anchor', '#ff9a94', '#51362c', 'curl', '#ededef', '#ecc19b', 'goatee'),
    ('Welle', 'Wellenkamm', 'burst', '#fbb2c1', '#a98152', 'longhair', '#3d3346', '#f6c3a5', 'gold'),
    ('Puls', 'Pulsring', 'burst', '#83e9d3', '#383539', 'fade', '#46695f', '#c88962', 'hood'),
    ('Raster', 'Gitterblitz', 'bolt', '#fbd070', '#522c25', 'part', '#714378', '#bd805c', 'square'),
    ('Kante', 'Kantentritt', 'long', '#ffc1a0', '#bb794e', 'crop', '#405a9a', '#efbfa6', ''),
    ('Funk', 'Funkfolge', 'echo', '#bbabf7', '#2e2331', 'longhair', '#aa5b6e', '#c89479', 'gold'),
    ('Lot', 'Ausgleich', 'anchor', '#a2dba6', '#4c302e', 'sweep', '#4a7697', '#d69f7e', 'polo'),
    ('Klick', 'Klickschirm', 'guard', '#ecb5e3', '#534038', 'side', '#966254', '#ebc4ac', 'jacket'),
    ('Herr Haidenthaler', 'Tutorial', 'guard', '#9ce6c4', '#513b30', 'sweep', '#f4f1e8', '#e5b79c', 'teacher'),
    ('Herr Grimmer', 'Regalwelle', 'burst', '#f4a48a', '#483027', 'sweep', '#688eac', '#e9b99d', 'round'),
]

TALENTS = {
    'dash': 'Schießt mit einem schnellen Vorstoß nach vorn.',
    'rise': 'Bekommt in der Luft einen zusätzlichen Schub nach oben.',
    'burst': 'Stößt Figuren ringsum mit einer Impulswelle weg.',
    'guard': 'Blockt kurz einen Treffer und kontert im Nahbereich.',
    'bolt': 'Schickt einen Glühpunkt quer durch die Arena.',
    'long': 'Erreicht Figuren weiter vorn mit einer breiten Schwunglinie.',
    'echo': 'Schickt zwei Glühpunkte in unterschiedlichen Höhen.',
    'anchor': 'Bremst den eigenen Schwung und löst einen Bodenimpuls aus.',
}

def rgb(value):
    if isinstance(value, tuple):
        return value
    return tuple(int(value[pos:pos + 2], 16) for pos in (1, 3, 5))

def mix(a, b, amount):
    return tuple(round(x + (y - x) * amount) for x, y in zip(rgb(a), rgb(b)))

def shade(color, amount):
    return mix(color, '#171428' if amount < 0 else '#fff1d5', abs(amount))

def sprite(profile, frame, index):
    name, _, _, accent, hair, cut, shirt, skin, detail = profile
    img = Image.new('RGBA', (38, 48))
    d = ImageDraw.Draw(img)
    outline = '#201b2a'
    trousers = '#315b9c' if detail == 'teacher' else mix(shirt, '#283659', .7)
    motion = [(0, 0, 0), (1, 0, 0), (0, -4, 3), (1, 2, -2), (0, 4, -3),
              (-3, -3, 3), (1, -2, 2), (-1, -3, 3), (0, 2, -2)]
    bob, foot_l, foot_r = motion[frame]
    def r(x1, y1, x2, y2, c):
        d.rectangle((x1, y1 + bob, x2, y2 + bob), fill=c)
    def poly(points, c):
        d.polygon([(x, y + bob) for x, y in points], fill=c)

    # Schuhsilhouetten und bewegliche Beine.
    for x, stride, color in [(13, foot_l, shade(trousers, -.28)), (22, foot_r, trousers)]:
        bend = -2 if frame == 5 and stride < 0 else 0
        r(x-2, 32, x+5, 40+bend, outline)
        poly([(x-1, 34), (x+4, 34), (x+4+stride, 42+bend), (x-1+stride, 42+bend)], outline)
        poly([(x, 35), (x+3, 35), (x+3+stride, 40+bend), (x+stride, 40+bend)], color)
        r(x-1+stride, 41+bend, x+6+stride, 44+bend, outline)
        r(x+stride, 41+bend, x+5+stride, 42+bend, shade(color, .35))
        r(x+stride, 43+bend, x+5+stride, 43+bend, '#d9d6d7')

    if cut in ('longhair', 'wave', 'part'):
        poly([(10, 13), (26, 12), (28, 28), (25, 33), (19, 29), (11, 31), (9, 25)],
             shade(hair, -.20))
    poly([(11, 24), (15, 21), (23, 21), (27, 24), (29, 32), (26, 37), (11, 37), (9, 31)], outline)
    poly([(12, 25), (16, 23), (23, 23), (27, 26), (26, 35), (12, 35)], shirt)
    r(12, 29, 14, 35, shade(shirt, -.24))
    r(15, 32, 23, 34, shade(shirt, -.12))
    r(16, 25, 22, 27, shade(shirt, .26))
    if detail in ('teacher', 'polo', 'collar'):
        col = '#bc8b5b' if detail == 'collar' else shade(shirt, .36)
        poly([(13, 24), (17, 24), (18, 28), (15, 27)], col)
        poly([(22, 23), (26, 25), (23, 28), (20, 27)], shade(col, -.12))
        r(19, 28, 19, 33, shade(shirt, -.32))
    elif detail == 'hood':
        poly([(12, 23), (14, 27), (18, 29), (24, 26), (25, 23)], shade(shirt, -.42))
        r(16, 27, 16, 30, shade(shirt, .40))
        r(22, 26, 22, 29, shade(shirt, .40))
    elif detail == 'jacket':
        poly([(18, 25), (22, 25), (23, 35), (17, 35)], '#e3ccb9')
        r(16, 29, 16, 34, shade(shirt, .3))
    elif detail == 'gold':
        poly([(16, 25), (20, 28), (22, 26), (21, 29), (19, 29)], '#dfb86d')
    else:
        r(19, 29, 22, 30, accent)

    # Hände und Ärmel. Das Ausholen ragt bewusst aus der Grundsilhouette heraus.
    pos = {
        2: ((7, 27), (28, 26)), 3: ((8, 29), (26, 29)), 4: ((10, 30), (28, 26)),
        5: ((6, 24), (29, 22)), 6: ((8, 29), (34, 24)),
        7: ((6, 25), (32, 20)), 8: ((7, 27), (28, 30)),
    }.get(frame, ((8, 29), (27, 28)))
    for idx, (x, y) in enumerate(pos):
        sx = 12 if idx == 0 else 25
        poly([(sx-2, 25), (sx+2, 25), (x+2, y-1), (x+1, y+3), (x-2, y+2)], outline)
        poly([(sx-1, 25), (sx+1, 26), (x+1, y), (x-1, y+1)], shade(shirt, -.13 + .27*idx))
        r(x-1, y, x+1, y+2, skin)
        r(x, y+2, x+1, y+2, shade(skin, -.2))

    r(17, 20, 22, 25, outline)
    r(17, 21, 22, 24, shade(skin, -.12))
    if detail == 'teacher':
        poly([(15, 24), (17, 23), (24, 30), (23, 32)], '#64402a')
        r(21, 29, 28, 36, '#412c2a')
        r(22, 30, 28, 35, '#936340')
        r(22, 30, 28, 32, '#b98050')
        r(24, 32, 26, 34, '#d1a761')
        r(25, 33, 25, 34, '#54352b')
    img = img.resize((76, 96), Image.Resampling.NEAREST)
    head = portrait(profile, index, bust=False).resize((49, 48), Image.Resampling.NEAREST)
    img.alpha_composite(head, (12, round(2 + bob * 2)))
    return img

stats = {
    'dash': (1.10, .98, .92), 'rise': (1.01, 1.10, .89),
    'guard': (.95, 1., 1.12), 'burst': (1., 1.02, 1.),
    'bolt': (.97, 1.04, .96), 'long': (.99, 1., 1.04),
    'echo': (1.025, .97, .98), 'anchor': (.92, .96, 1.20),
}
# Abweichungen für Tempo, Sprung und Gewicht. Dazu Kraft und Abklingzeit
# der Spezialaktion, damit auch Figuren mit ähnlichen Aktionen verschieden spielen.
tuning = [
    (.08, .00, -.02, .90, 1.76), (.03, -.02, .00, .94, 1.85),
    (-.02, .04, -.03, 1.02, 2.60), (.02, .02, -.06, 1.02, 2.11),
    (-.03, .00, .02, 1.08, 2.28), (-.03, -.03, .07, 1.16, 2.75),
    (.00, .06, .00, .90, 1.97), (.00, -.02, .02, 1.08, 2.55),
    (.02, .03, -.04, .88, 1.70), (-.03, .00, .03, 1.17, 2.72),
    (-.03, -.03, .09, 1.14, 2.61), (.04, .01, .08, 1.18, 2.87),
    (.03, -.06, .09, 1.21, 2.66), (.04, -.02, .02, 1.00, 2.04),
    (.05, .04, -.05, .88, 1.90), (.06, .01, -.01, .86, 1.91),
    (-.03, -.02, .11, 1.19, 2.83), (.01, .06, -.05, .96, 2.13),
    (.00, -.02, .06, 1.15, 2.51), (-.01, .05, -.03, .88, 1.74),
    (-.02, .06, .07, 1.20, 2.90), (.00, .02, .01, 1.04, 2.14),
    (.03, .02, -.02, .97, 1.91), (.08, .01, -.08, .84, 1.64),
    (.00, .00, .00, 1.00, 2.35), (.00, .00, .00, 1.00, 2.35),
]
roster = []
for index, profile in enumerate(PROFILES):
    name, ability, kind, accent, *_ = profile
    ident = f'figur-{index + 1:02d}' if index < 24 else ('haidenthaler' if index == 24 else 'grimmer')
    sheet = Image.new('RGBA', (76*9, 96))
    for frame in range(9):
        sheet.paste(sprite(profile, frame, index), (frame*76, 0))
    sheet.save(ART / f'{ident}.png', optimize=True)
    portrait(profile, index).save(ART / f'{ident}-portrait.png', optimize=True)
    speed, jump, weight = stats[kind]
    speed_bonus, jump_bonus, weight_bonus, power, cooldown = tuning[index]
    roster.append(dict(id=ident, name=name, ability=ability, kind=kind, color=accent,
                       description=TALENTS[kind], speed=round(speed+speed_bonus, 3),
                       jump=round(jump+jump_bonus, 3), weight=round(weight+weight_bonus, 3),
                       power=power, cooldown=cooldown))
roster_path = ROOT / 'data' / 'fighters.json'
if not roster_path.exists():
    roster_path.write_text(json.dumps(roster, ensure_ascii=False, indent=2)+'\n')

ARENAS = [
    ('turnsaal', 'Turnsaal', '#436888', [(-1, 560, 1282, 44), (377, 432, 210, 22)], [315, 925]),
    ('pausenhof', 'Pausenhof', '#5fe4bd', [(180, 535, 920, 58), (240, 418, 246, 26), (794, 418, 246, 26), (524, 326, 232, 26)], [360, 920]),
    ('computerraum', 'Computerraum', '#9bb4ff', [(145, 560, 990, 60), (335, 425, 242, 25), (710, 375, 242, 25)], [330, 935]),
    ('bibliothek', 'Bibliothek', '#ffbb78', [(160, 550, 960, 60), (205, 402, 252, 26), (822, 402, 252, 26)], [340, 923]),
]
stage_path = ROOT / 'data' / 'arenas.json'
if not stage_path.exists():
    stage_path.write_text(json.dumps([
        dict(id=ident, name=name, color=color, platforms=platforms, spawns=spawns)
        for ident, name, color, platforms, spawns in ARENAS
    ], ensure_ascii=False, indent=2)+'\n')

def backdrop(index):
    rng = Random(51+index)
    img = Image.new('RGB', (640, 360))
    d = ImageDraw.Draw(img)
    top, bottom = [('#1b2b48','#345571'),('#242044','#a36670'),
                   ('#151e3c','#333d6a'),('#282035','#845650')][index]
    for y in range(360):
        d.line((0,y,640,y), fill=mix(top,bottom, y/359))
    def r(x, y, w, h, c):
        d.rectangle((x, y, x+w-1, y+h-1), fill=c)
    def pattern(x,y,w,h,c,n):
        for _ in range(n):
            r(x+rng.randrange(w),y+rng.randrange(h),rng.choice([1,1,2,3]),1,c)

    if index == 1:
        # Über den Dächern: Mond, Gebäude, lichter Fenster und ein Pausenhof über der Stadt.
        d.ellipse((451, 40, 545, 134), fill='#ffd1a3')
        for y,w in [(113,63),(117,73),(126,65),(132,38)]:
            r(450+(93-w)//2,y,w,2,'#d08787')
        for _ in range(40):
            x,y=rng.randrange(640),rng.randrange(38,190)
            if (x-498)**2+(y-87)**2 > 50**2:
                r(x,y,1+rng.randrange(2),1,rng.choice(['#9d7895','#bf92a0','#f4bbaf']))
        for layer, (baseline, color, gap) in enumerate([(243,'#554064',5),(277,'#3f3657',6),(309,'#282844',6)]):
            x = -5
            while x < 640:
                w,h=rng.randrange(17,54),rng.randrange(16,84)
                y=baseline-h
                r(x,y,w,h,color)
                r(x+3,y-3,w-6,4,shade(color,.08))
                if rng.random()<.33:
                    r(x+w//2,y-12,2,10,color)
                for fy in range(y+7,baseline-6,9):
                    for fx in range(x+5,x+w-4,7):
                        if rng.random()<.33:
                            r(fx,fy,2,3,rng.choice(['#ac748d','#cd8f86','#92758d']))
                x+=w+gap
        for x in (58, 560):
            r(x,164,4,118,'#30283f')
            r(x-7,161,19,3,'#c5bab9')
            r(x-5,164,15,3,'#f6c191')
        for y in (245,266):
            r(0,y,640,2,'#5b506a')
        for x in range(0,640,24):
            r(x,245,2,36,'#5b506a')
        r(0,319,640,45,'#201e36')
        pattern(0,320,638,38,'#463858',330)
    elif index == 0:
        # Sporthalle mit Holzverkleidung, Oberlichtern und Sprossenwänden.
        r(0,45,640,7,'#17283f')
        r(0,157,640,5,'#192f46')
        for x in (41, 225, 409):
            r(x,60,158,86,'#24384f')
            r(x+4,64,150,76,'#6d9eac')
            for pos in (0,1,2):
                r(x+7+pos*49,67,44,68,'#84abb7')
                for j in range(12):
                    r(x+8+pos*49+j*2,69+j*2,23,1,'#a2c3c5')
            r(x+4,114,150,3,'#394e67')
            r(x,145,161,3,'#b4afa3')
        r(0,193,640,89,'#684e4c')
        for x in range(0,640,10):
            r(x,194,1,87,'#483946')
            r(x+1,195,1,84,'#795a51')
        r(0,193,640,3,'#ac7c60')
        for x in (58, 535):
            r(x,153,48,113,'#3d3441')
            r(x+3,152,3,114,'#ae8f70')
            r(x+43,152,3,114,'#7a624f')
            for y in range(157,261,11):
                r(x+3,y,41,3,'#9b795e')
        r(309,161,33,24,'#e6c7a7')
        r(312,163,27,17,'#52627d')
        r(318,175,14,3,'#ef9b88')
        for y in range(282,360):
            r(0,y,640,1,mix('#ad7d5f','#463346',(y-282)/78))
        for i in range(9):
            x=i*81-20
            d.line((320+(x-320)*.5,281,x,359),fill='#88624f')
        for y in (293,311,339,358):
            r(0,y,640,1,'#4e4650')
        d.ellipse((235,277,405,315),outline='#cf9a71',width=2)
        r(319,283,2,64,'#c59374')
    elif index == 2:
        for y in (49,51,151,154,224):
            r(0,y,640,2,'#424874')
        for x in range(29,640,117):
            r(x,67,96,75,'#241d3f')
            r(x+3,70,90,66,'#484b80')
            r(x+5,72,86,62,'#323a68')
            for col in range(7):
                r(x+8+col*12,72,1,62,'#485279')
            r(x+5,94,86,2,'#525b8e')
        for x in range(9,640,101):
            r(x,173,99,9,'#7a6490')
            r(x+6,181,5,58,'#342d56')
            r(x+91,181,4,58,'#342d56')
            r(x+16,141,41,27,'#251f44')
            r(x+19,144,35,20,'#516d99')
            r(x+22,147,29,14,'#728eba')
            for row in range(3):
                r(x+24,149+4*row,14+rng.randrange(11),1,'#a9aedb')
            r(x+32,167,10,6,'#4d4c79')
            r(x+63,158,14,12,'#45446a')
            r(x+65,161,2,2,'#85d3ca')
        r(0,273,640,87,'#211f41')
        for y in range(279,360,9):
            r(0,y,640,1,'#342d56')
        for x in range(-105,765,70):
            d.line((320+(x-320)*.54,272,x,359),fill='#372e57')
    else:
        # Bibliothek mit warmen Regalen und einem hohen Fenster in der Mitte.
        r(0,26,640,10,'#432d3f')
        r(0,182,640,100,'#4c3240')
        for x in (22, 158, 384, 520):
            r(x,51,108,220,'#392a3a')
            for shelf in range(4):
                top_y=55+shelf*51
                r(x+5,top_y,98,41,'#563844')
                pos=x+8
                while pos<x+96:
                    w,h=rng.randrange(4,9),rng.randrange(13,33)
                    col=rng.choice(['#9c5761','#b78363','#756080','#5d7487','#8d7372','#9e926f'])
                    r(pos,top_y+41-h,w,h,col)
                    r(pos+1,top_y+43-h,w-2,1,shade(col,.25))
                    r(pos+1,top_y+36,w-2,1,shade(col,-.32))
                    pos+=w+1+rng.randrange(3)
                r(x+2,top_y+42,104,4,'#805548')
                r(x+2,top_y+45,104,3,'#4b3441')
            r(x+2,51,4,218,'#866052')
            r(x+102,51,4,218,'#704b45')
        r(284,63,72,126,'#33293d')
        r(288,66,64,119,'#8a7190')
        for x in range(292,353,9):
            r(x,69,2,112,'#a88b9a')
        r(317,66,5,120,'#4e415a')
        r(288,120,64,4,'#514059')
        for x in (133, 498):
            r(x,92,9,2,'#c98965')
            r(x+2,86,5,6,'#f0b687')
        r(0,268,640,92,'#4a3341')
        for x in range(-60,760,40):
            d.line((320+(x-320)*.54,267,x,359),fill='#684552')
        for y in (276,290,309,334,354):
            r(0,y,640,1,'#795152')
        d.polygon([(273,273),(367,273),(425,359),(215,359)], fill='#744c5b')
        d.line(((277,275),(229,358)),fill='#b77e69',width=2)
        d.line(((363,275),(411,358)),fill='#b77e69',width=2)

    pattern(0,0,638,358,mix(top,bottom,.52),1400)
    return img

for i, (ident, *_) in enumerate(ARENAS):
    backdrop(i).save(ART / f'{ident}.png', optimize=True)

icon = Image.new('RGBA',(48,48))
di = ImageDraw.Draw(icon)
di.rounded_rectangle((1,1,46,46),radius=10,fill='#17243a')
di.polygon([(8,36),(18,13),(29,13),(40,36),(32,36),(29,29),(18,29),(15,36)],fill='#8fe8c6')
di.polygon([(21,24),(25,16),(28,24)],fill='#17243a')
icon.save(ASSETS / 'icon.png')

RATE = 22050

def save_audio(name, samples):
    with wave.open(str(AUDIO / f'{name}.wav'), 'wb') as file:
        file.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        file.writeframes(b''.join(struct.pack('<h', int(max(-1,min(1,s))*32767)) for s in samples))

def chirp(name,duration,f1,f2,style):
    rng=Random(120)
    samples=[]
    for i in range(int(duration*RATE)):
        t=i/RATE
        frac=t/duration
        phase=2*math.pi*(f1*t+(f2-f1)*t*t/(duration*2))
        pulse=(math.sin(phase)+.32*math.sin(phase*2))
        if style=='noise':
            pulse=.6*pulse+.4*rng.uniform(-1,1)
        samples.append(.47*pulse*min(1,t/.008)*(1-frac)**1.9)
    save_audio(name,samples)

for cue in [
    ('select',.10,490,730,'tone'),('jump',.15,200,510,'tone'),
    ('swing',.11,270,130,'noise'),('hit',.18,155,78,'noise'),
    ('special',.29,460,159,'tone'),('out',.38,325,60,'noise'),
    ('success',.42,350,790,'tone'),('boss',.49,110,140,'noise'),
]:
    chirp(*cue)

def music(name, bpm, roots, tune):
    step = 60/bpm/2
    length = int(RATE * step * 32)
    samples = [0.0]*length
    rng = Random(12)
    for n in range(32):
        start = round(n*step*RATE)
        bassroot = roots[n//8]
        lead = bassroot+12+tune[n%8]
        for i in range(int(step * RATE)):
            t = i / RATE
            note = 440*2**((lead-69)/12)
            bass = 440*2**((bassroot-69)/12)
            env = min(1,t/.012)*max(0,1-t/(step*.97))
            body = math.sin(math.tau*bass*t + .16*math.sin(math.tau*bass*2*t))* .19
            square = (math.sin(math.tau*note*t)+.24*math.sin(math.tau*note*3*t))* (.080 if n%4 in (0,3) else .054)
            kick = .13*math.sin(math.tau*(110*t-160*t*t))*math.exp(-t*19) if n%4==0 else 0
            hat = .055*rng.uniform(-1,1)*math.exp(-t*38) if n%2 else 0
            samples[(start+i)%length] = (body+square)*env+kick+hat
    save_audio(name,samples)

music('lobby', 112, [48, 45, 50, 43], [7,10,0,5,7,12,2,10])
music('arena', 144, [45, 43, 48, 41], [0,7,10,7,12,7,3,10])
music('finale', 154, [43, 46, 42, 41], [0,6,3,0,7,6,10,3])
