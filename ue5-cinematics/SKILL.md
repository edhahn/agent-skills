---
name: ue5-cinematics
description: >
  Unreal Engine 5 cinematography and cutscene development using Sequencer. Use when
  tasks involve creating or editing cinematic sequences, camera animation, cutscene
  scripting, Sequencer tracks, camera cuts, post-process animation, dialogue timing,
  movie rendering (MRQ), or virtual cinematography. Covers Sequencer workflow, camera
  rigs, Level Sequences, cinematic Blueprints, and final rendering.
---

# UE5 Cinematography & Cutscene Development

Cinematic sequences, virtual camera work, cutscene scripting, and final rendering in Unreal Engine 5 using Sequencer.

## Infrastructure

UE5 runs on your UE5 workstation. See `ue5-gamedev` skill for full infrastructure and API details.

Sequencer operations can be automated via Remote Control API, Python bridge, and MCP tools for camera placement, property keyframing, and render queue management.

The Remote Control API endpoint defaults to `http://localhost:8080` but is configurable per your UE5 Remote Control plugin settings (Edit > Project Settings > Plugins > Remote Control).

## Sequencer fundamentals

### Level Sequence vs Master Sequence

- **Level Sequence**: Single cinematic clip (one scene, one shot, one take)
- **Master Sequence**: Orchestrates multiple Level Sequences in order (shot list / edit)

### Creating sequences

```python
import unreal

# Create a Level Sequence asset
asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
factory = unreal.LevelSequenceFactoryNew()
sequence = asset_tools.create_asset(
    "LS_Cutscene_01",
    "/Game/Cinematics/Sequences",
    unreal.LevelSequence,
    factory
)

# Open in Sequencer
unreal.LevelSequenceEditorBlueprintLibrary.open_level_sequence(sequence)
```

### Track types

| Track | Purpose | Common uses |
|-------|---------|-------------|
| Actor (Possessable) | Animate existing level actor | Characters, props, lights |
| Actor (Spawnable) | Spawn actor for this sequence only | Temp cameras, FX |
| Camera Cut | Switch active camera | Shot editing |
| Audio | Sound cues and dialogue | Music, VO, SFX |
| Event | Trigger Blueprint events | Gameplay integration |
| Fade | Screen fade in/out | Transitions |
| Subscene | Embed another Level Sequence | Reusable shots |
| Material Parameter | Animate material properties | Dissolves, color shifts |
| Particle | Control Niagara systems | Cinematic VFX |
| Transform | Position/rotation/scale | Any actor movement |
| Property | Keyframe any exposed property | Light intensity, FOV, etc. |

## Camera work

### Camera types

| Camera | When to use |
|--------|-------------|
| CineCameraActor | Primary cinematic camera. Has filmback, lens, focus settings. |
| CameraActor | Basic camera. Fewer cinematic controls. |
| Camera Rig Rail | Camera dolly on a spline path |
| Camera Rig Crane | Crane arm with boom length and rotation |

### CineCameraActor properties

Key properties to keyframe:

```
Filmback:
  SensorWidth: 36.0      -- 35mm full frame (default)
  SensorHeight: 24.0     -- Aspect ratio from sensor dimensions

Current Focal Length: 35.0   -- Lens focal length in mm
  Wide: 16-24mm
  Normal: 35-50mm
  Telephoto: 85-200mm

Current Aperture: 2.8        -- f-stop (depth of field)
  Deep DOF: f/8 - f/16
  Shallow DOF: f/1.4 - f/2.8

Focus Settings:
  FocusMethod: Manual / Tracking
  ManualFocusDistance: 500.0  -- cm
  TrackedActorForFocus: (actor reference)

Current Horizontal FOV: (computed from focal length + sensor)
```

### Common filmback presets

| Format | Sensor Width | Sensor Height | Aspect |
|--------|-------------|---------------|--------|
| 35mm Full Frame | 36.0 | 24.0 | 1.5:1 |
| Super 35 | 24.89 | 18.66 | 1.33:1 |
| IMAX | 70.41 | 52.63 | 1.34:1 |
| Anamorphic 2:1 | 21.95 | 18.6 | ~2.39:1 |
| 16:9 HD | 36.0 | 20.25 | 16:9 |

### Camera placement via Remote Control

```
# Set camera position
PUT http://localhost:8080/remote/object/property
{
  "objectPath": "/Game/Maps/MainLevel.MainLevel:PersistentLevel.CineCameraActor_0",
  "propertyName": "RelativeLocation",
  "propertyValue": { "RelativeLocation": { "X": 500, "Y": -200, "Z": 180 } }
}

# Set focal length
PUT http://localhost:8080/remote/object/property
{
  "objectPath": "/Game/Maps/MainLevel.MainLevel:PersistentLevel.CineCameraActor_0.CineCameraComponent",
  "propertyName": "CurrentFocalLength",
  "propertyValue": { "CurrentFocalLength": 50.0 }
}

# Set aperture
PUT http://localhost:8080/remote/object/property
{
  "objectPath": "/Game/Maps/MainLevel.MainLevel:PersistentLevel.CineCameraActor_0.CineCameraComponent",
  "propertyName": "CurrentAperture",
  "propertyValue": { "CurrentAperture": 2.0 }
}
```

