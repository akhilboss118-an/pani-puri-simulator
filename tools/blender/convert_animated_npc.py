"""Convert an animated Mixamo-style FBX trio (idle, walk, eat) into a single
game-ready GLB for Godot 4.

Fixes applied automatically:
  * 30 fps timeline preserved cleanly
  * Normalized height (default 1.68 m) and feet grounded on Z = 0 (Godot Y = 0)
  * Rotated 180 deg around world Z so Mixamo -Y faces Godot -Z (matching look_at)
  * Horizontal forward root drift stripped from walk animation (seamless in-place)
  * Trailing motionless tail trimmed from eat animation
  * Isolated NLA tracks ("idle", "walk", "eat") slid to t = 0
  * Deduplicated images, opaque body materials, and 1024px PNG/JPEG textures

Usage:
  blender --background --python convert_animated_npc.py -- <idle.fbx> <walk.fbx> <eat.fbx> <out.glb> [target_height]
"""
import math
import os
import sys
import tempfile

import bpy
import numpy as np
from mathutils import Vector

MAX_TEX_SIZE = 1024
JPEG_QUALITY = 85
DEFAULT_HEIGHT = 1.68


def reset() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.render.fps = 30
    bpy.context.scene.render.fps_base = 1.0


def import_fbx(path: str) -> list[bpy.types.Object]:
    before = set(bpy.data.objects.keys())
    bpy.ops.import_scene.fbx(filepath=path)
    return [o for o in bpy.data.objects if o.name not in before]


def find_armature(objects: list[bpy.types.Object]) -> bpy.types.Object:
    arms = [o for o in objects if o.type == "ARMATURE"]
    if not arms:
        raise RuntimeError("No armature found in FBX")
    return arms[0]


def get_fcurves(action: bpy.types.Action) -> list:
    if action is None:
        return []
    fcurves = []
    if hasattr(action, "layers") and len(action.layers) > 0:
        for layer in action.layers:
            for strip in layer.strips:
                if hasattr(strip, "channelbags"):
                    for cb in strip.channelbags:
                        fcurves.extend(cb.fcurves)
    elif hasattr(action, "fcurves"):
        fcurves = list(action.fcurves)
    return fcurves


def evaluated_mesh_bounds(objects: list[bpy.types.Object]) -> tuple[Vector, Vector]:
    bpy.context.view_layer.update()
    depsgraph = bpy.context.evaluated_depsgraph_get()
    low = Vector((1e9, 1e9, 1e9))
    high = Vector((-1e9, -1e9, -1e9))
    for obj in objects:
        if obj.type != "MESH":
            continue
        ev = obj.evaluated_get(depsgraph)
        me = ev.to_mesh()
        for v in me.vertices:
            w = obj.matrix_world @ v.co
            low.x = min(low.x, w.x)
            low.y = min(low.y, w.y)
            low.z = min(low.z, w.z)
            high.x = max(high.x, w.x)
            high.y = max(high.y, w.y)
            high.z = max(high.z, w.z)
        ev.to_mesh_clear()
    return low, high


def normalize_armature(armature: bpy.types.Object, objects: list[bpy.types.Object], target_height: float) -> None:
    bpy.context.scene.frame_set(1)
    low, high = evaluated_mesh_bounds(objects)
    cur_h = max(high.z - low.z, 0.001)
    factor = target_height / cur_h
    armature.scale = (
        armature.scale.x * factor,
        armature.scale.y * factor,
        armature.scale.z * factor,
    )
    # Mixamo FBX faces -Y in Blender (+Z in glTF); rotate 180 deg around world Z so it faces -Z in Godot.
    armature.rotation_mode = "XYZ"
    armature.rotation_euler.z += math.pi

    low, high = evaluated_mesh_bounds(objects)
    # Mixamo already centers the character between the feet on X/Y; only ground Z so pivots don't orbit when turning.
    armature.location.z -= low.z

    low, high = evaluated_mesh_bounds(objects)
    print(
        "NORMALIZED_BOUNDS",
        tuple(round(v, 3) for v in low),
        "to",
        tuple(round(v, 3) for v in high),
        "height=",
        round(high.z - low.z, 3),
    )


def strip_walk_root_motion(action: bpy.types.Action) -> None:
    f0, f1 = float(action.frame_range[0]), float(action.frame_range[1])
    span = max(1.0, f1 - f0)
    for fc in get_fcurves(action):
        if "Hips" in fc.data_path and fc.data_path.endswith("location"):
            kps = fc.keyframe_points
            if len(kps) < 2:
                continue
            first_v = kps[0].co[1]
            last_v = kps[-1].co[1]
            drift = last_v - first_v
            if abs(drift) > 5.0:
                print(f"STRIP_ROOT_DRIFT {fc.data_path}[{fc.array_index}] drift={drift:.3f}")
                for kp in kps:
                    u = (kp.co[0] - f0) / span
                    offset = drift * u
                    kp.co[1] -= offset
                    kp.handle_left[1] -= offset
                    kp.handle_right[1] -= offset
                fc.update()


