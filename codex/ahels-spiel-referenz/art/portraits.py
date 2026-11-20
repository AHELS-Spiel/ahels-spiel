"""Handgezeichnete Portraits und Köpfe für das Figurenmenü und die Kampf-Sprites."""
from random import Random
from PIL import Image, ImageDraw

# Wangenbreite, Kinnbreite, Kinnhöhe, Augenhöhe, Augenabstand, Nasenlänge,
# Augenfarbe, Mundwinkel. Die Konturen stammen aus den sichtbaren Vorlagen.
FACES = [
    (18, 12, 62, 35, 10, 13, '#63432d', 3),
    (17, 13, 61, 36, 10, 12, '#6b4530', 2),
    (17, 13, 62, 35, 10, 13, '#4d637f', 0),
    (17, 11, 62, 35, 10, 13, '#526b82', 2),
    (19, 15, 64, 39, 10, 13, '#5d6e8b', 1),
    (17, 10, 65, 35, 10, 14, '#57706c', 2),
    (18, 12, 63, 36, 10, 14, '#617b87', 1),
    (17, 11, 62, 35, 10, 13, '#67786e', 3),
    (18, 12, 62, 37, 11, 13, '#557086', 4),
    (16, 11, 62, 36, 10, 13, '#667d77', 2),
    (17, 12, 62, 36, 10, 13, '#756556', 1),
    (17, 10, 61, 36, 11, 13, '#7e5733', 2),
    (17, 13, 63, 36, 10, 14, '#503528', 0),
    (17, 12, 63, 37, 10, 13, '#5c3823', 3),
    (16, 12, 64, 36, 10, 14, '#607987', 1),
    (17, 10, 63, 35, 10, 14, '#5c7581', 1),
    (18, 12, 64, 36, 10, 14, '#78855f', 2),
    (17, 10, 60, 34, 11, 12, '#7a7448', 3),
    (17, 12, 63, 35, 10, 13, '#77644e', 4),
    (17, 11, 64, 35, 10, 14, '#66808d', 0),
    (17, 11, 61, 36, 10, 13, '#67767b', 1),
    (17, 11, 61, 35, 10, 13, '#51403b', 2),
    (17, 12, 63, 35, 10, 13, '#657b79', 2),
    (17, 12, 62, 35, 10, 13, '#617782', 1),
    (17, 12, 66, 36, 10, 14, '#536f91', 2),
    (17, 12, 65, 36, 10, 14, '#785f4c', 4),
]

