"""Things at sea, painted-kawaii style (Olivier, 2026-10-22: "a sunken ship here, a rock there, a
whale there, a siren here, an atoll there"). blender -b -P tools/blender/build_sea_things.py
-> assets/art/export/models/<thing>.glb (+ assets/art/source/blender/sea_things.blend)

All sized for radius 1 at the waterline (y = 0) and scaled by the game to the obstacle's radius,
except the atoll, wreck, whale and siren, which have their own sizes noted below."""
import math
import os
import random
import sys

sys.path.append(os.path.dirname(__file__))
import kit  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets/art/export/models")


def lumpy(name, centre, radius, height, mat, seed, lumps=7):
    """A soft, rounded rock built from overlapping squashed spheres."""
    random.seed(seed)
    parts = [kit.sphere(name + "Core", centre, radius, mat, scale=(1, height / radius, 1), segments=16, rings=10)]
    for i in range(lumps):
        a = random.uniform(0, 2 * math.pi)
        r = radius * random.uniform(0.45, 0.75)
        d = radius * random.uniform(0.45, 0.8)
        parts.append(kit.sphere("%sLump%d" % (name, i), (centre[0] + math.cos(a) * d, centre[1] + random.uniform(-0.2, 0.25) * height,
                                centre[2] + math.sin(a) * d), r, mat, scale=(1, random.uniform(0.6, 1.1), 1), segments=12, rings=8))
    return parts


def rock():
    """A reef rock, radius 1 (just breaks the surface; mostly hidden under water)."""
    p = lumpy("Rock", (0, -0.1, 0), 1.0, 0.75, "rock", 1)
    p += lumpy("RockTop", (0.2, 0.25, -0.1), 0.45, 0.35, "rock_dark", 2, lumps=3)
    p.append(kit.sphere("Moss", (0.0, 0.4, 0.1), 0.35, "moss", scale=(1.2, 0.35, 1.0)))
    return p


def cliff():
    """A tall coastal rock, radius 1, height about 2.4 (the channel walls)."""
    p = lumpy("Cliff", (0, 0.7, 0), 1.0, 1.6, "rock", 3)
    p += lumpy("CliffTop", (0.1, 1.9, 0.05), 0.65, 0.5, "rock_dark", 4, lumps=4)
    p.append(kit.sphere("CliffGrass", (0.1, 2.35, 0.0), 0.6, "moss", scale=(1.1, 0.3, 1.1)))
    for i, (x, z) in enumerate(((0.3, 0.2), (-0.25, -0.1))):  # little tufts
        p.append(kit.sphere("Tuft%d" % i, (x, 2.55, z), 0.18, "leaf"))
    return p


def wreck():
    """A sunken ship, about 8 m long (radius 4 in the game): a tilted broken hull, two masts poking out."""
    p = [kit.box("WreckHull", (0, -0.2, 0), (7.0, 1.6, 2.6), "wood_hull", bevel=0.4, rot=(0.25, 0.3, 0.12))]
    p.append(kit.box("WreckDeck", (0.2, 0.55, 0.05), (5.0, 0.12, 2.0), "wood_dark", bevel=0.05, rot=(0.25, 0.3, 0.12)))
    p.append(kit.box("WreckBow", (3.8, 0.2, 1.1), (1.6, 1.3, 1.4), "wood_hull", bevel=0.4, rot=(0.25, 0.9, 0.3)))
    p.append(kit.cylinder("WreckMast1", (0.8, 0.0, 0.2), (2.0, 5.0, 1.1), 0.18, 0.12, "wood_dark", verts=10))
    p.append(kit.cylinder("WreckMast2", (-1.8, 0.0, -0.4), (-2.6, 3.4, -1.6), 0.16, 0.1, "wood_dark", verts=10))
    p.append(kit.cylinder("WreckYard", (1.0, 3.9, -0.7), (2.6, 4.3, 2.2), 0.07, mat="wood_dark", verts=8))
    sail = kit.mesh_from("WreckSail", [(1.3, 3.8, -0.4), (2.4, 4.1, 1.8), (2.2, 2.2, 1.6), (1.4, 2.6, 0.2)],
                         [(0, 1, 2, 3)], "sail", smooth=False)
    kit.finish(sail, smooth=False, solidify=0.03)
    p.append(sail)
    p.append(kit.mesh_from("WreckFlag", [(-2.6, 3.4, -1.6), (-2.5, 2.9, -1.4), (-3.4, 3.0, -1.9)], [(0, 1, 2)], "eye",
                           smooth=False))
    for i in range(4):  # barnacles
        p.append(kit.sphere("Barnacle%d" % i, (-2.0 + i * 1.2, 0.1, 1.35), 0.15, "trim_cream", scale=(1, 0.6, 1)))
    return p


