"""Convert a folder of user-supplied T-pose FBX characters into game-ready GLBs.

What it does per character:
  * imports the FBX and applies the object transform (the FBX ships with a
    -90 deg X rotation, so local coords are not Z-up until it is applied)
  * rebuilds the material with the embedded atlas (the FBX's own image link is
    broken), downsized for mobile/web
  * bends the T-pose arms down around the shoulders
  * decimates to a triangle budget
  * scales to a consistent height, puts the feet on the origin, faces Godot -Z
  * exports a compressed GLB

Usage:
  blender --background --python convert_customers.py -- <src_dir> <dst_dir>

The source file names are never used in the output: characters are written as
customer_1.glb .. customer_7.glb so no personal name ships with the game.
"""
import math
import os
import sys

import bpy
from mathutils import Vector

TARGET_HEIGHT = 1.68
TARGET_TRIS = 6500
ATLAS_SIZE = 512
ARM_DROP_DEGREES = 68.0
SHOULDER_HEIGHT = 0.705
SHOULDER_WIDTH = 0.125

# Explicit, ordered mapping. Source names stay only in this build tool.
SOURCES = [
    "Akhilboss.fbx",
    "Harika.fbx",
    "Nandini.fbx",
    "Navaneeth.fbx",
    "Pavan.fbx",
    "pravalika.fbx",
    "Srikar.fbx",
]


def smoothstep(value: float) -> float:
    value = max(0.0, min(1.0, value))
    return value * value * (3.0 - 2.0 * value)


def bounds(mesh: bpy.types.Mesh) -> tuple[Vector, Vector]:
    low = Vector((1e9, 1e9, 1e9))
    high = Vector((-1e9, -1e9, -1e9))
    for vertex in mesh.vertices:
        co = vertex.co
        low = Vector((min(low.x, co.x), min(low.y, co.y), min(low.z, co.z)))
        high = Vector((max(high.x, co.x), max(high.y, co.y), max(high.z, co.z)))
    return low, high


def apply_transforms(obj: bpy.types.Object) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


def clear_custom_normals(obj: bpy.types.Object) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    try:
        bpy.ops.mesh.customdata_custom_splitnormals_clear()
    except RuntimeError:
        pass


def center_xy(mesh: bpy.types.Mesh) -> None:
    low, high = bounds(mesh)
    center_x = (low.x + high.x) * 0.5
    center_y = (low.y + high.y) * 0.5
    for vertex in mesh.vertices:
        vertex.co.x -= center_x
        vertex.co.y -= center_y


def bend_arms(mesh: bpy.types.Mesh) -> None:
    low, high = bounds(mesh)
    height = max(high.z - low.z, 0.0001)
    shoulder_z = low.z + SHOULDER_HEIGHT * height
    shoulder_x = SHOULDER_WIDTH * height
    blend = 0.055 * height
    angle = math.radians(ARM_DROP_DEGREES)
    moved = 0
    for vertex in mesh.vertices:
        co = vertex.co
        reach = abs(co.x)
        if reach <= shoulder_x:
            continue
        if co.z > shoulder_z + 0.13 * height:
            continue
        if co.z < shoulder_z - 0.16 * height and reach < 0.22 * height:
            continue
        weight = smoothstep((reach - shoulder_x) / blend)
        if weight <= 0.0:
            continue
        side = 1.0 if co.x > 0.0 else -1.0
        theta = angle * weight * side
        pivot_x = side * shoulder_x
        dx = co.x - pivot_x
        dz = co.z - shoulder_z
        cos_t = math.cos(theta)
        sin_t = math.sin(theta)
        co.x = pivot_x + dx * cos_t + dz * sin_t
        co.z = shoulder_z - dx * sin_t + dz * cos_t
        moved += 1
    print("BENT_VERTS", moved)