def trim_trailing_hold(armature: bpy.types.Object, action: bpy.types.Action) -> float:
    """Trim motionless/breathing-only tail from one-shot clips (e.g. Mixamo eat)."""
    f0 = int(round(action.frame_range[0]))
    f1 = int(round(action.frame_range[1]))
    if f1 - f0 < 20:
        return float(f1)
    prev_action = armature.animation_data.action
    armature.animation_data.action = action
    arm_bones = [
        pb for pb in armature.pose.bones
        if any(k in pb.name for k in ("Arm", "Hand", "Head", "Neck"))
    ]
    if not arm_bones:
        arm_bones = list(armature.pose.bones)
    prev_quat = {}
    last_active = f0 + 20
    for f in range(f0, f1 + 1):
        bpy.context.scene.frame_set(f)
        max_delta = 0.0
        for pb in arm_bones:
            q = pb.matrix_basis.to_quaternion()
            if pb.name in prev_quat:
                dot = min(1.0, abs(q.dot(prev_quat[pb.name])))
                ang = 2.0 * math.acos(dot)
                if ang > max_delta:
                    max_delta = ang
            prev_quat[pb.name] = q
        if max_delta > 0.010:
            last_active = f
    armature.animation_data.action = prev_action
    trimmed = min(f1, last_active + 6)
    print(f"TRIM_EAT {f0}..{f1} -> {f0}..{trimmed} ({(trimmed - f0) / 30.0:.2f}s)")
    return float(trimmed)


def extract_action(path: str, name: str) -> bpy.types.Action:
    new_objs = import_fbx(path)
    action = None
    for obj in new_objs:
        if obj.type == "ARMATURE" and obj.animation_data and obj.animation_data.action is not None:
            action = obj.animation_data.action.copy()
            break
    for obj in list(new_objs):
        bpy.data.objects.remove(obj, do_unlink=True)
    if action is None:
        raise RuntimeError(f"No action in {path}")
    action.name = name
    return action


def push_nla_track(armature: bpy.types.Object, name: str, action: bpy.types.Action, end_frame: float | None = None) -> None:
    f0 = float(action.frame_range[0])
    f1 = float(end_frame) if end_frame is not None else float(action.frame_range[1])
    track = armature.animation_data.nla_tracks.new()
    track.name = name
    strip = track.strips.new(name, 1, action)
    strip.action_frame_start = f0
    strip.action_frame_end = f1
    strip.frame_start = 1.0
    strip.frame_end = 1.0 + (f1 - f0)


def deduplicate_and_optimize_textures(used_materials: set[bpy.types.Material], tmp_dir: str) -> None:
    # 1. Deduplicate identical packed images (e.g. BrowsMAP1..BrowsMAP1.006) and merge Color+Alpha sampler nodes.
    canonical_by_sig: dict[tuple, bpy.types.Image] = {}
    remap: dict[bpy.types.Image, bpy.types.Image] = {}
    alpha_needed: set[bpy.types.Image] = set()

    for mat in used_materials:
        if not mat or not mat.use_nodes:
            continue
        bsdf = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
        has_alpha = bool(bsdf and bsdf.inputs["Alpha"].is_linked)
        # Keep opaque materials strictly OPAQUE (FBX importer sets HASHED unnecessarily).
        mat.blend_method = "BLEND" if has_alpha else "OPAQUE"

        tex_nodes = [n for n in mat.node_tree.nodes if n.type == "TEX_IMAGE" and n.image is not None]
        for node in tex_nodes:
            img = node.image
            sig = (img.size[0], img.size[1], len(img.packed_file.data) if img.packed_file else 0, os.path.basename(img.filepath))
            if sig not in canonical_by_sig:
                canonical_by_sig[sig] = img
            canon = canonical_by_sig[sig]
            remap[img] = canon
            node.image = canon
            if has_alpha:
                alpha_needed.add(canon)

        # If a material uses the exact same canonical image for both Color and Alpha, reuse one TEX_IMAGE node.
        if bsdf and bsdf.inputs["Base Color"].is_linked and bsdf.inputs["Alpha"].is_linked:
            c_node = bsdf.inputs["Base Color"].links[0].from_node
            a_link = bsdf.inputs["Alpha"].links[0]
            a_node = a_link.from_node
            if (
                c_node.type == "TEX_IMAGE"
                and a_node.type == "TEX_IMAGE"
                and c_node != a_node
                and c_node.image == a_node.image
            ):
                mat.node_tree.links.remove(a_link)
                mat.node_tree.links.new(c_node.outputs["Alpha"], bsdf.inputs["Alpha"])
                mat.node_tree.nodes.remove(a_node)

    unique_imgs = set(remap.values())
    replaced_imgs: dict[bpy.types.Image, bpy.types.Image] = {}
    for img in unique_imgs:
        if img.size[0] == 0 or img.size[1] == 0:
            continue
        # Ensure pixels are cached in memory before dropping old packed data.
        arr = np.empty(img.size[0] * img.size[1] * 4, dtype=np.float32)
        img.pixels.foreach_get(arr)
        rgba = arr.reshape(-1, 4)
        uses_alpha = img in alpha_needed and float(rgba[:, 3].min()) < 0.995

        w, h = img.size[0], img.size[1]
        if max(w, h) > MAX_TEX_SIZE:
            scale = MAX_TEX_SIZE / float(max(w, h))
            nw = max(64, int(round(w * scale)))
            nh = max(64, int(round(h * scale)))
            img.scale(nw, nh)

        safe_name = "".join(c if c.isalnum() or c in "_-" else "_" for c in img.name)
        if uses_alpha:
            out_img = os.path.join(tmp_dir, safe_name + ".png")
            img.filepath_raw = out_img
            img.file_format = "PNG"
        else:
            out_img = os.path.join(tmp_dir, safe_name + ".jpg")
            img.filepath_raw = out_img
            img.file_format = "JPEG"
            bpy.context.scene.render.image_settings.quality = JPEG_QUALITY
        img.save()

        new_img = bpy.data.images.load(out_img, check_existing=False)
        new_img.name = safe_name
        new_img.colorspace_settings.name = img.colorspace_settings.name
        new_img.pack()
        replaced_imgs[img] = new_img
        print("TEX_OPT", new_img.name, new_img.size[:], "alpha=" + str(uses_alpha), os.path.getsize(out_img), "B")

    for mat in used_materials:
        if not mat or not mat.use_nodes:
            continue
        for node in mat.node_tree.nodes:
            if node.type == "TEX_IMAGE" and node.image in replaced_imgs:
                node.image = replaced_imgs[node.image]


