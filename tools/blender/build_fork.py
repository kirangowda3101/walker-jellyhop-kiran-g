# --- call 1: empty the scene, metric units in metres, Fork_Silver material ---
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

# One flat silver-grey material (metallic 0, approved)
mat = bpy.data.materials.new("Fork_Silver")
if hasattr(mat, "use_nodes") and not mat.use_nodes:
    mat.use_nodes = True
bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
def socket(node, ident):
    return next(s for s in node.inputs if s.identifier == ident)
socket(bsdf, "Base Color").default_value = (0.6, 0.6, 0.62, 1.0)
socket(bsdf, "Metallic").default_value = 0.0
socket(bsdf, "Roughness").default_value = 0.5
mat.diffuse_color = (0.6, 0.6, 0.62, 1.0)  # viewport colour
mat.metallic = 0.0
mat.roughness = 0.5
mat.use_fake_user = True  # keep it through a save while no object uses it yet

print("unit system:", us.system, "| length_unit:", us.length_unit, "| scale_length:", us.scale_length)
print("material:", mat.name, "| base colour:", tuple(round(v, 3) for v in socket(bsdf, "Base Color").default_value),
      "| metallic:", socket(bsdf, "Metallic").default_value, "| roughness:", socket(bsdf, "Roughness").default_value,
      "| fake user:", mat.use_fake_user)
print("objects left:", len(scene.objects), "| materials:", [m.name for m in bpy.data.materials])

# --- call 2: Prong_1 ---
import bpy

name, size, centre = "Prong_1", (0.05, 0.05, 0.40), (-0.225, 0.0, 0.20)

bpy.ops.object.select_all(action="DESELECT")
bpy.ops.mesh.primitive_cube_add(size=1.0, location=centre)
obj = bpy.context.active_object
obj.name = name
obj.data.name = name
obj.scale = size
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
obj.data.materials.clear()
obj.data.materials.append(bpy.data.materials["Fork_Silver"])

world = [obj.matrix_world @ v.co for v in obj.data.vertices]
r = lambda vals: tuple(round(v, 4) for v in vals)
print(name, "| location", r(obj.location), "| dimensions", r(obj.dimensions), "| scale", r(obj.scale),
      "| x", r((min(p.x for p in world), max(p.x for p in world))),
      "| z", r((min(p.z for p in world), max(p.z for p in world))),
      "| tris", sum(len(p.vertices) - 2 for p in obj.data.polygons),
      "| materials", [m.name for m in obj.data.materials])

# --- call 3: Prong_2 ---
import bpy

name, size, centre = "Prong_2", (0.05, 0.05, 0.40), (-0.075, 0.0, 0.20)

bpy.ops.object.select_all(action="DESELECT")
bpy.ops.mesh.primitive_cube_add(size=1.0, location=centre)
obj = bpy.context.active_object
obj.name = name
obj.data.name = name
obj.scale = size
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
obj.data.materials.clear()
obj.data.materials.append(bpy.data.materials["Fork_Silver"])

world = [obj.matrix_world @ v.co for v in obj.data.vertices]
r = lambda vals: tuple(round(v, 4) for v in vals)
print(name, "| location", r(obj.location), "| dimensions", r(obj.dimensions), "| scale", r(obj.scale),
      "| x", r((min(p.x for p in world), max(p.x for p in world))),
      "| z", r((min(p.z for p in world), max(p.z for p in world))),
      "| tris", sum(len(p.vertices) - 2 for p in obj.data.polygons),
      "| materials", [m.name for m in obj.data.materials])

# --- call 4: Prong_3 ---
import bpy

name, size, centre = "Prong_3", (0.05, 0.05, 0.40), (0.075, 0.0, 0.20)

bpy.ops.object.select_all(action="DESELECT")
bpy.ops.mesh.primitive_cube_add(size=1.0, location=centre)
obj = bpy.context.active_object
obj.name = name
obj.data.name = name
obj.scale = size
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
obj.data.materials.clear()
obj.data.materials.append(bpy.data.materials["Fork_Silver"])

world = [obj.matrix_world @ v.co for v in obj.data.vertices]
r = lambda vals: tuple(round(v, 4) for v in vals)
print(name, "| location", r(obj.location), "| dimensions", r(obj.dimensions), "| scale", r(obj.scale),
      "| x", r((min(p.x for p in world), max(p.x for p in world))),
      "| z", r((min(p.z for p in world), max(p.z for p in world))),
      "| tris", sum(len(p.vertices) - 2 for p in obj.data.polygons),
      "| materials", [m.name for m in obj.data.materials])

# --- call 5: Prong_4 ---
import bpy

name, size, centre = "Prong_4", (0.05, 0.05, 0.40), (0.225, 0.0, 0.20)

bpy.ops.object.select_all(action="DESELECT")
bpy.ops.mesh.primitive_cube_add(size=1.0, location=centre)
obj = bpy.context.active_object
obj.name = name
obj.data.name = name
obj.scale = size
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
obj.data.materials.clear()
obj.data.materials.append(bpy.data.materials["Fork_Silver"])

