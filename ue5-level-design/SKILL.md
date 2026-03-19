---
name: ue5-level-design
description: >
  Unreal Engine 5 level design: world building, landscape, lighting, environment art,
  gameplay spaces, and level streaming. Use when tasks involve creating or modifying
  levels, placing actors, configuring lighting, building landscapes, setting up level
  streaming, or designing gameplay spaces. Covers both manual editor workflows and
  automated placement via Remote Control API, Python bridge, and MCP tools.
---

# UE5 Level Design

World building, environment art, lighting, landscape, gameplay spaces, and level streaming in Unreal Engine 5.

## Infrastructure

See the `ue5-gamedev` skill for full infrastructure details.

| Channel | Endpoint | Use for level design |
|---------|----------|---------------------|
| Remote Control API | localhost:8080 | Actor placement, property tweaking, lighting adjustments |
| Python bridge | localhost:30010 | Batch operations, procedural placement, asset management |
| MCP (ChiR24/Unreal_mcp) | Local plugin | Actor creation, level management, lighting control |

## Level structure

### Level organization

```
/Game/Maps/
  MainLevel.umap              -- Persistent level
  MainLevel_Gameplay.umap     -- Gameplay actors (streaming)
  MainLevel_Lighting.umap     -- Lights and post-process (streaming)
  MainLevel_Audio.umap        -- Ambient audio (streaming)
  MainLevel_Foliage.umap      -- Foliage and vegetation (streaming)
```

### World Partition (UE5 preferred)

For open worlds, use World Partition instead of manual level streaming:

- **Data Layers**: Organize actors into logical layers (Gameplay, Environment, Audio)
- **Runtime Grid**: Controls streaming granularity (cell size, loading range)
- **One File Per Actor (OFPA)**: Each actor is its own file -- enables parallel work
- **HLODs**: Hierarchical LODs for distant rendering
- **Minimap**: World Partition generates a grid-based minimap for the editor

### Sub-levels (classic approach)

For linear or contained levels:
- Use Level Streaming Volumes for automatic loading
- Use `ULevelStreamingDynamic` for code-driven streaming
- Keep persistent level minimal (only always-loaded actors)

## Actor placement

### Via Remote Control API

```
# Spawn an actor at a location
PUT http://localhost:8080/remote/object/call
{
  "objectPath": "/Script/Engine.Default__GameplayStatics",
  "functionName": "BeginDeferredActorSpawnFromClass",
  "parameters": {
    "WorldContextObject": "/Game/Maps/MainLevel.MainLevel",
    "ActorClass": "/Game/Blueprints/BP_Torch.BP_Torch_C",
    "SpawnTransform": {
      "Translation": { "X": 1000, "Y": 500, "Z": 0 },
      "Rotation": { "X": 0, "Y": 0, "Z": 45, "W": 1 },
      "Scale3D": { "X": 1, "Y": 1, "Z": 1 }
    }
  }
}
```

### Via Python bridge

```python
import unreal

editor = unreal.EditorLevelLibrary()

# Spawn from Blueprint class
bp_class = unreal.EditorAssetLibrary.load_blueprint_class("/Game/Blueprints/BP_Torch")
location = unreal.Vector(1000, 500, 0)
rotation = unreal.Rotator(0, 45, 0)
actor = editor.spawn_actor_from_class(bp_class, location, rotation)

# Batch place actors along a path
import math
for i in range(20):
    angle = (i / 20) * 2 * math.pi
    x = math.cos(angle) * 2000
    y = math.sin(angle) * 2000
    loc = unreal.Vector(x, y, 0)
    editor.spawn_actor_from_class(bp_class, loc, unreal.Rotator(0, 0, 0))
```

### Via MCP (ChiR24/Unreal_mcp)

The MCP server provides higher-level actor management:
- Create actors by type (cube, sphere, light, camera, custom Blueprint)
- Set transforms (position, rotation, scale)
- Query and find actors by name or class
- Delete actors
- Manage actor hierarchies

## Landscape

### Landscape setup

- **Component size**: 63x63 or 127x127 quads (63 for smaller levels, 127 for large)
- **Sections per component**: 1x1 (small) or 2x2 (large worlds)
- **Scale**: Default 100x100x256 (X/Y/Z). For realistic terrain, Z scale of 51200 = ~500m height range
- **Material**: Use landscape-specific material with layer blending

### Landscape layers

```python
import unreal

# Create landscape material layers via Python
landscape = unreal.EditorLevelLibrary.get_all_level_actors_of_class(unreal.Landscape)[0]

# Sculpt operations use the Landscape Editor mode
# For automation, modify heightmap data directly:
# Export: Right-click landscape > Export to file (.r16 or .png)
# Import: Landscape > Import heightmap
```

### Foliage

- Use **Procedural Foliage Volume** for large-area automatic placement
- Use **Foliage Painting** for manual detail placement
- Use **Nanite** for high-poly foliage (UE5.1+): enable Nanite on foliage static meshes
- **Grass types**: Use Landscape Grass Type for lightweight ground cover (rendered per-component)

