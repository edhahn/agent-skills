---
name: concept-art
description: >
  Game concept art using ComfyUI for iterative visual development. Use when tasks
  involve generating concept art, character design sheets, environment paintings,
  storyboard frames, mood boards, color studies, prop design, or visual exploration
  for game development. Covers organized iteration workflows, prompt engineering for
  FLUX models, output naming conventions, and production-ready concept art pipelines.
  Integrates with the game-designer skill for design-driven visual exploration.
---

# Game Concept Art

Iterative visual development using ComfyUI for concept art, character design, environment painting, storyboards, and visual exploration. This skill covers organized workflows for generating, iterating, and managing concept art across game projects.

## Infrastructure

ComfyUI runs on a GPU workstation accessible over the network (or locally).

| Detail | Value |
|--------|-------|
| Web UI | `${COMFYUI_BASE_URL}` (default: `http://localhost:8188`) |
| API | `${COMFYUI_BASE_URL}/api` |
| Models | FLUX 1 Schnell, FLUX 2 Klein (4B/9B), FLUX 2 Dev |
| Text encoders | CLIP, Mistral, Qwen 3 (4B/8B), T5 XXL |
| Output dir | Configured in ComfyUI settings (default: `./output/`) |

Set the `COMFYUI_BASE_URL` environment variable to point to your ComfyUI instance. Defaults to `http://localhost:8188`.

**VRAM guidelines:** Adjust based on your GPU. A 12GB card can run FLUX 9B at 1024px comfortably; 1536px will push the limit. A 16GB+ card gives more headroom for larger models and resolutions.

## Available models

| Model | Size | Speed | Quality | Best for |
|-------|------|-------|---------|----------|
| flux1-schnell | Fast | Fastest | Good | Rapid exploration, thumbnails |
| flux-2-klein-4b-fp8 | 4B | Fast | Good | Quick iteration, batch concepts |
| flux-2-klein-9b-fp8 | 9B | Medium | High | Refined concepts, hero images |
| flux2_dev_fp8mixed | Full | Slow | Highest | Final concept art, presentations |

**Text encoders by quality tier:**
- Quick iteration: CLIP + T5 XXL
- Standard: CLIP + Qwen 3 4B + T5 XXL
- Maximum: CLIP + Mistral + Qwen 3 8B + T5 XXL

## ComfyUI API usage

### Queue a prompt (generate an image)

```
POST ${COMFYUI_BASE_URL}/prompt
{
  "prompt": { <workflow JSON nodes> },
  "client_id": "agent-concept-art"
}
```

The workflow JSON is a node graph. Key nodes for concept art:

### Minimal text-to-image workflow

```json
{
  "1": {
    "class_type": "CheckpointLoaderSimple",
    "inputs": { "ckpt_name": "flux1-schnell.safetensors" }
  },
  "2": {
    "class_type": "CLIPTextEncode",
    "inputs": { "text": "your prompt here", "clip": ["1", 1] }
  },
  "3": {
    "class_type": "CLIPTextEncode",
    "inputs": { "text": "blurry, low quality, text, watermark", "clip": ["1", 1] }
  },
  "4": {
    "class_type": "EmptyLatentImage",
    "inputs": { "width": 1024, "height": 1024, "batch_size": 1 }
  },
  "5": {
    "class_type": "KSampler",
    "inputs": {
      "model": ["1", 0],
      "positive": ["2", 0],
      "negative": ["3", 0],
      "latent_image": ["4", 0],
      "seed": 42,
      "steps": 20,
      "cfg": 7.0,
      "sampler_name": "euler",
      "scheduler": "normal"
    }
  },
  "6": {
    "class_type": "VAEDecode",
    "inputs": { "samples": ["5", 0], "vae": ["1", 2] }
  },
  "7": {
    "class_type": "SaveImage",
    "inputs": { "images": ["6", 0], "filename_prefix": "concept/char_hero" }
  }
}
```

### Check generation status

```
GET ${COMFYUI_BASE_URL}/history/{prompt_id}
```

### Get generated image

```
GET ${COMFYUI_BASE_URL}/view?filename={filename}&subfolder={subfolder}&type=output
```

### Interrupt current generation

```
POST ${COMFYUI_BASE_URL}/interrupt
```

## Iteration workflow

Concept art is iterative. Follow this structured approach:

### Phase 1: Exploration (wide, fast)

Generate many rough variants to find promising directions.

- **Model**: flux1-schnell or flux-2-klein-4b
- **Steps**: 8-12
- **Resolution**: 512x512 or 768x768
- **Batch size**: 4-8 per prompt
- **Naming**: `{project}/{category}_explore_{concept}_{number}`
- **Goal**: 20-40 thumbnails across varied prompts