def convert(idle_path: str, walk_path: str, eat_path: str, out_path: str, target_height: float = DEFAULT_HEIGHT) -> None:
    reset()
    base_objs = import_fbx(idle_path)
    armature = find_armature(base_objs)
    if armature.animation_data is None:
        armature.animation_data_create()

    idle_action = armature.animation_data.action
    if idle_action is None:
        raise RuntimeError(f"No action in idle FBX: {idle_path}")
    idle_action = idle_action.copy()
    idle_action.name = "idle"

    walk_action = extract_action(walk_path, "walk")
    strip_walk_root_motion(walk_action)

    eat_action = extract_action(eat_path, "eat")
    eat_end = trim_trailing_hold(armature, eat_action)

    # Clear active action so only clean, isolated NLA tracks drive export.
    armature.animation_data.action = None
    for track in list(armature.animation_data.nla_tracks):
        armature.animation_data.nla_tracks.remove(track)

    push_nla_track(armature, "idle", idle_action)
    push_nla_track(armature, "walk", walk_action)
    push_nla_track(armature, "eat", eat_action, end_frame=eat_end)

    normalize_armature(armature, base_objs, target_height)

    used_mats = set()
    for obj in base_objs:
        if obj.type == "MESH":
            for mat in obj.data.materials:
                if mat is not None:
                    used_mats.add(mat)

    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp_dir:
        deduplicate_and_optimize_textures(used_mats, tmp_dir)

        # Purge orphaned duplicate textures/actions before export
        for act in list(bpy.data.actions):
            if act not in (idle_action, walk_action, eat_action):
                bpy.data.actions.remove(act, do_unlink=True)
        bpy.ops.outliner.orphans_purge(do_local_ids=True, do_linked_ids=True, do_recursive=True)

        bpy.ops.object.select_all(action="DESELECT")
        for obj in base_objs:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = armature

        bpy.ops.export_scene.gltf(
            filepath=out_path,
            export_format="GLB",
            use_selection=True,
            export_yup=True,
            export_animations=True,
            export_animation_mode="NLA_TRACKS",
            export_nla_strips=True,
            export_merge_animation="NLA_TRACK",
            export_anim_slide_to_zero=True,
            export_current_frame=False,
            export_skins=True,
            export_materials="EXPORT",
            export_image_format="AUTO",
            export_jpeg_quality=JPEG_QUALITY,
            export_cameras=False,
            export_lights=False,
        )

    print("EXPORTED", out_path, os.path.getsize(out_path), "bytes")
    print("ACTIONS", [a.name for a in bpy.data.actions])


def main() -> None:
    args = sys.argv[sys.argv.index("--") + 1:]
    idle_path, walk_path, eat_path, out_path = args[:4]
    height = float(args[4]) if len(args) > 4 else DEFAULT_HEIGHT
    convert(idle_path, walk_path, eat_path, out_path, height)


if __name__ == "__main__":
    main()
