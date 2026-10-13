# --- call 1: empty the scene, metric units in metres, two Platform materials ---
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

# Two flat-colour materials (metallic 0, roughness 0.5), colours given as sRGB hex and converted to linear
def socket(node, ident):
    return next(s for s in node.inputs if s.identifier == ident)

def to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

def hex_to_linear(h):
    h = h.lstrip("#")
    return tuple(to_linear(int(h[i:i + 2], 16) / 255) for i in (0, 2, 4)) + (1.0,)

def to_srgb(c):
    return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055

colours = {
    "Platform_Biscuit": "#B8752A",
    "Platform_Cream": "#F9DEA2",  # same as the hand-edited Dome_Cream
}
for name, hex_srgb in colours.items():
    rgba = hex_to_linear(hex_srgb)
    mat = bpy.data.materials.new(name)
    if hasattr(mat, "use_nodes") and not mat.use_nodes:
        mat.use_nodes = True
    bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    socket(bsdf, "Base Color").default_value = rgba
    socket(bsdf, "Metallic").default_value = 0.0
    socket(bsdf, "Roughness").default_value = 0.5
    mat.diffuse_color = rgba  # viewport colour, same as the base colour
    mat.metallic = 0.0
    mat.roughness = 0.5
    mat.use_fake_user = True  # keep it through a save while no object uses it yet
    base = socket(bsdf, "Base Color").default_value
    back = "#" + "".join(f"{round(max(0.0, min(1.0, to_srgb(c))) * 255):02X}" for c in base[:3])
    print("material:", mat.name, "| hex in", hex_srgb, "| base colour linear", tuple(round(c, 4) for c in base),
          "| back to hex", back, "| viewport colour", tuple(round(c, 4) for c in mat.diffuse_color),
          "| metallic:", socket(bsdf, "Metallic").default_value, "| roughness:", socket(bsdf, "Roughness").default_value,
          "| fake user:", mat.use_fake_user)

print("unit system:", us.system, "| length_unit:", us.length_unit, "| scale_length:", us.scale_length)
print("objects left:", len(scene.objects), "| materials:", [m.name for m in bpy.data.materials])

# --- call 2: Biscuit_Bottom (2.00 x 1.50 x 0.10, Z 0.00 to 0.10) ---
import bpy

name, size, centre, material = "Biscuit_Bottom", (2.00, 1.50, 0.10), (0.0, 0.0, 0.05), "Platform_Biscuit"

bpy.ops.object.select_all(action="DESELECT")
bpy.ops.mesh.primitive_cube_add(size=1.0, location=centre)
obj = bpy.context.active_object
obj.name = name
obj.data.name = name
obj.scale = size
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
obj.data.materials.clear()
obj.data.materials.append(bpy.data.materials[material])

world = [obj.matrix_world @ v.co for v in obj.data.vertices]
r = lambda vals: tuple(round(v, 4) for v in vals)
print(name, "| location", r(obj.location), "| dimensions", r(obj.dimensions), "| scale", r(obj.scale),
      "| x", r((min(p.x for p in world), max(p.x for p in world))),
      "| y", r((min(p.y for p in world), max(p.y for p in world))),
      "| z", r((min(p.z for p in world), max(p.z for p in world))),
      "| tris", sum(len(p.vertices) - 2 for p in obj.data.polygons),
      "| materials", [m.name for m in obj.data.materials])

# --- call 3: Filling (1.90 x 1.40 x 0.05, inset 0.05 m on every side, Z 0.10 to 0.15) ---
import bpy

name, size, centre, material = "Filling", (1.90, 1.40, 0.05), (0.0, 0.0, 0.125), "Platform_Cream"

bpy.ops.object.select_all(action="DESELECT")
bpy.ops.mesh.primitive_cube_add(size=1.0, location=centre)
obj = bpy.context.active_object
obj.name = name
obj.data.name = name
obj.scale = size
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
obj.data.materials.clear()
obj.data.materials.append(bpy.data.materials[material])

world = [obj.matrix_world @ v.co for v in obj.data.vertices]
r = lambda vals: tuple(round(v, 4) for v in vals)
print(name, "| location", r(obj.location), "| dimensions", r(obj.dimensions), "| scale", r(obj.scale),
      "| x", r((min(p.x for p in world), max(p.x for p in world))),
      "| y", r((min(p.y for p in world), max(p.y for p in world))),
      "| z", r((min(p.z for p in world), max(p.z for p in world))),
      "| tris", sum(len(p.vertices) - 2 for p in obj.data.polygons),
      "| materials", [m.name for m in obj.data.materials])