### Camera placement via Python

```python
import unreal

editor = unreal.EditorLevelLibrary()

# Spawn a cine camera
camera = editor.spawn_actor_from_class(
    unreal.CineCameraActor,
    unreal.Vector(500, -200, 180),
    unreal.Rotator(0, 30, 0)
)

# Configure lens
cine_comp = camera.get_cine_camera_component()
cine_comp.set_editor_property("current_focal_length", 50.0)
cine_comp.set_editor_property("current_aperture", 2.0)

# Set focus to track an actor
focus_settings = cine_comp.get_editor_property("focus_settings")
focus_settings.focus_method = unreal.CameraFocusMethod.MANUAL
focus_settings.manual_focus_distance = 300.0
cine_comp.set_editor_property("focus_settings", focus_settings)
```

## Cutscene workflow

### Shot structure

A typical cutscene edit in Sequencer:

```
Master Sequence: MS_Cutscene_01
  |-- LS_Shot_010 (establishing wide)       [0.0s - 3.0s]
  |-- LS_Shot_020 (character close-up)      [3.0s - 5.5s]
  |-- LS_Shot_030 (reaction shot)           [5.5s - 7.0s]
  |-- LS_Shot_040 (two-shot dialogue)       [7.0s - 15.0s]
  |-- LS_Shot_050 (action beat)             [15.0s - 18.0s]
```

### Shot numbering convention

- Number shots by 10s (010, 020, 030...) to leave room for inserts
- Insert shots: 015, 025, etc.
- Takes: append `_v01`, `_v02` for iterations

### Creating a shot list via Python

```python
import unreal

# Create master sequence
asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
factory = unreal.LevelSequenceFactoryNew()
master = asset_tools.create_asset(
    "MS_Cutscene_01",
    "/Game/Cinematics/Sequences",
    unreal.LevelSequence,
    factory
)

# Create individual shots
shot_names = ["LS_Shot_010", "LS_Shot_020", "LS_Shot_030"]
for name in shot_names:
    shot = asset_tools.create_asset(
        name,
        "/Game/Cinematics/Sequences/Cutscene_01",
        unreal.LevelSequence,
        factory
    )
```

## Sequencer keyframing

### Keyframe types

| Interpolation | Use case |
|--------------|----------|
| Auto | Default -- smooth curves between keys |
| User | Manual tangent control |
| Break | Different in/out tangents |
| Linear | Constant-speed interpolation |
| Constant (Step) | Instant value change (no interpolation) |

### Adding tracks and keyframes via Python

```python
import unreal

# Get the sequence
sequence = unreal.load_asset("/Game/Cinematics/Sequences/LS_Shot_010")
movie_scene = sequence.get_movie_scene()

# Bind an actor (possessable)
# This must be done when the level with the actor is loaded
world = unreal.EditorLevelLibrary.get_editor_world()
actor = unreal.GameplayStatics.get_actor_of_class(world, unreal.CineCameraActor)

binding = sequence.add_possessable(actor)

# Add transform track
transform_track = binding.add_track(unreal.MovieScene3DTransformTrack)
transform_section = transform_track.add_section()
transform_section.set_start_frame(0)
transform_section.set_end_frame(150)  # 5 seconds at 30fps
```

## Cinematic lighting

### Lighting for cinematics vs. gameplay

Cinematics often need:
- **Three-point lighting** per shot (key, fill, rim)
- Higher shadow quality (increase shadow resolution via console `r.Shadow.MaxCSMResolution 4096`)
- Rect Lights for soft, area-based illumination
- Light functions for patterns (gobos, window blinds)
- Animated light properties (intensity, color for mood shifts)

### Animatable light properties

Keyframe these in Sequencer:
- `Intensity` -- brightness
- `LightColor` -- color temperature shifts
- `AttenuationRadius` -- falloff distance
- `SourceRadius` / `SourceLength` -- soft shadow spread
- `Temperature` -- Kelvin color temperature (if using temperature mode)
- `VolumetricScatteringIntensity` -- god rays contribution

## Audio and dialogue

### Audio tracks in Sequencer

- **Audio Track**: Place audio assets directly on the timeline
- **Subtitles**: Use Dialogue Wave assets (contain subtitles + localization keys)
- **Sync**: Align audio waveform visually in Sequencer editor (enable waveform display)

### Dialogue workflow

1. Create `DialogueWave` assets for each line
2. Associate `DialogueVoice` (per character)
3. Place DialogueWave on Sequencer Audio Track
4. Keyframe character facial animations to match timing
5. Use Anim Notifies for lip sync markers

## Post-process animation

Keyframe post-processing for cinematic mood:

```
Common animated properties:
  - Color Grading > Global Saturation (desaturate for flashbacks)
  - Color Grading > Shadows/Midtones/Highlights Gain (color shifts)
  - Depth of Field > Aperture (rack focus)
  - Depth of Field > Focal Distance (focus pulls)
  - Bloom > Intensity (dream sequences)
  - Vignette > Intensity (tension, focus)
  - Exposure > Compensation (brightness shifts)
  - Film > Slope/Toe/Shoulder (look development)
```