Example exploration naming:
```
myproject/char_explore_survivor_00001.png
myproject/char_explore_survivor_00002.png
myproject/env_explore_ruins_00001.png
```

### Phase 2: Refinement (narrow, quality)

Take the best directions and iterate with better parameters.

- **Model**: flux-2-klein-9b or flux2_dev
- **Steps**: 20-30
- **Resolution**: 1024x1024 or 1024x1536
- **Batch size**: 2-4
- **Naming**: `{project}/{category}_refine_{concept}_{number}`
- **Seed locking**: Fix the seed from exploration, vary prompt details

```
myproject/char_refine_survivor_00001.png
myproject/char_refine_survivor_00002.png
```

### Phase 3: Final (hero images)

Polish selected concepts for presentation or handoff.

- **Model**: flux2_dev_fp8mixed
- **Steps**: 30-50
- **Resolution**: 1536x1536 or 1024x2048 (depending on format)
- **Batch size**: 1
- **Naming**: `{project}/{category}_final_{concept}_{number}`

```
myproject/char_final_survivor_00001.png
```

## Output organization

### Folder structure by project

```
output/
  {project}/
    characters/
      char_explore_{name}_{NNNNN}.png
      char_refine_{name}_{NNNNN}.png
      char_final_{name}_{NNNNN}.png
      char_sheet_{name}_{NNNNN}.png      -- Character sheets
      char_turnaround_{name}_{NNNNN}.png -- Turnaround views
    environments/
      env_explore_{name}_{NNNNN}.png
      env_refine_{name}_{NNNNN}.png
      env_final_{name}_{NNNNN}.png
      env_mood_{name}_{NNNNN}.png        -- Mood/lighting studies
    storyboards/
      sb_{scene}_{shot}_{NNNNN}.png      -- Storyboard frames
      sb_{scene}_layout_{NNNNN}.png      -- Scene layouts
    props/
      prop_{name}_{NNNNN}.png
    ui/
      ui_{screen}_{NNNNN}.png
    mood/
      mood_{theme}_{NNNNN}.png           -- Mood boards, color palettes
```

Use the `filename_prefix` parameter in ComfyUI's SaveImage node to route output to the right folder automatically.

## Prompt engineering for concept art

### Structure

```
{subject}, {style}, {composition}, {lighting}, {mood}, {medium}, {details}
```

### Style keywords by art direction

| Direction | Keywords |
|-----------|----------|
| Painterly | oil painting, visible brushstrokes, impressionistic, painterly |
| Clean digital | digital painting, clean lines, polished, concept art, artstation |
| Sketch | pencil sketch, rough, gestural, line art, hatching |
| Realistic | photorealistic, hyperdetailed, 8k, ray tracing |
| Stylized | stylized, cel shaded, low poly, flat color, graphic |
| Dark/gritty | dark fantasy, grimdark, muted palette, weathered, grungy |
| Vibrant | vivid colors, saturated, high contrast, colorful |

### Negative prompt defaults

Always include quality negatives unless seeking a specific rough style:

```
blurry, low quality, jpeg artifacts, text, watermark, signature,
deformed, disfigured, bad anatomy, extra limbs, mutated
```

### Character design prompts

```
# Full body character sheet
"full body character concept art, {character description},
front view and side view, character sheet, white background,
clean design, game character, {style keywords}"

# Portrait / headshot
"portrait of {character description}, bust shot,
detailed face, {expression}, {lighting}, concept art, {style}"

# Action pose
"{character description}, dynamic action pose, {action},
{environment context}, dramatic lighting, concept art"

# Turnaround
"character turnaround sheet, {character description},
front view, three-quarter view, side view, back view,
orthographic, character design, white background"
```

### Environment design prompts

```
# Establishing shot
"wide landscape, {environment description}, {time of day},
{weather}, {mood}, environment concept art, matte painting style"

# Key location
"{location type}, {architectural style}, {materials},
{lighting condition}, {mood}, game environment concept art,
detailed, atmospheric perspective"

# Color/mood study
"color key painting, {scene description}, {dominant colors},
{time of day}, {mood adjectives}, loose brushwork,
environment mood study"

# Cross-section / layout
"cross-section view of {building/structure}, interior layout,
cutaway illustration, architectural diagram, concept art"
```

### Storyboard prompts

```
# Single frame
"storyboard frame, {shot type}: {action description},
{camera angle}, cinematic composition, black and white sketch,
film storyboard style"

# Shot types: extreme wide, wide, medium, close-up, extreme close-up,
#   over-the-shoulder, bird's eye, worm's eye, dutch angle

# Emotional beat
"cinematic frame, {character} {emotion/action},
{lighting mood}, dramatic, film still composition,
concept art, {color palette}"
```