## Lighting

### Light types and when to use them

| Light | Use case | Cost |
|-------|----------|------|
| Directional Light | Sun/moon, outdoor scenes | Low (one per level) |
| Sky Light | Ambient fill, sky color | Low (one per level) |
| Point Light | Lamps, torches, small areas | Medium |
| Spot Light | Flashlights, focused beams | Medium |
| Rect Light | Windows, screens, area sources | High |

### Lumen (UE5 default GI)

- **Lumen Global Illumination**: Real-time indirect lighting. No lightmap baking needed.
- **Lumen Reflections**: Real-time reflections replacing SSR + planar reflections.
- **Hardware Ray Tracing**: Enable for higher quality (requires RTX GPU).
- **Software Ray Tracing**: Fallback that works without RTX. Lower quality but no hardware requirement.

### Lighting via Remote Control

```
# Adjust directional light intensity
PUT http://localhost:8080/remote/object/property
{
  "objectPath": "/Game/Maps/MainLevel.MainLevel:PersistentLevel.DirectionalLight_0.LightComponent0",
  "propertyName": "Intensity",
  "propertyValue": { "Intensity": 8.0 }
}

# Change light color
PUT http://localhost:8080/remote/object/property
{
  "objectPath": "/Game/Maps/MainLevel.MainLevel:PersistentLevel.PointLight_0.LightComponent0",
  "propertyName": "LightColor",
  "propertyValue": { "LightColor": { "R": 255, "G": 180, "B": 100, "A": 255 } }
}
```

### Lighting via Python

```python
import unreal

editor = unreal.EditorLevelLibrary()

# Spawn a point light
light = editor.spawn_actor_from_class(
    unreal.PointLight,
    unreal.Vector(500, 0, 300),
    unreal.Rotator(0, 0, 0)
)
light_comp = light.get_component_by_class(unreal.PointLightComponent)
light_comp.set_intensity(5000)
light_comp.set_light_color(unreal.LinearColor(1.0, 0.7, 0.4, 1.0))
light_comp.set_attenuation_radius(1000)
```

## Post-processing

### Post Process Volume settings

Key properties to control via Remote Control or Python:

- **Exposure**: Min/Max EV100, metering mode, exposure compensation
- **Bloom**: Intensity, threshold, size
- **Color grading**: Temperature, tint, saturation, contrast, gamma, gain (per shadows/midtones/highlights)
- **Ambient occlusion**: Intensity, radius, bias
- **Depth of field**: Focal distance, aperture (f-stop), near/far transition
- **Motion blur**: Amount, max velocity
- **Tone mapping**: Film slope, toe, shoulder

### Environment

- **Sky Atmosphere**: Realistic atmospheric scattering. One per level.
- **Volumetric Clouds**: GPU-driven cloud rendering. Configure coverage, density, shape.
- **Exponential Height Fog**: Distance fog with directional inscattering.
- **Ultra Dynamic Sky** (marketplace): Popular all-in-one sky/weather solution.

## Performance guidelines

- **Draw calls**: Keep under 2000 for 60fps. Use instanced static meshes for repeated geometry.
- **Nanite**: Enable for complex static meshes. Automatic LOD with virtualized geometry.
- **Virtual Shadow Maps**: UE5 default. Handles large worlds well but costs VRAM.
- **Occlusion**: Use precomputed visibility volumes in indoor areas.
- **LODs**: Auto-generate via mesh editor for non-Nanite meshes.
- **Texture streaming**: Use virtual textures for large landscapes.
- **Profiling**: Use `stat unit`, `stat gpu`, `stat scenerendering` console commands. ProfileGPU (`Ctrl+Shift+,`) for per-pass timings.

## Collision and navigation

- **Collision**: Use simple collision (boxes, spheres, capsules) over complex collision where possible
- **NavMesh**: Place a NavMeshBoundsVolume to enable AI pathfinding. Configure agent radius/height.
- **Navigation modifiers**: Use NavModifierVolume to mark areas (avoid, prefer, custom)
- **RecastNavMesh**: Default navmesh system. Configure cell size, agent parameters.

## File and asset conventions

```
/Game/
  Maps/              -- Level files
  Blueprints/        -- Blueprint actors
  Environment/
    Meshes/          -- Static meshes
    Materials/       -- Material instances
    Textures/        -- Texture assets
  Lighting/
    LightProfiles/   -- IES profiles
    HDRIs/           -- Sky/environment maps
  FX/                -- Niagara particle systems
  Audio/
    Ambient/         -- Environmental audio
    SFX/             -- Sound effects
```

## Workflow

1. **Block out**: Place BSP brushes or simple meshes to define spaces
2. **Gameplay test**: Verify scale, sightlines, flow with placeholder actors
3. **Art pass**: Replace blockout with final meshes and materials
4. **Lighting pass**: Set up lights, sky, post-processing
5. **Polish**: Foliage, decals, particles, audio
6. **Optimize**: Profile, add LODs, configure streaming, set culling distances