world = [obj.matrix_world @ v.co for v in obj.data.vertices]
r = lambda vals: tuple(round(v, 4) for v in vals)
print(name, "| location", r(obj.location), "| dimensions", r(obj.dimensions), "| scale", r(obj.scale),
      "| x", r((min(p.x for p in world), max(p.x for p in world))),
      "| z", r((min(p.z for p in world), max(p.z for p in world))),
      "| tris", sum(len(p.vertices) - 2 for p in obj.data.polygons),
      "| materials", [m.name for m in obj.data.materials])

# --- call 6: Head ---
import bpy

name, size, centre = "Head", (0.50, 0.05, 0.15), (0.0, 0.0, 0.475)

bpy.ops.object.select_all(action="DESELECT")
bpy.ops.mesh.primitive_cube_add(size=1.0, location=centre)
obj = bpy.context.active_object
obj.name = name
obj.data.name = name
obj.scale = size
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
obj.data.materials.clear()
obj.data.materials.append(bpy.data.materials["Fork_Silver"])

world = [obj.matrix_world @ v.co for v in obj.data.vertices]
r = lambda vals: tuple(round(v, 4) for v in vals)
print(name, "| location", r(obj.location), "| dimensions", r(obj.dimensions), "| scale", r(obj.scale),
      "| x", r((min(p.x for p in world), max(p.x for p in world))),
      "| z", r((min(p.z for p in world), max(p.z for p in world))),
      "| tris", sum(len(p.vertices) - 2 for p in obj.data.polygons),
      "| materials", [m.name for m in obj.data.materials])

# --- call 7: Handle ---
import bpy

name, size, centre = "Handle", (0.10, 0.05, 0.95), (0.0, 0.0, 1.025)

bpy.ops.object.select_all(action="DESELECT")
bpy.ops.mesh.primitive_cube_add(size=1.0, location=centre)
obj = bpy.context.active_object
obj.name = name
obj.data.name = name
obj.scale = size
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
obj.data.materials.clear()
obj.data.materials.append(bpy.data.materials["Fork_Silver"])

world = [obj.matrix_world @ v.co for v in obj.data.vertices]
r = lambda vals: tuple(round(v, 4) for v in vals)
print(name, "| location", r(obj.location), "| dimensions", r(obj.dimensions), "| scale", r(obj.scale),
      "| x", r((min(p.x for p in world), max(p.x for p in world))),
      "| z", r((min(p.z for p in world), max(p.z for p in world))),
      "| tris", sum(len(p.vertices) - 2 for p in obj.data.polygons),
      "| materials", [m.name for m in obj.data.materials])

# --- call 8: join the six parts into Fork, origin at world origin, apply rotation and scale ---
import bpy

scene = bpy.context.scene
part_names = ["Prong_1", "Prong_2", "Prong_3", "Prong_4", "Head", "Handle"]
parts = [bpy.data.objects[n] for n in part_names]

# Join: select all six, make Head the active object; the result keeps the active object
bpy.ops.object.select_all(action="DESELECT")
for p in parts:
    p.select_set(True)
bpy.context.view_layer.objects.active = bpy.data.objects["Head"]
bpy.ops.object.join()
fork = bpy.context.active_object
fork.name = "Fork"
fork.data.name = "Fork"

# Origin to the world origin (the point between the prong tips); geometry does not move
saved_cursor = scene.cursor.location.copy()
scene.cursor.location = (0.0, 0.0, 0.0)
bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
scene.cursor.location = saved_cursor

# Apply rotation and scale
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

# Fork now uses the material, so the fake user is no longer needed
mat = bpy.data.materials["Fork_Silver"]
mat.use_fake_user = False

world = [fork.matrix_world @ v.co for v in fork.data.vertices]
r = lambda vals: tuple(round(v, 4) for v in vals)
print("objects:", [o.name for o in scene.objects])
print("Fork | tris", sum(len(p.vertices) - 2 for p in fork.data.polygons),
      "| verts", len(fork.data.vertices), "| faces", len(fork.data.polygons))
print("dimensions", r(fork.dimensions), "| location", r(fork.location),
      "| rotation (deg)", r(tuple(a * 180 / 3.141592653589793 for a in fork.rotation_euler)), "| scale", r(fork.scale))
print("lowest vertex Z", round(min(p.z for p in world), 6), "| highest vertex Z", round(max(p.z for p in world), 6),
      "| X", r((min(p.x for p in world), max(p.x for p in world))),
      "| Y", r((min(p.y for p in world), max(p.y for p in world))))
print("material slots", [s.material.name for s in fork.material_slots],
      "| Fork_Silver fake user", mat.use_fake_user, "| users", mat.users)
print("cursor restored to", r(scene.cursor.location))
print("orphan meshes left by the join:", [m.name for m in bpy.data.meshes if m.users == 0])

# --- call 9: remove the five orphan meshes left by the join ---
import bpy

leftover_names = ["Handle", "Prong_1", "Prong_2", "Prong_3", "Prong_4"]
removed = []
for n in leftover_names:
    mesh = bpy.data.meshes.get(n)
    if mesh is not None and mesh.users == 0:
        bpy.data.meshes.remove(mesh)
        removed.append(n)

mat = bpy.data.materials["Fork_Silver"]
print("removed:", removed)
print("meshes left:", [(m.name, m.users) for m in bpy.data.meshes])
print("Fork_Silver users:", mat.users, "| fake user:", mat.use_fake_user)