### Prop and item design

```
# Weapon/tool
"{item type} design sheet, {description}, multiple angles,
orthographic views, detailed, game prop concept art,
white background, {material} surface"

# Inventory item
"game item icon, {item description}, isometric view,
stylized, clean rendering, game UI icon style"
```

## Sampler and parameter guide

| Use case | Sampler | Steps | CFG | Scheduler |
|----------|---------|-------|-----|-----------|
| Fast exploration | euler | 8-12 | 5-7 | normal |
| Standard quality | euler_ancestral | 20 | 7 | normal |
| High detail | dpmpp_2m_sde | 25-30 | 7-8 | karras |
| Maximum quality | dpmpp_2m_sde | 40-50 | 7 | karras |
| Consistent iteration | euler | 20 | 7 | normal |

### Seed management

- **Exploration**: Random seeds (let ComfyUI auto-generate)
- **Refinement**: Lock the seed from a good exploration result, adjust prompt
- **Variations**: Increment seed by 1 from a good result for similar-but-different outputs
- **Record seeds**: Always note the seed of outputs you like -- it's your "undo" for regeneration

## Aspect ratios

| Format | Resolution | Use case |
|--------|-----------|----------|
| Square | 1024x1024 | Character portraits, icons, mood boards |
| Portrait | 832x1216 | Full-body characters, vertical environments |
| Landscape | 1216x832 | Environment establishing shots, panoramas |
| Wide | 1536x640 | Storyboard frames, cinematic compositions |
| Tall | 640x1536 | Vertical scenes, tower/cliff environments |
| Sheet | 1536x1024 | Character sheets, turnarounds, multi-view |

Keep dimensions divisible by 8. FLUX models work well at 1024-1536px range.

## Batch iteration patterns

### A/B prompt comparison

Generate the same seed with two different prompts to compare specific changes:

1. Prompt A: "medieval knight, steel armor, battle-worn"
2. Prompt B: "medieval knight, leather armor, battle-worn"
3. Same seed, same parameters -- only the prompt differs

### Style exploration

Same subject, different style keywords:

1. "hero character, oil painting, classical"
2. "hero character, cel shaded, anime inspired"
3. "hero character, pencil sketch, rough concept"
4. "hero character, digital painting, artstation trending"

### Lighting studies

Same scene, different lighting:

1. "forest ruins, golden hour, warm light"
2. "forest ruins, moonlight, cool blue tones"
3. "forest ruins, overcast, diffused light, muted"
4. "forest ruins, dramatic storm, volumetric lightning"

## Working with the game design team

### Concept brief format

When receiving a design brief (from the game-designer skill or director):

1. **Extract visual keywords**: Characters, props, locations, mood, references
2. **Define scope**: How many concepts? Which categories? What fidelity?
3. **Exploration round**: Generate 20-40 thumbnails across directions
4. **Present options**: Organize by direction, annotate with brief notes
5. **Refine selected**: Iterate on approved directions at higher quality
6. **Deliver finals**: Export hero images for handoff to 3D or further development

### Handoff to other skills

- **To character pipeline**: Final character concepts as reference for modeling/rigging
- **To level design**: Environment concepts as reference for world building
- **To cinematics**: Storyboard frames as shot planning reference
- **To team documentation**: Upload approved concepts to shared project docs for team access

### Requesting feedback

When presenting concepts to the director/operator:

1. Show exploration thumbnails grouped by direction
2. Call out your recommended top 3 with brief rationale
3. Ask specific questions: "Should the armor be heavier?" not "What do you think?"
4. Iterate based on feedback -- don't regenerate from scratch unless directed

## Managing large batches

For projects generating many images (100+ iterations):

- Use consistent `filename_prefix` for project/category grouping
- Track promising seeds and prompts in a text file or project notes
- Periodically clean exploration outputs -- keep only selected refinement/final images
- Use ComfyUI's built-in image comparison to review batches side-by-side

## Troubleshooting

- **Out of VRAM**: Switch to flux-2-klein-4b or reduce resolution. Check your GPU's VRAM capacity and adjust model/resolution accordingly.
- **Slow generation**: Use TAESD preview (VAE approximation) for fast previews during exploration. Full VAE for finals only.
- **Inconsistent style**: Lock the model, sampler, and CFG. Only vary prompt and seed.
- **ComfyUI unreachable**: Check that ComfyUI is running. `curl ${COMFYUI_BASE_URL}/system_stats` for health check.
