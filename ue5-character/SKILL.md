---
name: ue5-character
description: >
  Unreal Engine 5 character design, modeling, rigging, and animation. Use when tasks
  involve creating or modifying character meshes, setting up Skeletal Meshes, building
  animation Blueprints (AnimBP), configuring IK/FK rigs, retargeting animations,
  importing characters from DCC tools, working with Control Rig, or managing animation
  assets. Covers the full pipeline from mesh import through gameplay-ready animated character.
---

# UE5 Character Design, Modeling, Rigging & Animation

Full pipeline from mesh creation through gameplay-ready animated characters in Unreal Engine 5.

## Infrastructure

<!-- Configure your UE5 workstation and network paths based on your studio's setup. -->
<!-- Asset source files and processed exports should be organized on your file server or version control. -->

## Character pipeline overview

```
DCC (Blender/Maya)          UE5 Editor
+------------------+        +---------------------------+
| Model + Rig      |  FBX   | Skeletal Mesh             |
| Animations       | -----> | Skeleton                  |
| Morph targets    |        | Physics Asset             |
+------------------+        | Animation Blueprint       |
                            | Control Rig               |
                            | IK Rig / IK Retargeter    |
                            +---------------------------+
```

## Skeletal Mesh import

### FBX import settings

When importing character FBX files:

| Setting | Value | Notes |
|---------|-------|-------|
| Skeleton | Select existing or create new | Reuse skeleton for animation sharing |
| Import Mesh | Yes | |
| Import Animations | Yes (or separate) | Can split mesh and anim imports |
| Import Morph Targets | Yes | For facial animation |
| Normal Import Method | Import Normals and Tangents | Preserve DCC normals |
| Material Import | Create new or assign existing | |
| Convert Scene Unit | Yes | Ensures correct scale |

### Via automation API

```
# Configure your asset bridge/automation server URL and export paths
# based on your studio's infrastructure.

POST http://<YOUR_BRIDGE_HOST>:<PORT>/ue5/import
{
  "source_path": "<YOUR_EXPORT_PATH>/characters/hero.fbx",
  "destination_path": "/Game/Characters/Hero",
  "asset_name": "SK_Hero"
}
```

### Via Python

```python
import unreal

# Import FBX with specific settings
task = unreal.AssetImportTask()
# Set filename to your source FBX path (local, network share, or mapped drive)
task.set_editor_property("filename", "/path/to/exports/characters/hero.fbx")
task.set_editor_property("destination_path", "/Game/Characters/Hero")
task.set_editor_property("destination_name", "SK_Hero")
task.set_editor_property("replace_existing", True)
task.set_editor_property("automated", True)
task.set_editor_property("save", True)

# FBX-specific options
options = unreal.FbxImportUI()
options.set_editor_property("import_mesh", True)
options.set_editor_property("import_animations", False)
options.set_editor_property("import_as_skeletal", True)
options.set_editor_property("skeleton", None)  # Create new, or pass existing
options.skeletal_mesh_import_data.set_editor_property("import_morph_targets", True)
options.skeletal_mesh_import_data.set_editor_property("normal_import_method",
    unreal.FBXNormalImportMethod.FBXNIM_IMPORT_NORMALS_AND_TANGENTS)
task.set_editor_property("options", options)

unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks([task])
```

## Skeleton setup

### UE5 standard skeleton hierarchy

Epic's Mannequin skeleton (UE5 default):

```
root
  pelvis
    spine_01
      spine_02
        spine_03
          spine_04
            spine_05
              neck_01
                neck_02
                  head
              clavicle_l
                upperarm_l
                  lowerarm_l
                    hand_l
                      (finger chains)
              clavicle_r
                (mirror of left)
    thigh_l
      calf_l
        foot_l
          ball_l
    thigh_r
      (mirror of left)
```

### Skeleton compatibility

- Characters sharing animations must use the same Skeleton asset or be retargeted
- Use **IK Retargeter** for cross-skeleton animation sharing (UE5 preferred)
- Aim for bone naming consistency across characters in the same project

## Rigging

### Physics Asset

Every Skeletal Mesh needs a Physics Asset for ragdoll, hit detection, and cloth:

1. Right-click Skeletal Mesh > Create > Physics Asset
2. Add capsule/sphere bodies to major bones (pelvis, spine, limbs, head)
3. Configure constraints between bodies (angular limits, stiffness)
4. Test with `Simulate` in Physics Asset editor

### Control Rig (UE5 native rigging)

Control Rig replaces traditional FK/IK setups with a node-based visual rig:

- **Forward Solve**: Drives bones from controls (animation playback)
- **Backward Solve**: Used for authoring (interactive posing)
- **Construction Event**: Initial rig setup (create controls, set hierarchy)

Key nodes:
- `Set Transform` / `Set Translation` / `Set Rotation` -- drive bone transforms
- `Two Bone IK` -- standard IK chain (arm, leg)
- `Full Body IK` -- whole-body IK (FBIK) for natural multi-chain solving
- `Aim` -- orient bone toward target
- `Spring Interpolate` -- springy secondary motion

### IK Rig

Define IK goals and chains for retargeting:

```python
import unreal

# Create IK Rig asset via Python
# IK Rigs are typically created in-editor via right-click > Animation > IK Rig
# Then configured manually with:
# - Set Preview Mesh
# - Add IK Goals (ik_foot_l, ik_foot_r, ik_hand_l, ik_hand_r)
# - Define Chains (Spine, LeftArm, RightArm, LeftLeg, RightLeg, Head)
# - Set Root bone
```

### IK Retargeter

Map animations between different skeletons:

