---
name: product-illustrator
description: >
  Product illustration and rendering for ecommerce, instruction manuals, and marketing.
  Use when tasks involve creating product images from CAD files (CadQuery, OpenSCAD),
  generating marketing renders or lifestyle mockups, illustrating assembly instructions
  or user guides, creating Etsy/ecommerce listing images, rendering 3D-printed product
  photography, or producing visual assets for product pages. Combines CAD rendering with
  ComfyUI image generation for polished output. Works with STL files, .scad files, and
  CadQuery Python scripts.
---

# Product Illustrator

Generate product images from CAD source files for marketing, ecommerce listings, instruction manuals, and packaging. Bridges parametric CAD (CadQuery, OpenSCAD) with AI image generation (ComfyUI) for production-quality visual assets.

## Operating context

This skill serves product teams producing visual assets for ecommerce storefronts, marketing sites, and instruction manuals. It is designed for workflows where products originate as parametric CAD models (3D-printed goods, manufactured parts, consumer products) and need polished imagery for customer-facing channels.

Typical roles that interact with this pipeline:

| Role | Responsibility |
|------|---------------|
| Product Lead | Product strategy, ecommerce, CAD modeling |
| Manufacturing / Print Operator | Print execution, slicer config, quality |
| Creative Director | Final approval on visual assets |

### Infrastructure

Configure the following environment variables to connect to your rendering services:

| Variable | Default | Purpose |
|----------|---------|---------|
| `COMFYUI_HOST` | `localhost` | Hostname of the ComfyUI server |
| `COMFYUI_PORT` | `8188` | Port for the ComfyUI API |
| `OUTPUT_DIR` | `./output` | Base directory for generated images |
| `CAD_LIB_PATH` | *(none)* | Additional library path for CadQuery (e.g., `$HOME/.local/lib`) |

**ComfyUI endpoint**: `http://${COMFYUI_HOST}:${COMFYUI_PORT}`

If CadQuery requires additional shared libraries, set `LD_LIBRARY_PATH` before running:
```bash
export LD_LIBRARY_PATH="${CAD_LIB_PATH}:$LD_LIBRARY_PATH"
```

### CAD tools

| Tool | Status | Use |
|------|--------|-----|
| CadQuery (Python) | Primary, installed | Parametric modeling, direct STL export, headless rendering |
| SolidPython2 | Available | Python wrapper for OpenSCAD syntax, generates .scad files |
| OpenSCAD | Binary not installed | Can read .scad files via SolidPython2, but use CadQuery for STL export |
| Shapr3D | Available (local) | Manual CAD modeling |

## Pipeline overview

```
CAD Source                  Rendering                    Enhancement
+----------------+         +------------------+         +------------------+
| CadQuery (.py) |  STL    | CadQuery render  |  PNG    | ComfyUI          |
| OpenSCAD (.scad)| -----> | or               | -----> | (style transfer,  |
| STL files      |         | Blender headless |         |  background,      |
+----------------+         +------------------+         |  enhancement)     |
                                                        +------------------+
                                                               |
                                                        +------+-------+
                                                        |              |
                                                   Marketing      Instruction
                                                   renders        manual images
```

## Reading CAD files

### CadQuery Python files (.py)

CadQuery scripts are parametric -- they define geometry through code. To understand a product:

1. Read the `.py` file to extract parameters (dimensions, tolerances, materials)
2. Identify the key components (frames, inserts, connectors, etc.)
3. Note the export calls (`cq.exporters.export()`) to find what STLs are generated

```python
import cadquery as cq

# Read and render a CadQuery model
result = cq.Workplane("XY").box(100, 50, 10)

# Export STL for printing
cq.exporters.export(result, "output/part.stl")

# Export SVG for 2D illustration (orthographic views)
cq.exporters.export(result, "output/part_front.svg",
    opt={"projectionDir": (0, 0, 1)})  # Top view
cq.exporters.export(result, "output/part_side.svg",
    opt={"projectionDir": (1, 0, 0)})  # Side view
cq.exporters.export(result, "output/part_iso.svg",
    opt={"projectionDir": (1, 1, 1)})  # Isometric view
```

### OpenSCAD files (.scad)

