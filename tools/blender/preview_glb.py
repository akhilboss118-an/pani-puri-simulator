"""Render a preview of a converted GLB to verify orientation and pose.

Usage:
  blender --background --python preview_glb.py -- "input.glb" "output.png"
"""
import math
import sys

import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
src, dst = argv[0], argv[1]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)

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
print("BBOX", tuple(round(v, 3) for v in low), tuple(round(v, 3) for v in high))

camera_data = bpy.data.cameras.new("Camera")
camera = bpy.data.objects.new("Camera", camera_data)
bpy.context.scene.collection.objects.link(camera)
camera.location = center + Vector((0.0, size * 2.1, size * 0.12))
direction = center - camera.location
camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
camera_data.lens = 60
camera_data.clip_start = 0.01
camera_data.clip_end = 100.0
bpy.context.scene.camera = camera

sun_data = bpy.data.lights.new("Sun", type="SUN")
sun = bpy.data.objects.new("Sun", sun_data)
bpy.context.scene.collection.objects.link(sun)
sun.rotation_euler = (math.radians(58), 0, math.radians(25))
sun_data.energy = 3.5

fill_data = bpy.data.lights.new("Fill", type="AREA")
fill = bpy.data.objects.new("Fill", fill_data)
bpy.context.scene.collection.objects.link(fill)
fill.location = center + Vector((-size, -size * 1.4, size * 0.4))
fill_data.energy = 120.0
fill_data.size = size
fill.rotation_euler = (math.radians(70), 0, math.radians(-40))

world = bpy.data.worlds.new("World")
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.16, 0.17, 0.2, 1)
world.node_tree.nodes["Background"].inputs[1].default_value = 1.0
bpy.context.scene.world = world

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = 512
scene.render.resolution_y = 512
scene.render.filepath = dst
bpy.ops.render.render(write_still=True)
print("RENDERED", dst)