## Movie Render Queue (MRQ)

MRQ is the production renderer for final output.

### MRQ settings

| Setting | Cinematic | Preview |
|---------|-----------|---------|
| Output Resolution | 3840x2160 (4K) | 1920x1080 |
| Anti-Aliasing | Temporal AA Samples: 64 | 8 |
| Spatial AA Samples | 4-8 | 1 |
| Output Format | EXR (16-bit) or PNG | JPEG |
| Motion Blur | Max quality | Default |
| Frame Rate | 24 (film) or 30 | 30 |

### Render via Python

```python
import unreal

# Get Movie Render Queue subsystem
mrq = unreal.MoviePipelineQueueSubsystem()

# Create a job
queue = mrq.get_queue()
job = queue.allocate_new_job(unreal.MoviePipelineExecutorJob)
job.sequence = unreal.SoftObjectPath("/Game/Cinematics/Sequences/MS_Cutscene_01")
job.map = unreal.SoftObjectPath("/Game/Maps/MainLevel")

# Configure output
config = job.get_configuration()
output_setting = config.find_or_add_setting_by_class(
    unreal.MoviePipelineOutputSetting
)
output_setting.output_directory = unreal.DirectoryPath("{project}/Saved/MovieRenders/")
output_setting.file_name_format = "{sequence_name}/{shot_name}/{frame_number}"
output_setting.output_resolution = unreal.IntPoint(3840, 2160)

# Add image output
png_output = config.find_or_add_setting_by_class(
    unreal.MoviePipelineImageSequenceOutput_PNG
)

# Render
executor = unreal.MoviePipelinePIEExecutor()
mrq.render_queue_with_executor(executor)
```

### Console commands for rendering

```
# High quality rendering overrides
r.ScreenPercentage 200
r.Shadow.MaxCSMResolution 4096
r.Lumen.Reflections.MaxRoughnessToTrace 1.0
r.Lumen.TranslucencyVolume.Enable 1
r.VolumetricFog.GridSizeZ 128
```

## Cinematic Blueprints

### Triggering sequences from gameplay

```cpp
// C++ -- Play a Level Sequence
UPROPERTY(EditAnywhere, Category = "Cinematic")
ULevelSequence* CutsceneSequence;

void AMyTrigger::PlayCutscene()
{
    ALevelSequenceActor* SequenceActor = GetWorld()->SpawnActor<ALevelSequenceActor>();
    SequenceActor->SetSequence(CutsceneSequence);

    ULevelSequencePlayer* Player = SequenceActor->GetSequencePlayer();
    Player->OnFinished.AddDynamic(this, &AMyTrigger::OnCutsceneFinished);
    Player->Play();

    // Disable player input during cutscene
    APlayerController* PC = UGameplayStatics::GetPlayerController(this, 0);
    PC->SetCinematicMode(true, true, true, true, true);
}

void AMyTrigger::OnCutsceneFinished()
{
    APlayerController* PC = UGameplayStatics::GetPlayerController(this, 0);
    PC->SetCinematicMode(false, false, false, true, true);
}
```

### Skip/pause functionality

- `ULevelSequencePlayer::Pause()` / `Play()` for pause
- `ULevelSequencePlayer::GoToEndAndStop()` for skip
- Bind skip to input action (typically a button press after a short hold)

## Cinematography reference

### Shot types

| Shot | Description | Focal length |
|------|-------------|-------------|
| Extreme Wide (EWS) | Full environment, tiny subject | 16-24mm |
| Wide (WS) | Full body in environment | 24-35mm |
| Medium (MS) | Waist up | 35-50mm |
| Medium Close-Up (MCU) | Chest up | 50-85mm |
| Close-Up (CU) | Face fills frame | 85-135mm |
| Extreme Close-Up (ECU) | Eyes or detail | 100-200mm |
| Over-the-Shoulder (OTS) | Dialogue framing | 50-85mm |

### Camera movement types

| Move | Sequencer approach |
|------|-------------------|
| Pan/Tilt | Keyframe camera rotation |
| Dolly | Keyframe camera position (forward/back) |
| Truck | Keyframe camera position (left/right) |
| Crane | Use Camera Rig Crane actor |
| Dolly track | Use Camera Rig Rail + spline |
| Handheld | Add procedural noise to transform curves |
| Orbit | Keyframe position around focal point |

## Asset conventions

```
/Game/Cinematics/
  Sequences/
    MS_{SceneName}/           -- Master sequences
    {SceneName}/
      LS_Shot_{Number}.uasset -- Individual shots
  Cameras/
    BP_CineCam_{Name}.uasset  -- Reusable camera rigs
  Audio/
    DW_{Character}_{Line}.uasset -- Dialogue Waves
    DV_{Character}.uasset        -- Dialogue Voice per character
  Renders/
    {SequenceName}/           -- MRQ output (not committed to source)
```