HAIR = {
    'center_wave': [(13,43),(11,38),(10,31),(8,26),(10,20),(12,17),(17,15),
                    (20,11),(25,10),(29,11),(33,8),(36,10),(40,8),(44,10),
                    (49,10),(54,13),(57,17),(60,20),(60,26),(62,31),(60,37),
                    (57,40),(55,37),(53,32),(49,28),(45,30),(42,31),(39,27),
                    (36,22),(34,26),(30,28),(27,31),(24,30),(20,34),(18,42)],
    'bowl': [(14,41),(12,34),(11,27),(12,20),(15,14),(21,10),(29,8),
             (38,8),(47,9),(54,12),(58,17),(61,23),(60,30),(58,35),
             (55,39),(54,33),(52,31),(49,32),(46,30),(43,32),(40,30),
             (37,32),(33,30),(30,32),(27,30),(24,32),(20,31),(18,40)],
    'longstraight': [(9,80),(9,70),(10,61),(10,53),(11,44),(11,34),(13,25),
                    (17,18),(22,13),(28,10),(34,8),(38,8),(44,10),(50,12),
                    (55,17),(59,24),(61,34),(61,45),(62,55),(64,65),(65,79),
                    (56,81),(51,75),(53,62),(54,53),(54,42),(52,31),(49,24),
                    (44,20),(37,16),(32,19),(26,24),(22,31),(20,41),(20,52),
                    (21,61),(22,75),(17,81)],
    'sweep': [(16,38),(13,29),(14,20),(16,14),(23,10),(31,8),(41,10),(49,12),
              (55,17),(59,25),(57,39),(53,35),(52,26),(49,23),(44,22),(33,26),(22,27),(19,34)],
    'crop': [(16,38),(14,31),(14,22),(17,16),(24,11),(33,10),(39,11),(41,10),
             (51,14),(56,21),(58,36),(54,38),(52,28),(46,27),(42,29),(39,27),(35,29),
             (32,27),(27,29),(23,27),(20,29),(19,37)],
    'fade': [(15,37),(13,30),(13,21),(18,16),(21,15),(22,12),(29,12),(34,10),(41,11),
             (47,10),(54,13),(59,20),(58,34),(55,38),(54,27),(52,24),(47,29),(44,26),
             (40,30),(36,27),(31,30),(28,26),(23,28),(20,24),(18,31)],
    'fringe': [(14,41),(12,30),(11,24),(14,16),(20,10),(28,8),(39,7),(49,10),(56,15),(59,24),
               (58,37),(55,43),(54,33),(49,31),(45,35),(44,29),(39,33),(37,27),(33,29),
               (30,37),(27,32),(22,35),(23,30),(18,35),(17,44)],
    'wave': [(11,51),(12,43),(9,37),(11,30),(9,25),(12,20),(13,15),(21,11),(24,8),(30,9),
             (36,7),(44,10),(51,9),(57,14),(60,21),(62,30),(61,39),(64,43),(63,51),(61,51),
             (60,58),(55,59),(53,52),(54,42),(49,34),(46,36),(44,31),(41,37),(38,35),
             (37,40),(34,39),(34,34),(31,31),(27,36),(22,34),(22,40),(18,43),(17,52),(13,55)],
    'wave_up': [(12,37),(8,34),(10,29),(8,22),(12,20),(13,14),(18,15),(19,11),(24,11),(27,8),
                (31,10),(36,6),(40,10),(44,7),(48,10),(54,9),(56,15),(59,17),(62,21),(64,28),
                (61,34),(56,37),(54,34),(51,36),(48,34),(45,29),(40,35),(37,32),(32,38),
                (29,33),(26,36),(24,31),(20,34),(16,33)],
    'curl': [(11,39),(10,36),(8,33),(9,28),(7,24),(10,21),(11,16),(15,14),(17,10),(21,10),
             (24,6),(29,7),(32,5),(37,7),(41,5),(45,6),(47,9),(51,8),(55,10),(57,14),(61,16),
             (61,20),(64,23),(63,28),(62,32),(59,36),(56,39),(53,36),(51,32),(48,35),(44,32),
             (43,29),(39,34),(35,32),(32,35),(28,32),(27,29),(23,33),(20,33),(17,37),(16,43)],
    'messy': [(13,40),(11,33),(12,25),(10,21),(14,19),(14,15),(20,15),(21,11),(17,8),
              (22,9),(26,13),(28,8),(29,5),(33,11),(34,7),(39,10),(41,6),(45,11),(49,8),
              (49,12),(55,13),(55,17),(60,20),(59,32),(56,39),(53,30),(48,27),(44,30),
              (39,27),(34,31),(29,27),(25,30),(20,28),(18,35),(17,43)],
    'part': [(13,48),(12,36),(11,28),(14,19),(17,15),(22,11),(28,9),(34,10),(37,8),(44,10),
             (51,12),(57,17),(59,22),(61,29),(59,44),(56,52),(54,49),(54,38),(52,30),
             (47,23),(43,21),(36,16),(31,21),(26,24),(22,31),(20,40),(18,48),(16,51)],
    'quiff': [(16,37),(13,31),(12,24),(14,18),(15,14),(20,14),(23,10),(28,11),(34,7),(40,9),
              (45,8),(51,11),(55,12),(59,16),(61,22),(58,31),(57,36),(53,37),(52,29),
              (50,27),(47,27),(41,24),(37,26),(34,24),(28,26),(24,27),(20,29),(19,39)],
    'side': [(14,42),(12,35),(13,29),(11,22),(14,16),(20,12),(26,10),(35,7),(43,9),
             (50,10),(56,14),(60,21),(59,32),(57,42),(54,40),(53,30),(50,25),(47,21),
             (43,25),(39,28),(35,28),(32,32),(25,33),(21,36),(17,36),(17,43)],
    'longhair': [(6,72),(10,66),(9,60),(12,54),(11,48),(13,39),(11,31),(14,22),(19,15),(25,10),
                 (31,8),(36,8),(39,7),(46,9),(54,14),(60,20),(61,28),(63,34),(63,41),(66,45),
                 (65,50),(67,54),(66,58),(70,63),(66,73),(58,77),(50,75),(51,67),(54,59),
                 (57,52),(55,39),(52,31),(49,24),(43,19),(37,16),(32,19),(26,25),(22,32),
                 (21,43),(20,50),(22,56),(19,63),(22,70),(17,78),(10,79)],
}

