"""Inspect an FBX character before converting it for Godot.

Usage:
  blender --background --python inspect_fbx.py -- "E:/3d models/fbx models/Name.fbx"

Prints meshes, armature bone counts, actions and the world-space bounding box so
we can pick scale/orientation without guessing.
"""
import sys

import bpy
from mathutils import Vector


def main() -> None:
    path = sys.argv[-1]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=path)
    objs = list(bpy.context.scene.objects)
    print("FILE", path)
    print("OBJECTS", [(o.name, o.type) for o in objs])
    for obj in objs:
        if obj.type == "MESH":
            mats = [m.name if m else "None" for m in obj.data.materials]
            print("MESH", obj.name, "verts", len(obj.data.vertices), "materials", mats)
        elif obj.type == "ARMATURE":
            print("ARMATURE", obj.name, "bones", len(obj.data.bones))
    print("ACTIONS", [a.name for a in bpy.data.actions])
    low = Vector((1e9, 1e9, 1e9))
    high = Vector((-1e9, -1e9, -1e9))
    for obj in objs:
        if obj.type != "MESH":
            continue
        for corner in obj.bound_box:
            world = obj.matrix_world @ Vector(corner)
            low = Vector((min(low.x, world.x), min(low.y, world.y), min(low.z, world.z)))
            high = Vector((max(high.x, world.x), max(high.y, world.y), max(high.z, world.z)))
    print("BBOX_MIN", tuple(round(v, 3) for v in low))
    print("BBOX_MAX", tuple(round(v, 3) for v in high))
    print("SIZE", tuple(round(v, 3) for v in (high - low)))


main()
