# --- call 1: empty the scene, metric units in metres, three Dome materials ---
import bpy

scene = bpy.context.scene

# Empty the scene: remove every object (Cube, Light, Camera)
removed = [o.name for o in scene.objects]
for obj in list(scene.objects):
    bpy.data.objects.remove(obj, do_unlink=True)

# Remove the data the default objects left behind, only where nothing uses it any more
for coll in (bpy.data.meshes, bpy.data.lights, bpy.data.cameras, bpy.data.materials):
    for block in list(coll):
        if block.users == 0:
            removed.append(f"{type(block).__name__}:{block.name}")
            coll.remove(block)
print("removed:", removed)

# Units: read the valid identifiers instead of hardcoding them
us = scene.unit_settings
systems = [i.identifier for i in us.bl_rna.properties["system"].enum_items]
print("unit systems available:", systems)
us.system = "METRIC" if "METRIC" in systems else us.system
us.scale_length = 1.0
try:
    us.length_unit = "METERS"
except TypeError as e:
    print("length_unit not set:", e)

# Three flat-colour materials (metallic 0, roughness 0.5, like Fork_Silver)
def socket(node, ident):
    return next(s for s in node.inputs if s.identifier == ident)

colours = {
    "Dome_Cream": (0.95, 0.85, 0.65, 1.0),
    "Dome_Pink": (0.95, 0.60, 0.70, 1.0),
    "Dome_Red": (0.70, 0.03, 0.05, 1.0),
}
for name, rgba in colours.items():
    mat = bpy.data.materials.new(name)
    if hasattr(mat, "use_nodes") and not mat.use_nodes:
        mat.use_nodes = True
    bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    socket(bsdf, "Base Color").default_value = rgba
    socket(bsdf, "Metallic").default_value = 0.0
    socket(bsdf, "Roughness").default_value = 0.5
    mat.diffuse_color = rgba  # viewport colour
    mat.metallic = 0.0
    mat.roughness = 0.5
    mat.use_fake_user = True  # keep it through a save while no object uses it yet
    print("material:", mat.name, "| base colour:", tuple(round(v, 3) for v in socket(bsdf, "Base Color").default_value),
          "| metallic:", socket(bsdf, "Metallic").default_value, "| roughness:", socket(bsdf, "Roughness").default_value,
          "| fake user:", mat.use_fake_user)

print("unit system:", us.system, "| length_unit:", us.length_unit, "| scale_length:", us.scale_length)
print("objects left:", len(scene.objects), "| materials:", [m.name for m in bpy.data.materials])

# --- call 2: Base (cylinder, 16 sides, 1.0 m diameter, Z 0.00 to 0.10) ---
import bpy

name, radius, depth, centre = "Base", 0.50, 0.10, (0.0, 0.0, 0.05)

# Read the valid cap-fill identifiers instead of hardcoding them
fills = [i.identifier for i in bpy.ops.mesh.primitive_cylinder_add.get_rna_type().properties["end_fill_type"].enum_items]
print("end_fill_type options:", fills)

bpy.ops.object.select_all(action="DESELECT")
bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=radius, depth=depth, end_fill_type="NGON", location=centre)
obj = bpy.context.active_object
obj.name = name
obj.data.name = name
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
obj.data.materials.clear()
obj.data.materials.append(bpy.data.materials["Dome_Cream"])

world = [obj.matrix_world @ v.co for v in obj.data.vertices]
r = lambda vals: tuple(round(v, 4) for v in vals)
print(name, "| location", r(obj.location), "| dimensions", r(obj.dimensions), "| scale", r(obj.scale),
      "| x", r((min(p.x for p in world), max(p.x for p in world))),
      "| z", r((min(p.z for p in world), max(p.z for p in world))),
      "| tris", sum(len(p.vertices) - 2 for p in obj.data.polygons),
      "| faces", len(obj.data.polygons),
      "| materials", [m.name for m in obj.data.materials])

# --- call 3: Cover (half UV sphere, 16 segments x 8 rings, radius 0.45, Z 0.10 to 0.55) ---
import bpy
import bmesh

name, radius, centre = "Cover", 0.45, (0.0, 0.0, 0.10)

bpy.ops.object.select_all(action="DESELECT")
bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=radius, location=centre)
obj = bpy.context.active_object
obj.name = name
obj.data.name = name

# Keep the top half: snap the equator ring to local z = 0, delete every vertex below it, close the bottom
bm = bmesh.new()
bm.from_mesh(obj.data)
for v in bm.verts:
    if abs(v.co.z) < 1e-5:
        v.co.z = 0.0
bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < 0.0], context="VERTS")
open_edges = [e for e in bm.edges if e.is_boundary]
bmesh.ops.holes_fill(bm, edges=open_edges, sides=0)
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
bm.to_mesh(obj.data)
bm.free()
obj.data.update()

bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
obj.data.materials.clear()
obj.data.materials.append(bpy.data.materials["Dome_Pink"])

