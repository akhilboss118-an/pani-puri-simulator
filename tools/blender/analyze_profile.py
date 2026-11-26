"""Print a z-histogram of a character mesh to locate the shoulder/arm band.

Usage:
  blender --background --python analyze_profile.py -- "input.fbx"
"""
import sys

import bpy

src = sys.argv[-1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src) if src.lower().endswith(".glb") else bpy.ops.import_scene.fbx(filepath=src)
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
obj = max(meshes, key=lambda o: len(o.data.vertices))
bpy.ops.object.select_all(action="DESELECT")
obj.select_set(True)
bpy.context.view_layer.objects.active = obj
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
mesh = obj.data
low = min(v.co.z for v in mesh.vertices)
high = max(v.co.z for v in mesh.vertices)
height = high - low
bins = 20
counts = [0] * bins
max_x = [0.0] * bins
for v in mesh.vertices:
    idx = min(bins - 1, int((v.co.z - low) / height * bins))
    counts[idx] += 1
    max_x[idx] = max(max_x[idx], abs(v.co.x))
for i in range(bins - 1, -1, -1):
    print("BAND %.2f-%.2f count %5d max|x| %.3f" % (
        low / height + i / bins * 1.0,
        low / height + (i + 1) / bins * 1.0,
        counts[i],
        max_x[i] / height,
    ))
