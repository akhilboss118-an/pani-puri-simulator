"""Print material and texture information for an FBX.

Usage:
  blender --background --python inspect_material.py -- "input.fbx"
"""
import sys

import bpy

path = sys.argv[-1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=path)
print("IMAGES", [(i.name, i.size[:], i.filepath) for i in bpy.data.images])
for mat in bpy.data.materials:
    print("MATERIAL", mat.name, "use_nodes", mat.use_nodes, "diffuse", tuple(round(c, 3) for c in mat.diffuse_color))
    if not mat.use_nodes:
        continue
    for node in mat.node_tree.nodes:
        print("  NODE", node.type, node.name)
        if node.type == "BSDF_PRINCIPLED":
            base = node.inputs["Base Color"]
            print("    BASE", tuple(round(c, 3) for c in base.default_value), "linked", base.is_linked)
            if base.is_linked:
                print("    FROM", base.links[0].from_node.type)
        if node.type == "TEX_IMAGE":
            print("    IMAGE", node.image.name if node.image else None)