world = [obj.matrix_world @ v.co for v in obj.data.vertices]
r = lambda vals: tuple(round(v, 4) for v in vals)
bottom = [p for p in obj.data.polygons if len(p.vertices) > 4]
print(name, "| location", r(obj.location), "| dimensions", r(obj.dimensions), "| scale", r(obj.scale),
      "| x", r((min(p.x for p in world), max(p.x for p in world))),
      "| z", r((min(p.z for p in world), max(p.z for p in world))),
      "| tris", sum(len(p.vertices) - 2 for p in obj.data.polygons),
      "| faces", len(obj.data.polygons),
      "| open edges before fill", len(open_edges),
      "| bottom face sides", [len(p.vertices) for p in bottom],
      "| bottom normal z", [round(p.normal.z, 3) for p in bottom],
      "| materials", [m.name for m in obj.data.materials])

# --- call 4: Cherry (UV sphere, 8 segments x 6 rings, 0.24 m diameter, Z 0.51 to 0.75) ---
import bpy

name, radius, centre = "Cherry", 0.12, (0.0, 0.0, 0.63)

bpy.ops.object.select_all(action="DESELECT")
bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=6, radius=radius, location=centre)
obj = bpy.context.active_object
obj.name = name
obj.data.name = name
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
obj.data.materials.clear()
obj.data.materials.append(bpy.data.materials["Dome_Red"])

world = [obj.matrix_world @ v.co for v in obj.data.vertices]
r = lambda vals: tuple(round(v, 4) for v in vals)
print(name, "| location", r(obj.location), "| dimensions", r(obj.dimensions), "| scale", r(obj.scale),
      "| x", r((min(p.x for p in world), max(p.x for p in world))),
      "| z", r((min(p.z for p in world), max(p.z for p in world))),
      "| tris", sum(len(p.vertices) - 2 for p in obj.data.polygons),
      "| faces", len(obj.data.polygons),
      "| materials", [m.name for m in obj.data.materials])

# --- call 5: join Base, Cover and Cherry into Dome, origin at world origin, apply rotation and scale, clean up ---
# Material colours were changed by hand in Blender's Material tab before this call
# (Dome_Pink #D17390, Dome_Red #A6111E, Dome_Cream #F9DEA2). This call does not change or reset any colour.
import bpy

scene = bpy.context.scene
part_names = ["Base", "Cover", "Cherry"]
parts = [bpy.data.objects[n] for n in part_names]

# Join: select all three, make Base the active object; the result keeps the active object
bpy.ops.object.select_all(action="DESELECT")
for p in parts:
    p.select_set(True)
bpy.context.view_layer.objects.active = bpy.data.objects["Base"]
bpy.ops.object.join()
dome = bpy.context.active_object
dome.name = "Dome"
dome.data.name = "Dome"

# Origin to the world origin (the centre of the base underside); geometry does not move
saved_cursor = scene.cursor.location.copy()
scene.cursor.location = (0.0, 0.0, 0.0)
bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
scene.cursor.location = saved_cursor

# Apply rotation and scale
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

# Dome now uses all three materials, so the fake users are no longer needed
mat_names = ["Dome_Cream", "Dome_Pink", "Dome_Red"]
for n in mat_names:
    bpy.data.materials[n].use_fake_user = False

# Remove the meshes the join left behind, only where nothing uses them
leftovers = []
for n in ["Cover", "Cherry"]:
    mesh = bpy.data.meshes.get(n)
    if mesh is not None and mesh.users == 0:
        bpy.data.meshes.remove(mesh)
        leftovers.append(n)

world = [dome.matrix_world @ v.co for v in dome.data.vertices]
r = lambda vals: tuple(round(v, 4) for v in vals)
print("objects:", [o.name for o in scene.objects])
print("Dome | tris", sum(len(p.vertices) - 2 for p in dome.data.polygons),
      "| verts", len(dome.data.vertices), "| faces", len(dome.data.polygons))
print("dimensions", r(dome.dimensions), "| location", r(dome.location),
      "| rotation (deg)", r(tuple(a * 180 / 3.141592653589793 for a in dome.rotation_euler)), "| scale", r(dome.scale))
print("lowest vertex Z", round(min(p.z for p in world), 6), "| highest vertex Z", round(max(p.z for p in world), 6),
      "| X", r((min(p.x for p in world), max(p.x for p in world))),
      "| Y", r((min(p.y for p in world), max(p.y for p in world))))
tris_per_slot = {}
for p in dome.data.polygons:
    slot = dome.material_slots[p.material_index].material.name
    tris_per_slot[slot] = tris_per_slot.get(slot, 0) + len(p.vertices) - 2
print("material slots", [s.material.name for s in dome.material_slots], "| tris per material", tris_per_slot)
print("leftover meshes removed:", leftovers, "| meshes left:", [(m.name, m.users) for m in bpy.data.meshes])
print("cursor restored to", r(scene.cursor.location))

# Record the current colours (read only): node base colour in linear RGB, plus its sRGB hex for comparison
def to_srgb(c):
    return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055
for n in mat_names:
    mat = bpy.data.materials[n]
    bsdf = next(nd for nd in mat.node_tree.nodes if nd.type == "BSDF_PRINCIPLED")
    base = next(s for s in bsdf.inputs if s.identifier == "Base Color").default_value
    hex_srgb = "#" + "".join(f"{round(max(0.0, min(1.0, to_srgb(c))) * 255):02X}" for c in base[:3])
    print(n, "| base colour linear", tuple(round(c, 4) for c in base), "| as sRGB hex", hex_srgb,
          "| viewport colour", tuple(round(c, 4) for c in mat.diffuse_color),
          "| fake user", mat.use_fake_user, "| users", mat.users)
