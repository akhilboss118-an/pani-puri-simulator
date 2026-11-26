"""Render a quick turntable preview of an imported FBX.

Usage:
  blender --background --python preview_fbx.py -- "input.fbx" "output.png"
"""
import math
import sys

import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
src, dst = argv[0], argv[1]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=src)

low = Vector((1e9, 1e9, 1e9))
high = Vector((-1e9, -1e9, -1e9))
for obj in bpy.context.scene.objects:
    if obj.type != "MESH":
        continue
    for corner in obj.bound_box:
        world = obj.matrix_world @ Vector(corner)
        low = Vector((min(low.x, world.x), min(low.y, world.y), min(low.z, world.z)))
        high = Vector((max(high.x, world.x), max(high.y, world.y), max(high.z, world.z)))
center = (low + high) * 0.5
size = max((high - low).x, (high - low).y, (high - low).z, 0.001)

camera_data = bpy.data.cameras.new("Camera")
camera = bpy.data.objects.new("Camera", camera_data)
bpy.context.scene.collection.objects.link(camera)
camera.location = center + Vector((size * 1.6, -size * 2.4, size * 0.7))
direction = center - camera.location
camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
camera_data.lens = 55
camera_data.clip_start = max(size * 0.01, 0.0001)
camera_data.clip_end = max(size * 100.0, 10.0)
bpy.context.scene.camera = camera

sun_data = bpy.data.lights.new("Sun", type="SUN")
sun = bpy.data.objects.new("Sun", sun_data)
bpy.context.scene.collection.objects.link(sun)
sun.rotation_euler = (math.radians(55), 0, math.radians(35))
sun_data.energy = 3.0

world = bpy.data.worlds.new("World")
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.12, 0.13, 0.15, 1)
world.node_tree.nodes["Background"].inputs[1].default_value = 1.0
bpy.context.scene.world = world

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = 512
scene.render.resolution_y = 512
scene.render.film_transparent = False
scene.render.filepath = dst
bpy.ops.render.render(write_still=True)
print("RENDERED", dst)