def whale():
    """A big friendly whale, about 9 m long (radius 3.5), facing +x. Tail is a separate object."""
    p = [kit.sphere("WhaleBody", (0, 0.2, 0), 2.2, "whale", scale=(2.0, 0.85, 1.05), segments=28, rings=16)]
    p.append(kit.sphere("WhaleBelly", (0.4, -0.25, 0), 1.9, "belly", scale=(1.9, 0.6, 0.95), segments=24, rings=12))
    for side in (-1, 1):
        p.append(kit.sphere("WhaleEye%d" % side, (2.9, 0.6, side * 1.75), 0.32, "eye", scale=(0.6, 1.0, 0.5)))
        p.append(kit.sphere("WhaleShine%d" % side, (3.0, 0.72, side * 1.95), 0.1, "white"))
        p.append(kit.sphere("WhaleBlush%d" % side, (3.2, 0.0, side * 1.7), 0.32, "blush", scale=(1, 0.5, 0.4)))
        p.append(kit.sphere("WhaleFin%d" % side, (1.0, -0.4, side * 2.2), 0.8, "whale", scale=(1.0, 0.25, 0.7)))
    p.append(kit.cylinder("Blowhole", (1.6, 1.9, 0), (1.6, 2.0, 0), 0.18, mat="eye", verts=10))
    return p


def whale_tail():
    """The whale's tail (separate so it can wave), hinged at the origin, pointing -x."""
    p = [kit.sphere("TailStock", (-1.0, 0.1, 0), 0.9, "whale", scale=(1.6, 0.6, 0.6))]
    for side in (-1, 1):
        p.append(kit.sphere("Fluke%d" % side, (-2.5, 0.4, side * 0.9), 0.9, "whale", scale=(0.9, 0.18, 1.1)))
    return p


def siren():
    """A siren on her rock (radius 2.5): a kawaii mermaid with long pink hair, singing."""
    p = lumpy("SirenRock", (0, 0.2, 0), 2.2, 1.1, "rock", 7)
    p.append(kit.sphere("SirenMoss", (0.1, 1.2, 0), 1.2, "moss", scale=(1.2, 0.25, 1.1)))
    # Tail curling over the rock.
    for i in range(6):
        t = i / 5
        p.append(kit.sphere("Tail%d" % i, (-0.9 + t * 1.2, 1.4 + math.sin(t * 2.5) * 0.25, 0.6 - t * 0.5), 0.36 - t * 0.12,
                            "tail"))
    p.append(kit.sphere("TailFin", (0.5, 1.8, 0.0), 0.35, "tail", scale=(0.5, 1.0, 1.4)))
    p.append(kit.sphere("SirenBody", (-1.0, 2.0, 0.6), 0.42, "skin", scale=(1, 1.3, 0.9)))
    p.append(kit.sphere("Shell1", (-0.85, 2.25, 0.9), 0.14, "blush", scale=(1, 1, 0.5)))
    p.append(kit.sphere("SirenHead", (-1.1, 2.95, 0.65), 0.55, "skin", segments=24, rings=14))
    p.append(kit.sphere("SirenHair", (-1.3, 3.05, 0.55), 0.62, "hair", scale=(1, 1.05, 1)))
    for i in range(4):
        p.append(kit.sphere("HairLock%d" % i, (-1.6 + i * 0.05, 2.5 - i * 0.25, 0.4 - i * 0.05), 0.3, "hair",
                            scale=(0.8, 1.3, 0.8)))
    for side in (-1, 1):  # she faces +z (towards the lane)
        p.append(kit.sphere("SirenEye%d" % side, (-1.1 + side * 0.2, 2.98, 1.12), 0.1, "eye", scale=(0.8, 1.2, 0.5)))
        p.append(kit.sphere("SirenShine%d" % side, (-1.06 + side * 0.2, 3.03, 1.17), 0.03, "white"))
        p.append(kit.sphere("SirenBlush%d" % side, (-1.1 + side * 0.3, 2.82, 1.08), 0.07, "blush", scale=(1, 0.6, 0.4)))
    p.append(kit.sphere("SirenMouth", (-1.1, 2.8, 1.15), 0.06, "blush"))  # singing "o"
    p.append(kit.sphere("Starfish", (-1.35, 3.5, 0.8), 0.13, "gold", scale=(1, 0.4, 1)))
    return p