If given a `.scad` file, read it to understand the geometry. Key syntax:

```scad
// Primitives
cube([width, depth, height]);
sphere(r=radius);
cylinder(h=height, r=radius);

// Transforms
translate([x, y, z]) { ... }
rotate([rx, ry, rz]) { ... }
scale([sx, sy, sz]) { ... }

// Boolean operations
union() { ... }        // Combine shapes
difference() { ... }   // Subtract second from first
intersection() { ... } // Keep only overlap

// Parametric
module part_name(param1, param2) { ... }
```

Since OpenSCAD binary isn't installed, convert to CadQuery for rendering, or describe the geometry for ComfyUI prompt generation.

### STL files

STL files are mesh data -- they can't be read as source code. For STL-only products:
- Note the filename convention to understand what the part is
- Use CadQuery's STL import: `cq.importers.importStep("part.stl")`
- Or render with a headless tool and pass to ComfyUI

## Rendering with CadQuery

### Orthographic views (for instruction manuals)

```python
import cadquery as cq

model = cq.importers.importStep("product.step")
# or build from CadQuery script

# Front view
cq.exporters.export(model, "front.svg",
    opt={"projectionDir": (0, -1, 0), "width": 800, "height": 600})

# Top view
cq.exporters.export(model, "top.svg",
    opt={"projectionDir": (0, 0, 1), "width": 800, "height": 600})

# Isometric (exploded or assembled)
cq.exporters.export(model, "iso.svg",
    opt={"projectionDir": (1, -1, 1), "width": 800, "height": 600})
```

### Exploded views (for assembly instructions)

```python
import cadquery as cq

# Render each part offset along the assembly axis
frame = build_frame()
insert = build_insert().translate((0, 0, 30))   # Offset upward
connector = build_connector().translate((0, 0, 60))

# Export each part as a separate SVG layer, or combine
assembly = cq.Assembly()
assembly.add(frame, name="frame")
assembly.add(insert, name="insert", loc=cq.Location((0, 0, 30)))
assembly.add(connector, name="connector", loc=cq.Location((0, 0, 60)))
```

## ComfyUI enhancement

After generating base renders from CAD, use ComfyUI to produce polished marketing images.

**ComfyUI endpoint**: `http://${COMFYUI_HOST}:${COMFYUI_PORT}`

See the `concept-art` skill for full ComfyUI API details. The key differences for product illustration:

### Marketing renders

Transform CAD renders into photorealistic product shots:

```
Prompt structure:
"professional product photography, {product description},
{material/finish}, studio lighting, white background,
soft shadows, high-key lighting, commercial photography,
8k, sharp focus, {angle}"
```

Example prompts by product type:

**3D-printed decorative product**:
```
"professional product photography, geometric decorative wall panel,
intricate lattice pattern, matte PLA finish, warm studio lighting,
clean white background, soft shadows, lifestyle interior setting,
modern minimalist decor, commercial product shot"
```

**Product on white background** (for Etsy/ecommerce):
```
"product photography on pure white background, {product},
even studio lighting, no shadows, isolated product,
ecommerce listing style, clean, sharp, professional"
```

**Lifestyle context** (for marketing sites):
```
"interior design photography, {product} mounted on modern wall,
living room setting, natural window light, scandinavian style,
lifestyle product photography, editorial quality"
```

### Instruction manual illustrations

For clean technical illustrations:

```
"technical illustration, {assembly step description},
clean line art, instruction manual style, numbered callouts,
white background, clear and simple, isometric view,
assembly diagram, no shading"
```

Or enhance CAD SVG exports:

```
"clean technical diagram, product assembly illustration,
exploded view, {parts description}, minimal style,
numbered parts, clear arrows showing assembly direction,
instruction booklet quality"
```

## Image types and specifications

### Etsy / Ecommerce listings

| Image | Resolution | Format | Requirements |
|-------|-----------|--------|-------------|
| Main listing | 2000x2000 | PNG/JPG | White or lifestyle background, product fills 80% of frame |
| Detail shot | 2000x2000 | PNG/JPG | Close-up of texture, pattern, finish |
| Scale reference | 2000x2000 | PNG/JPG | Product with common object for size context |
| Lifestyle | 2000x2000 | PNG/JPG | Product in real setting (room, desk, wall) |
| Process/materials | 2000x2000 | PNG/JPG | Filament, printer, unboxing |