1. Create IK Rig for source skeleton (e.g., UE5 Mannequin)
2. Create IK Rig for target skeleton (your custom character)
3. Create IK Retargeter: source IK Rig -> target IK Rig
4. Auto-map chains by name, manually adjust mismatches
5. Preview and adjust chain mapping / pose offsets

## Animation Blueprint (AnimBP)

The AnimBP is the character's animation state machine.

### Core components

```
AnimBP
  EventGraph          -- Game logic (velocity, direction, state flags)
  AnimGraph           -- Animation evaluation
    StateMachine      -- State-based animation flow
      Idle            -- Standing still
      Walk/Run        -- Locomotion blend space
      Jump            -- Jump montage / blend
      Fall            -- Falling loop
    Slots             -- Montage playback layers
    Layered Blend     -- Upper/lower body compositing
    IK / Post-Process -- Foot IK, look-at, etc.
```

### State machine setup

```
[Idle] ---(Speed > 10)---> [Locomotion]
[Locomotion] ---(Speed < 10)---> [Idle]
[Any State] ---(bIsJumping)---> [Jump]
[Jump] ---(bIsFalling)---> [Fall]
[Fall] ---(bIsOnGround)---> [Land]
[Land] ---(Finished)---> [Idle]
```

### Blend Spaces

- **1D Blend Space**: Single axis (e.g., speed: idle -> walk -> run)
- **2D Blend Space**: Two axes (e.g., speed + direction for omnidirectional locomotion)
- Horizontal axis: Direction (-180 to 180)
- Vertical axis: Speed (0 to max)
- Place animation samples at grid points

### Via Python -- create and configure AnimBP

```python
import unreal

# Create Animation Blueprint
factory = unreal.AnimBlueprintFactory()
factory.set_editor_property("target_skeleton",
    unreal.load_asset("/Game/Characters/Hero/SK_Hero_Skeleton"))

asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
anim_bp = asset_tools.create_asset(
    "ABP_Hero", "/Game/Characters/Hero", None, factory
)
```

## Animation import

### Animation-only FBX import

```python
import unreal

task = unreal.AssetImportTask()
# Set filename to your source animation FBX path
task.set_editor_property("filename", "/path/to/exports/animations/hero_run.fbx")
task.set_editor_property("destination_path", "/Game/Characters/Hero/Animations")
task.set_editor_property("destination_name", "AM_Hero_Run")
task.set_editor_property("automated", True)
task.set_editor_property("save", True)

options = unreal.FbxImportUI()
options.set_editor_property("import_mesh", False)
options.set_editor_property("import_animations", True)
options.set_editor_property("skeleton",
    unreal.load_asset("/Game/Characters/Hero/SK_Hero_Skeleton"))
options.anim_sequence_import_data.set_editor_property("import_bone_tracks", True)
options.anim_sequence_import_data.set_editor_property("import_custom_attribute", True)
task.set_editor_property("options", options)

unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks([task])
```

### Animation Montages

Montages layer on top of state machine animations (attacks, emotes, interactions):

- Create Montage from Animation Sequence (right-click > Create Montage)
- Define Sections (startup, loop, recovery)
- Add Notify events (hit frame, sound, VFX trigger)
- Play via `UAnimInstance::Montage_Play()` in C++ or AnimBP

### Notify events

| Notify type | Purpose |
|------------|---------|
| AnimNotify | Fire-and-forget event (sound, particle) |
| AnimNotifyState | Duration-based (trail effect, weapon collision window) |
| Custom AnimNotify class | Complex logic (damage application, state changes) |

## Morph targets / Blend Shapes

Used for facial animation and corrective shapes:

- Import morph targets with the FBX (enable "Import Morph Targets")
- Drive via Curve assets in animations
- Control at runtime: `SkeletalMeshComponent->SetMorphTarget("Smile", 1.0)`
- Use **MetaHuman** or **Live Link Face** for facial capture workflows

## Cloth simulation

1. Open Skeletal Mesh in editor
2. Section Selection > select cloth geometry
3. Create Cloth Asset from Section
4. Paint cloth weights (fixed vs. simulated vertices)
5. Configure: wind, gravity, stiffness, damping, collision

## Character Blueprint setup

A gameplay-ready character needs:

```
BP_Character (inherits ACharacter)
  CapsuleComponent (root, collision)
  SkeletalMeshComponent (visual mesh + AnimBP)
  SpringArmComponent (camera boom)
  CameraComponent (follow camera)
  CharacterMovementComponent (built-in locomotion)
```

Key CharacterMovement settings:
- `MaxWalkSpeed`: 600 (default)
- `JumpZVelocity`: 420 (default)
- `AirControl`: 0.2 (default, 0-1)
- `GravityScale`: 1.0
- `bOrientRotationToMovement`: true (character faces movement direction)

## Asset conventions

```
/Game/Characters/{CharacterName}/
  SK_{Name}.uasset              -- Skeletal Mesh
  SK_{Name}_Skeleton.uasset     -- Skeleton
  SK_{Name}_PhysicsAsset.uasset -- Physics Asset
  ABP_{Name}.uasset             -- Animation Blueprint
  CR_{Name}.uasset              -- Control Rig
  IK_{Name}.uasset              -- IK Rig
  Animations/
    AM_{Name}_{Action}.uasset   -- Animation Montages
    AS_{Name}_{Action}.uasset   -- Animation Sequences
    BS_{Name}_{Type}.uasset     -- Blend Spaces
  Materials/
    MI_{Name}_Body.uasset       -- Material Instances
    MI_{Name}_Hair.uasset
  Textures/
    T_{Name}_BaseColor.uasset
    T_{Name}_Normal.uasset
    T_{Name}_ORM.uasset         -- Occlusion/Roughness/Metallic
```