def atoll():
    """A little ring island (radius 12) with a turquoise lagoon and palm trees."""
    random.seed(11)
    p = [kit.torus("AtollSand", (0, -0.15, 0), 9.5, 2.6, "sand")]
    p[0].scale = (1.0, 1.0, 0.28)
    p.append(kit.cylinder("Lagoon", (0, -0.05, 0), (0, 0.02, 0), 8.0, mat="water", verts=40))
    for i in range(5):
        a = i * 2 * math.pi / 5 + random.uniform(-0.3, 0.3)
        x, z = math.cos(a) * 9.5, math.sin(a) * 9.5
        p += palm("Palm%d" % i, (x, 0.5, z), random.uniform(3.0, 4.2), random.uniform(0, math.pi * 2))
    for i in range(6):
        a = random.uniform(0, 2 * math.pi)
        p.append(kit.sphere("Bush%d" % i, (math.cos(a) * 10, 0.6, math.sin(a) * 10), random.uniform(0.6, 1.0), "leaf"))
    p.append(kit.box("TinyChest", (9.2, 0.7, 2.0), (0.6, 0.45, 0.45), "paint_red", bevel=0.08))
    return p


def palm(name, base, height, lean):
    p = []
    segs = 6
    for i in range(segs):
        t0, t1 = i / segs, (i + 1) / segs
        a = (base[0] + math.cos(lean) * t0 * t0 * 1.2, base[1] + t0 * height, base[2] + math.sin(lean) * t0 * t0 * 1.2)
        b = (base[0] + math.cos(lean) * t1 * t1 * 1.2, base[1] + t1 * height, base[2] + math.sin(lean) * t1 * t1 * 1.2)
        p.append(kit.cylinder("%sTrunk%d" % (name, i), a, b, 0.22 - t0 * 0.08, 0.2 - t1 * 0.08, "wood_light", verts=8))
    top = (base[0] + math.cos(lean) * 1.2, base[1] + height, base[2] + math.sin(lean) * 1.2)
    for j in range(6):
        a = j * math.pi / 3
        tip = (top[0] + math.cos(a) * 1.8, top[1] - 0.6, top[2] + math.sin(a) * 1.8)
        mid = ((top[0] + tip[0]) / 2, top[1] + 0.25, (top[2] + tip[2]) / 2)
        w = 0.45
        sx, sz = -math.sin(a) * w, math.cos(a) * w
        leaf = kit.mesh_from("%sLeaf%d" % (name, j), [top, (mid[0] + sx, mid[1], mid[2] + sz), tip,
                                                      (mid[0] - sx, mid[1], mid[2] - sz)], [(0, 1, 2, 3)], "leaf",
                             smooth=False)
        kit.finish(leaf, smooth=False, solidify=0.04)
        p.append(leaf)
    for k in range(3):
        p.append(kit.sphere("%sCoconut%d" % (name, k), (top[0] + math.cos(k * 2.1) * 0.25, top[1] - 0.25,
                                                         top[2] + math.sin(k * 2.1) * 0.25), 0.16, "wood_dark"))
    return p


def fish(kind):
    """Catchable fish for the fishing minigame, about 0.6 m, facing +x."""
    colours = {"sardine": "iron", "goldfish": "gold", "pufferfish": "sand", "squid": "blush"}
    mat = colours[kind]
    if kind == "squid":
        p = [kit.sphere("SquidHead", (0.15, 0.1, 0), 0.25, mat, scale=(1.4, 1, 1))]
        for i in range(5):
            a = (i - 2) * 0.25
            p.append(kit.cylinder("Tentacle%d" % i, (-0.1, 0.05, a * 0.4), (-0.5, 0.0 + math.sin(i) * 0.08, a * 0.6), 0.05,
                                  0.02, mat, verts=6))
    elif kind == "pufferfish":
        p = [kit.sphere("PufferBody", (0, 0.1, 0), 0.3, mat)]
        for i in range(10):
            a, b = i * 0.63, (i % 3) * 0.9
            p.append(kit.cylinder("Spike%d" % i, (math.cos(a) * 0.25, 0.1 + math.sin(b) * 0.2, math.sin(a) * 0.25),
                                  (math.cos(a) * 0.4, 0.1 + math.sin(b) * 0.32, math.sin(a) * 0.4), 0.03, 0.0, "wood_light",
                                  verts=5))
    else:
        p = [kit.sphere("FishBody", (0, 0.1, 0), 0.3, mat, scale=(1.4, 0.8, 0.5))]
        p.append(kit.mesh_from("FishTail", [(-0.35, 0.1, 0), (-0.65, 0.35, 0), (-0.65, -0.15, 0)], [(0, 1, 2)], mat,
                               smooth=False))
    for side in (-1, 1):
        p.append(kit.sphere("FishEye%d" % side, (0.26, 0.17, side * 0.12), 0.06, "eye"))
        p.append(kit.sphere("FishShine%d" % side, (0.28, 0.19, side * 0.15), 0.02, "white"))
    return p


