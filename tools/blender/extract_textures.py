"""Extract embedded textures from an FBX and report material links.

Usage:
  blender --background --python extract_textures.py -- "input.fbx" "out_dir"
"""
import os
import sys

import bpy

argv = sys.argv[sys.argv.index("--") + 1:]
src, out_dir = argv[0], argv[1]
os.makedirs(out_dir, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=src)

for image in bpy.data.images:
    print("IMAGE", image.name, "size", tuple(image.size), "packed", bool(image.packed_file), "file", image.filepath)
    if image.size[0] == 0:
        continue
    image.filepath_raw = os.path.join(out_dir, image.name.replace(".", "_") + ".png")
    image.file_format = "PNG"
    try:
        image.save()
        print("SAVED", image.filepath_raw)
    except Exception as exc:  # noqa: BLE001
        print("SAVE_FAILED", image.name, exc)

for mat in bpy.data.materials:
    if not mat.use_nodes:
        continue
    for node in mat.node_tree.nodes:
        if node.type == "TEX_IMAGE":
            print("TEXNODE", mat.name, node.name, "image", node.image.name if node.image else None)
