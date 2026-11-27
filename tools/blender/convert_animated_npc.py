import os
import sys

import bpy

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def import_fbx(path):
    before = set(bpy.data.objects.keys())
    bpy.ops.import_scene.fbx(filepath=path)
    new = [o for o in bpy.data.objects if o.name not in before]
    return new

def original_armature(objects):
    arms = [o for o in objects if o.type == "ARMATURE"]
    if not arms:
        raise RuntimeError("no armature")
    return arms[0]

def extract_action(path, name, target_armature):
    new_objs = import_fbx(path)
    action = None
    for obj in new_objs:
        if obj.type == "ARMATURE" and obj.animation_data and obj.animation_data.action is not None:
            action = obj.animation_data.action
            break
    if action is not None:
        action.name = name
        track = target_armature.animation_data.nla_tracks.new()
        track.name = name
        track.strips.new(name, int(action.frame_range[0]), action)
    for obj in list(new_objs):
        bpy.data.objects.remove(obj, do_unlink=True)

def convert(idle_path, walk_path, eat_path, out_path):
    reset()
    base_objs = import_fbx(idle_path)
    armature = original_armature(base_objs)
    if armature.animation_data is None:
        armature.animation_data_create()
    idle = armature.animation_data.action
    if idle is not None:
        idle.name = "idle"
    extract_action(walk_path, "walk", armature)
    extract_action(eat_path, "eat", armature)
    bpy.ops.export_scene.gltf(
        filepath=out_path,
        export_format="GLB",
        export_yup=True,
        export_animations=True,
        export_nla_strips=True,
        export_current_frame=False,
        export_skins=True,
        export_materials="EXPORT",
        export_image_format="JPEG",
        export_jpeg_quality=80,
        export_cameras=False,
        export_lights=False,
    )
    print("EXPORTED", out_path, os.path.getsize(out_path), "bytes")
    print("ACTIONS", [a.name for a in bpy.data.actions])

def main():
    args = sys.argv[sys.argv.index("--") + 1:]
    convert(*args)

main()