def pair_shade(color, shadow, amount):
    if isinstance(color, str):
        color = tuple(int(color[i:i+2], 16) for i in (1,3,5))
    if isinstance(shadow, str):
        shadow = tuple(int(shadow[i:i+2], 16) for i in (1,3,5))
    return tuple(round(a+(b-a)*amount) for a,b in zip(color,shadow))

def portrait(profile, index, bust=True):
    _, _, _, accent, hair, cut, shirt, skin, detail = profile
    cheeks, jaw, chin, eyes, spacing, nose, iris, smile = FACES[index]
    img = Image.new('RGBA',(72,84))
    d = ImageDraw.Draw(img)
    outline = '#292536'
    f_shadow = pair_shade(skin,'#80556c',.33)
    warm = pair_shade(skin,'#b97169',.38)
    f_light = pair_shade(skin,'#fff2d5',.26)
    f_middle = pair_shade(skin,'#fff2df',.12)
    h_shadow = pair_shade(hair,'#1c1b2e',.53)
    h_mid = pair_shade(hair,'#f0b585',.18)
    h_light = pair_shade(hair,'#f0c39f',.38)
    rng = Random(283+index*19)
    def poly(points, color):
        d.polygon(points, fill=color)
    def block(x1,y1,x2,y2,color):
        d.rectangle((x1,y1,x2,y2),fill=color)
    def line(points, color, width=1):
        d.line(points,fill=color,width=width)

    if bust:
        outer=[(3,83),(4,75),(9,70),(19,67),(26,64),(28,54),(45,54),
               (46,64),(53,67),(63,71),(68,78),(69,83)]
        poly(outer,outline)
        poly([(5,83),(7,75),(18,70),(27,67),(45,67),(57,71),(64,75),(66,83)],shirt)
        poly([(5,83),(7,77),(22,71),(28,76),(24,83)],pair_shade(shirt,'#171f34',.34))
        poly([(49,72),(60,74),(65,80),(66,83),(51,83)],pair_shade(shirt,'#e5c6ab',.21))
        poly([(28,55),(45,55),(45,64),(51,70),(44,78),(31,77),(24,71),(28,64)],f_shadow)
        poly([(32,59),(43,58),(42,66),(47,70),(42,76),(35,76),(32,70)],skin)
        if detail in ('collar', 'polo', 'teacher', 'polo_glasses'):
            collar = '#bf9166' if detail=='collar' else pair_shade(shirt,'#fff3dd',.17)
            poly([(26,65),(27,69),(35,75),(24,78),(20,71)],collar)
            poly([(44,64),(52,69),(48,79),(38,76),(44,71)],pair_shade(collar,'#695064',.25))
            line([(37,79),(37,83)],pair_shade(shirt,'#253553',.53))
            if detail=='collar':
                line([(25,69),(30,74)],'#6d503d',2)
                line([(47,69),(43,75)],'#6d503d',2)
        elif detail in ('hood', 'hood_glasses'):
            poly([(22,65),(31,73),(43,73),(51,65),(59,70),(51,79),(39,83),(26,80),(17,71)],
                 pair_shade(shirt,'#172135',.30))
            line([(22,68),(30,75),(29,83)],pair_shade(shirt,'#ede0cf',.48))
            line([(50,68),(44,76),(46,83)],pair_shade(shirt,'#ede0cf',.55))
            if detail == 'hood_glasses':
                poly([(1,83),(4,75),(18,69),(27,77),(28,83)], '#25232d')
                poly([(45,83),(47,75),(52,69),(66,76),(69,83)], '#25232d')
        elif detail == 'zip_jacket':
            poly([(1,83),(5,75),(20,68),(27,78),(27,83)], '#272630')
            poly([(46,83),(47,75),(52,68),(65,75),(69,83)], '#272630')
            line([(20,69),(26,78),(26,83)], '#c7c4bd')
        elif detail == 'jacket':
            poly([(24,67),(27,73),(28,83),(47,83),(47,72),(49,68)],'#e7dfd6' if index==8 else '#9e5f49')
            line([(22,71),(26,81),(26,83)],pair_shade(shirt,'#d2af9a',.34),2)
        else:
            line([(24,68),(30,75),(42,75),(48,68)],pair_shade(shirt,'#4d384e',.53),2)
            if detail in ('gold', 'chain') or index == 16:
                line([(27,67),(31,74),(37,78),(42,75),(47,68)],
                    '#c99959' if detail in ('gold', 'chain') else '#b7bbca')
                if detail == 'chain':
                    line([(37,77),(37,82)], '#c99959')
                    line([(35,79),(39,79)], '#c99959')
        if detail == 'teacher':
            poly([(23,66),(25,65),(48,82),(45,83)],'#7d543b')
            line([(23,67),(42,82)],'#af7b49')
    if cut in ('longhair','longstraight','wave','center_wave','part'):
        edge=(67 if bust else 62) if cut in ('longhair', 'longstraight') else 59
        poly([(14,22),(53,22),(60,43),(61,edge),(51,edge),(49,55),(18,55),(12,edge),(10,50)],h_shadow)

    ear_y = eyes - 3
    for ear_x, sign in [(36-cheeks,-1),(36+cheeks,1)]:
        poly([(ear_x,ear_y),(ear_x+sign*4,ear_y-1),(ear_x+sign*6,ear_y+4),
              (ear_x+sign*5,ear_y+13),(ear_x,ear_y+15),(ear_x-sign*1,ear_y+7)],f_shadow)
        line([(ear_x+sign*3,ear_y+2),(ear_x+sign*4,ear_y+6),
              (ear_x+sign*2,ear_y+10)],warm,2)
    face=[(18,23),(24,17),(35,15),(45,16),(54,23),(36+cheeks,eyes+8),
          (36+jaw+3,chin-10),(36+jaw,chin-4),(43,chin),(32,chin+1),
          (36-jaw,chin-4),(36-jaw-4,chin-12),(36-cheeks,eyes+9)]
    poly([(x,y+1) for x,y in face],outline)
    poly(face,skin)
    poly([(18,24),(24,20),(24,eyes),(24,eyes+7),(28,chin-12),(34,chin),(32,chin+1),
          (36-jaw,chin-4),(36-jaw-4,chin-12),(36-cheeks,eyes+9)],f_shadow)
    poly([(25,22),(39,19),(48,22),(50,28),(44,30),(30,30),(25,34)],f_middle)
    poly([(42,42),(50,41),(52,45),(45,49),(40,47)],f_light)
    poly([(23,43),(28,43),(31,47),(27,49),(23,49)],warm)
    poly([(40,chin-5),(46,chin-7),(43,chin),(34,chin+1),(33,chin-1)],f_shadow)
    for x in range(22,50,2):
        y=eyes+11+rng.randrange(4)
        if rng.random()<(.74 if index in (5,2) else .36):
            d.point((x,y),fill=pair_shade(skin,'#ac7666',.58))

    angle = -1 if index in (1, 4, 6, 10, 14, 15) else 0
    for e, x in enumerate((35-spacing,36+spacing)):
        y = eyes + (angle if e else 0)
        brow = pair_shade(hair,'#573742',.28)
        line([(x-6,y-4),(x-2,y-6),(x+2,y-5),(x+5,y-4)],brow,2 if index in (0,6,8,11,12,13) else 1)
        poly([(x-5,y+1),(x-2,y-1),(x+2,y-1),(x+5,y+1),(x+2,y+3),(x-2,y+3)],
             '#f4dfce')
        line([(x-5,y+1),(x-2,y-1),(x+2,y-1),(x+5,y+1)],'#754c46')
        block(x-1,y,x+2,y+2,iris)
        block(x,y,x+1,y+2,'#302930')
        d.point((x,y),fill='#fff0da')
        line([(x+2,y+4),(x+4,y+3)],pair_shade(skin,'#92585d',.35))
    ny = eyes + nose
    poly([(35,eyes+3),(38,eyes+5),(41,ny-2),(39,ny),(37,ny),
          (36,ny-4)],f_light)
    line([(32,ny),(34,ny-1),(37,ny+1),(40,ny)],warm)
    d.point((33,ny),fill=f_shadow)
    d.point((40,ny),fill=f_shadow)
    mouth_y = chin-7
    mouth_w = 7 if index not in (8, 13, 25) else 9
    line([(36-mouth_w,mouth_y-smile//2),(32,mouth_y),(38,mouth_y+1),
          (42,mouth_y),(36+mouth_w,mouth_y-smile+1)],'#995d60')
    if index in (0,8,13,18,25):
        poly([(31,mouth_y),(40,mouth_y),(42,mouth_y-1),(39,mouth_y+2),(33,mouth_y+2)],'#f7e6ce')
    line([(33,mouth_y+3),(40,mouth_y+3)],pair_shade(skin,'#ad6a72',.46))
    if detail in ('goatee','stubble') or index in (0,13):
        line([(31,mouth_y-3),(35,mouth_y-4),(40,mouth_y-3),(42,mouth_y-2)],
             pair_shade(skin,hair,.45))
        if detail == 'goatee':
            line([(32,chin-1),(36,chin),(42,chin-1)],pair_shade(skin,hair,.55),2)

    contour = HAIR[cut]
    poly([(x,y+1) for x,y in contour],outline)
    hm=Image.new('1',img.size)
    ImageDraw.Draw(hm).polygon(contour,fill=1)
    hc=Image.new('RGBA',img.size,h_shadow)
    hd=ImageDraw.Draw(hc)
    hd.polygon([(x,max(6,y-2)) for x,y in contour],fill=hair)
    if cut in ('side','sweep','part','longhair','longstraight','fringe','crop','fade','bowl'):
        for i in range(40):
            sx = rng.randint(10,54)
            sy = rng.randint(8,29)
            if cut in ('longhair','longstraight','part'):
                side = -1 if sx < 35 else 1
                q = [(sx,sy),(sx+side*3,sy+7),(sx+side*5,sy+15)]
            else:
                q = [(sx,sy),(sx+4,sy-2),(sx+9,sy-2)]
            hd.line(q, fill=rng.choice([h_mid,h_mid,h_light,h_shadow]),width=rng.choice([1,1,2]))
    else:
        for i in range(45):
            sx,sy=rng.randint(9,59),rng.randint(8,31)
            a = rng.randint(2,6)
            hd.line([(sx,sy),(sx+2,sy-2),(sx+a,sy-1),(sx+a+1,sy+2)],
                    fill=rng.choice([h_mid,h_light,h_shadow,h_shadow]),width=1)
    if cut in ('longhair','longstraight','wave'):
        for side in (-1,1):
            for i in range(8):
                x=36+side*(17+i)
                y=25+i
                hd.line([(x,y),(x+side*2,y+10),(x-side,y+19),(x+side*2,y+28),
                    (x+side*3,y+35)],fill=h_light if i%3==1 else h_mid,width=1)
    img.paste(hc,(0,0),hm)
    if detail in ('round','square','teacher','metal_round','hood_glasses','polo_glasses'):
        metal = detail in ('metal_round','hood_glasses','polo_glasses')
        ink = '#66594e' if metal else '#4d3e3e' if detail=='teacher' else '#221f2b'
        gleam = '#c4af97' if metal else '#b98b70' if detail=='teacher' else '#5a5666'
        for k,x in enumerate((35-spacing,36+spacing)):
            y=eyes+(angle if k else 0)
            if detail in ('round','metal_round','hood_glasses','polo_glasses'):
                points=[(x-8,y-3),(x-6,y-5),(x+5,y-5),(x+8,y-3),(x+7,y+5),
                        (x+3,y+8),(x-3,y+8),(x-7,y+4),(x-8,y-3)]
            else:
                points=[(x-8,y-5),(x+8,y-5),(x+7,y+6),(x+5,y+7),
                        (x-6,y+7),(x-7,y+5),(x-8,y-5)]
            line(points,ink,1 if detail=='teacher' or metal else 2)
            line([(x-5,y-5),(x,y-5)],gleam)
            line([(x-4,y+1),(x-3,y+2)],pair_shade(skin,'#d4e4f3',.45))
        line([(35-spacing+8,eyes-2),(35+spacing-7,eyes-2+angle)],ink,1)
        line([(35-spacing-8,eyes-3),(16,eyes-5)],ink)
    if index==17 and bust:
        block(54,47,55,50,'#dab06d')
        block(53,50,55,51,'#edc479')
    if not bust:
        # Cutout bounded to the head, keeping the different relative silhouettes.
        return img.crop((5,4,68,68))
    return img