def port():
    """The destination harbour: a stone quay (front edge at x = 0, 30 m deep, 70 m wide) with a wooden
    pier, a striped lighthouse, little houses and cargo waiting on the dock."""
    random.seed(21)
    p = [kit.box("Quay", (15, 0.6, 0), (30, 2.4, 70), "rock", bevel=0.5)]
    p.append(kit.box("QuayTop", (15, 1.85, 0), (30, 0.2, 70), "sand", bevel=0.1))
    p.append(kit.box("Pier", (-6, 1.3, -14), (12, 0.25, 4), "wood_light", bevel=0.06))
    for i in range(4):
        for side in (-1, 1):
            p.append(kit.cylinder("PierPost%d%d" % (i, side), (-11 + i * 3, -1.0, -14 + side * 1.8),
                                  (-11 + i * 3, 1.6, -14 + side * 1.8), 0.22, mat="wood_dark", verts=8))
    # Lighthouse on the corner.
    for i in range(5):
        y0 = 2.0 + i * 2.2
        p.append(kit.cylinder("Lighthouse%d" % i, (4, y0, 28), (4, y0 + 2.2, 28), 2.0 - i * 0.18, 1.82 - i * 0.18,
                              "paint_red" if i % 2 == 0 else "trim_cream", verts=24))
    p.append(kit.cylinder("LampRoom", (4, 13.0, 28), (4, 14.6, 28), 1.1, mat="glow", verts=16))
    p.append(kit.sphere("LampRoof", (4, 14.7, 28), 1.4, "paint_teal", scale=(1, 0.7, 1)))
    # Little houses.
    for i, z in enumerate((-24, -8, 8)):
        x = 18 + random.uniform(-2, 2)
        p.append(kit.box("House%d" % i, (x, 4.0, z), (6, 4.2, 6), "trim_cream", bevel=0.25))
        roof = kit.cylinder("Roof%d" % i, (x, 6.6, z - 3.4), (x, 6.6, z + 3.4), 3.6, mat="paint_red" if i != 1 else "paint_teal",
                            verts=3)
        roof.rotation_euler[1] = math.pi / 2
        p.append(roof)
        p.append(kit.box("Door%d" % i, (x - 3.02, 2.9, z), (0.1, 2.0, 1.2), "wood_dark", bevel=0.05))
        p.append(kit.box("Win%d" % i, (x - 3.02, 4.6, z + 1.8), (0.1, 1.0, 1.0), "glow", bevel=0.05))
    for i in range(6):
        p.append(kit.box("DockCrate%d" % i, (4 + (i % 3) * 1.4, 2.6, -2 + (i // 3) * 1.4), (1.2, 1.2, 1.2), "wood_hull",
                         bevel=0.08))
    return p


def barrel():
    """A floating cask (radius about 0.8): a cannon target that bursts into loot."""
    p = [kit.cylinder("Cask", (0, -0.5, 0), (0, 0.7, 0), 0.62, 0.55, "wood_hull", verts=18)]
    for y in (-0.25, 0.45):
        p.append(kit.torus("CaskHoop%.0f" % (y * 100), (0, y, 0), 0.6, 0.05, "iron"))
    p.append(kit.cylinder("CaskStripe", (0, 0.05, 0), (0, 0.2, 0), 0.63, 0.63, "paint_red", verts=18))
    p.append(kit.cylinder("CaskLid", (0, 0.7, 0), (0, 0.74, 0), 0.5, mat="wood_light", verts=18))
    p.append(kit.cylinder("CaskFlagPole", (0.2, 0.74, 0), (0.2, 1.6, 0), 0.03, mat="wood_dark", verts=6))
    p.append(kit.mesh_from("CaskFlag", [(0.2, 1.6, 0), (0.2, 1.25, 0), (0.7, 1.42, 0)], [(0, 1, 2)], "gold", smooth=False))
    return p


THINGS = {
    "barrel": barrel,
    "port": port,
    "rock": rock, "cliff": cliff, "wreck": wreck, "whale": whale, "whale_tail": whale_tail, "siren": siren,
    "atoll": atoll, "fish_sardine": lambda: fish("sardine"), "fish_goldfish": lambda: fish("goldfish"),
    "fish_pufferfish": lambda: fish("pufferfish"), "fish_squid": lambda: fish("squid"),
}


def main():
    kit.reset()
    os.makedirs(OUT, exist_ok=True)
    for name, build in THINGS.items():
        kit.into(name)
        kit.parent_all(name, build())
        kit.export(name, os.path.join(OUT, name + ".glb"))
    kit.save(os.path.join(ROOT, "assets/art/source/blender/sea_things.blend"))


main()