def build_material() -> bpy.types.Material:
    atlas = None
    for image in bpy.data.images:
        if image.size[0] > 0 and image.size[1] > 0:
            if atlas is None or image.size[0] * image.size[1] > atlas.size[0] * atlas.size[1]:
                atlas = image
    if atlas is None:
        raise RuntimeError("No embedded texture found")
    atlas.scale(ATLAS_SIZE, ATLAS_SIZE)
    material = bpy.data.materials.new("CustomerAtlas")
    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Roughness"].default_value = 0.82
    bsdf.inputs["Metallic"].default_value = 0.0
    texture = nodes.new("ShaderNodeTexImage")
    texture.image = atlas
    texture.interpolation = "Linear"
    links.new(texture.outputs["Color"], bsdf.inputs["Base Color"])
    return material


def process(src: str, dst: str, index: int) -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=src)
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not meshes:
        raise RuntimeError("No mesh in " + src)
    mesh_obj = max(meshes, key=lambda obj: len(obj.data.vertices))
    apply_transforms(mesh_obj)
    clear_custom_normals(mesh_obj)
    bpy.ops.object.shade_smooth()

    mesh = mesh_obj.data
    print("SOURCE", os.path.basename(src), "verts", len(mesh.vertices), "uv_layers", len(mesh.uv_layers))
    if len(mesh.uv_layers) == 0:
        raise RuntimeError("Mesh has no UVs, cannot use the atlas")
    low, high = bounds(mesh)
    print("LOCAL_SIZE", tuple(round(v, 3) for v in (high - low)))

    material = build_material()
    mesh.materials.clear()
    mesh.materials.append(material)

    center_xy(mesh)
    bend_arms(mesh)

    triangles = sum(max(0, len(poly.vertices) - 2) for poly in mesh.polygons)
    ratio = min(1.0, float(TARGET_TRIS) / float(max(1, triangles)))
    if ratio < 0.999:
        modifier = mesh_obj.modifiers.new("Decimate", "DECIMATE")
        modifier.ratio = ratio
        bpy.context.view_layer.objects.active = mesh_obj
        mesh_obj.select_set(True)
        bpy.ops.object.modifier_apply(modifier=modifier.name)

    low, high = bounds(mesh)
    height = max(high.z - low.z, 0.0001)
    scale = TARGET_HEIGHT / height
    for vertex in mesh.vertices:
        vertex.co *= scale

    low, high = bounds(mesh)
    center_x = (low.x + high.x) * 0.5
    center_y = (low.y + high.y) * 0.5
    for vertex in mesh.vertices:
        vertex.co.x -= center_x
        vertex.co.y -= center_y
        vertex.co.z -= low.z
        # The source faces -Y in Blender; flip to +Y so it faces -Z in Godot.
        vertex.co.x = -vertex.co.x
        vertex.co.y = -vertex.co.y

    mesh.update()
    mesh_obj.location = (0.0, 0.0, 0.0)
    mesh_obj.rotation_euler = (0.0, 0.0, 0.0)
    mesh_obj.scale = (1.0, 1.0, 1.0)

    final_tris = sum(max(0, len(poly.vertices) - 2) for poly in mesh.polygons)
    low, high = bounds(mesh)
    print("OUTPUT_TRIS", final_tris, "SIZE", tuple(round(v, 3) for v in (high - low)))

    out_path = os.path.join(dst, "customer_%d.glb" % index)
    bpy.ops.object.select_all(action="DESELECT")
    mesh_obj.select_set(True)
    bpy.context.view_layer.objects.active = mesh_obj
    bpy.ops.export_scene.gltf(
        filepath=out_path,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_animations=False,
        export_materials="EXPORT",
        export_image_format="JPEG",
        export_jpeg_quality=80,
        export_texcoords=True,
        export_normals=True,
    )
    print("EXPORTED", out_path, os.path.getsize(out_path), "bytes")


def main() -> None:
    argv = sys.argv[sys.argv.index("--") + 1:]
    src_dir, dst_dir = argv[0], argv[1]
    only = int(argv[2]) if len(argv) > 2 else 0
    os.makedirs(dst_dir, exist_ok=True)
    for index, name in enumerate(SOURCES, start=1):
        if only and index != only:
            continue
        path = os.path.join(src_dir, name)
        if not os.path.exists(path):
            print("MISSING", path)
            continue
        process(path, dst_dir, index)


main()