Etsy allows up to 10 images per listing. Recommended set:
1. Hero shot (product on white)
2. Lifestyle context (product in room)
3. Detail/texture close-up
4. Scale reference
5. Color variants (if applicable)
6. Assembly/usage illustration
7. Packaging/unboxing

### Instruction manual images

| Image | Resolution | Format | Style |
|-------|-----------|--------|-------|
| Assembly step | 1200x900 | SVG or PNG | Line art, numbered callouts, isometric |
| Parts list | 1200x900 | SVG or PNG | All parts laid out, labeled |
| Completed product | 1200x900 | PNG | Clean render, all angles |
| Warning/note | 600x400 | SVG or PNG | Icon-based, clear symbols |

### Marketing site renders

| Image | Resolution | Format | Style |
|-------|-----------|--------|-------|
| Hero banner | 2560x1440 | PNG/WebP | Dramatic lighting, lifestyle setting |
| Product grid | 800x800 | PNG/WebP | Consistent white background, uniform framing |
| Feature callout | 1200x800 | PNG/WebP | Close-up with annotation overlay |
| Comparison | 1600x900 | PNG/WebP | Before/after or variant comparison |

## Workflow by deliverable

### Ecommerce listing images

1. **Read the CAD source** to understand the product geometry and variants
2. **Generate orthographic renders** from CadQuery for accurate product views
3. **Enhance with ComfyUI** for white-background studio shots
4. **Generate lifestyle images** with ComfyUI for context shots
5. **Create detail crops** focusing on textures, patterns, material finish
6. **Confirm with operator** before using for listings

### Assembly instructions

1. **Read the CAD source** and identify all parts and assembly sequence
2. **Generate exploded views** showing parts separated along assembly axis
3. **Render each assembly step** with relevant parts highlighted
4. **Add callout annotations** (part numbers, arrow directions)
5. **Export as SVG or clean PNG** for print and digital manual use
6. **Number steps sequentially** with clear "before" and "after" states

### Marketing site renders

1. **Read the CAD source** to understand the product
2. **Generate hero renders** from the best angles
3. **Use ComfyUI** to create photorealistic renders with dramatic lighting
4. **Create lifestyle contexts** (product in real-world settings)
5. **Generate multiple colorways/variants** if applicable
6. **Output at web-optimized sizes** (WebP for web, PNG for print)

## Naming conventions

```
output/
  {project}/
    product/
      ecommerce/
        listing_{product}_{variant}_{number}.png    -- Etsy/shop images
        lifestyle_{product}_{setting}_{number}.png  -- Context shots
      manual/
        step_{NN}_{description}.svg                 -- Assembly steps
        parts_list.svg                              -- Parts overview
        exploded_{view}.svg                         -- Exploded diagrams
      marketing/
        hero_{product}_{angle}_{number}.png         -- Hero banners
        grid_{product}_{variant}.png                -- Product grid tiles
        feature_{product}_{detail}.png              -- Feature callouts
      renders/
        ortho_{product}_{view}.svg                  -- Orthographic views from CAD
        iso_{product}.svg                           -- Isometric views from CAD
```

Use `filename_prefix` in ComfyUI's SaveImage node to route output automatically.

## Sampler settings for product images

| Use case | Model | Steps | CFG | Resolution | Notes |
|----------|-------|-------|-----|-----------|-------|
| White background product | flux-2-klein-9b | 25 | 7 | 1024x1024 | Clean, even lighting |
| Lifestyle context | flux2_dev | 30 | 7 | 1216x832 | More detail for environments |
| Technical illustration | flux-2-klein-4b | 15 | 8 | 1024x1024 | Higher CFG for precision |
| Quick variant exploration | flux1-schnell | 10 | 5 | 768x768 | Fast batch generation |

## Related skills

| Skill | Hand off when |
|-------|--------------|
| concept-art | Exploring visual direction before committing to product renders |
| ue5-gamedev | Product needs real-time 3D visualization (beyond static renders) |
| corporate-vp | Product launch decisions needing executive analysis |