# --- call 4: Biscuit_Top (2.00 x 1.50 x 0.10, Z 0.15 to 0.25, landing surface at Z = 0.25) ---
import bpy

name, size, centre, material = "Biscuit_Top", (2.00, 1.50, 0.10), (0.0, 0.0, 0.20), "Platform_Biscuit"

bpy.ops.object.select_all(action="DESELECT")
bpy.ops.mesh.primitive_cube_add(size=1.0, location=centre)
obj = bpy.context.active_object
obj.name = name
obj.data.name = name
obj.scale = size
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
obj.data.materials.clear()
obj.data.materials.append(bpy.data.materials[material])

world = [obj.matrix_world @ v.co for v in obj.data.vertices]
r = lambda vals: tuple(round(v, 4) for v in vals)
print(name, "| location", r(obj.location), "| dimensions", r(obj.dimensions), "| scale", r(obj.scale),
      "| x", r((min(p.x for p in world), max(p.x for p in world))),
      "| y", r((min(p.y for p in world), max(p.y for p in world))),
      "| z", r((min(p.z for p in world), max(p.z for p in world))),
      "| tris", sum(len(p.vertices) - 2 for p in obj.data.polygons),
      "| materials", [m.name for m in obj.data.materials])

# --- call 5: join Biscuit_Bottom, Filling and Biscuit_Top into Platform, origin at world origin, apply rotation and scale, clean up ---
import bpy

scene = bpy.context.scene
part_names = ["Biscuit_Bottom", "Filling", "Biscuit_Top"]
parts = [bpy.data.objects[n] for n in part_names]

# Join: select all three, make Biscuit_Bottom the active object; the result keeps the active object
bpy.ops.object.select_all(action="DESELECT")
for p in parts:
    p.select_set(True)
bpy.context.view_layer.objects.active = bpy.data.objects["Biscuit_Bottom"]
bpy.ops.object.join()
platform = bpy.context.active_object
platform.name = "Platform"
platform.data.name = "Platform"

# Origin to the world origin (the centre of the underside); geometry does not move
saved_cursor = scene.cursor.location.copy()
scene.cursor.location = (0.0, 0.0, 0.0)
bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
scene.cursor.location = saved_cursor

# Apply rotation and scale
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

# Platform now uses both materials, so the fake users are no longer needed
mat_names = ["Platform_Biscuit", "Platform_Cream"]
for n in mat_names:
    bpy.data.materials[n].use_fake_user = False

# Remove the meshes the join left behind, only where nothing uses them
leftovers = []
for n in ["Filling", "Biscuit_Top"]:
    mesh = bpy.data.meshes.get(n)
    if mesh is not None and mesh.users == 0:
        bpy.data.meshes.remove(mesh)
        leftovers.append(n)

world = [platform.matrix_world @ v.co for v in platform.data.vertices]
r = lambda vals: tuple(round(v, 4) for v in vals)
print("objects:", [o.name for o in scene.objects])
print("Platform | tris", sum(len(p.vertices) - 2 for p in platform.data.polygons),
      "| verts", len(platform.data.vertices), "| faces", len(platform.data.polygons))
print("dimensions", r(platform.dimensions), "| location", r(platform.location),
      "| rotation (deg)", r(tuple(a * 180 / 3.141592653589793 for a in platform.rotation_euler)), "| scale", r(platform.scale))
print("lowest vertex Z", round(min(p.z for p in world), 6), "| highest vertex Z", round(max(p.z for p in world), 6),
      "| X", r((min(p.x for p in world), max(p.x for p in world))),
      "| Y", r((min(p.y for p in world), max(p.y for p in world))))
tris_per_slot = {}
for p in platform.data.polygons:
    slot = platform.material_slots[p.material_index].material.name
    tris_per_slot[slot] = tris_per_slot.get(slot, 0) + len(p.vertices) - 2
print("material slots", [s.material.name for s in platform.material_slots], "| tris per material", tris_per_slot)
print("leftover meshes removed:", leftovers, "| meshes left:", [(m.name, m.users) for m in bpy.data.meshes])
print("cursor restored to", r(scene.cursor.location))
for n in mat_names:
    mat = bpy.data.materials[n]
    print(n, "| fake user", mat.use_fake_user, "| users", mat.users)
