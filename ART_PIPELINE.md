# Art Pipeline

Everything in the game except the two animated customer GLBs and a handful of
environment props is procedural (primitives plus shared cached materials), so
the download stays small. Both active NPCs are rigged Mixamo-style animated
characters (`customer_1.glb` and `customer_2.glb`) with `idle`, `walk`, and `eat` clips.

## 1. Customers: FBX -> GLB

```
cd new-game-project
blender --background --python tools/blender/convert_customers.py -- "E:\3d models\fbx models" "new-game-project/assets/models/customers"
```

What it does per character (`tools/blender/convert_customers.py`):

- imports the FBX and applies the object transform (the FBX ships with a
  -90 deg X rotation, so local axes are not Z-up until applied)
- rebuilds the material with the embedded atlas image (the FBX's own image
  link is broken), downsized to 512
- bends the T-pose arms down around the shoulders
- decimates to ~6500 triangles
- scales to 1.68 m, centers, puts the feet on the origin, and faces Godot's
  -Z (the source faces -Y)
- exports a compressed GLB

Output: `customer_1.glb` .. `customer_7.glb`. The source names stay only in
the build tool; `CustomerManager` assigns names `Customer 1..N` and hands out
the GLBs in rotation (`Customer.MODEL_COUNT`).

### Animated customers

`customer_8.glb` and `customer_9.glb` keep their rig and ship three clips,
`idle`, `walk` and `eat`. Build them from a Breathing Idle + Walking + eat
FBX trio (same rigged character):

```
blender --background --python tools/blender/convert_animated_npc.py -- idle.fbx walking.fbx eat.fbx customer_8.glb
```

`Customer` finds the `AnimationPlayer`, plays `idle`, switches to `walk` when
moving, plays `eat` when the order is served, and returns to `walk` when leaving.
The source names are never used in-game.

To review a conversion, render a preview of one:

```
blender --background --python tools/blender/preview_glb.py -- "new-game-project/assets/models/customers/customer_1.glb" "build/previews/customer_1.png"
```

## 2. Environment: Kenney 3D (CC0) + Sketchfab (manual, no in-game downloads)

Real models we ship curations for (all CC0, verified on kenney.nl, safe for
publish):

| pack | link | files | notes |
|---|---|---|---|
| Nature Kit | https://kenney.nl/assets/nature-kit | 330 | trees, rocks, foliage |
| Survival Kit | https://kenney.nl/assets/survival-kit | 80 | nature, surv. items |
| Furniture Kit | https://kenney.nl/assets/furniture-kit | 140 | interior furniture |
| Food Kit | https://kenney.nl/assets/food-kit | 200 | food, pots and table props |

### 2a. Drop-in placement (semi-realistic world)

**18 curated CC0 props are already shipped and enabled** in
`assets/environment/props/` and placed by `assets/environment/placements.json`:
two palms, a shrub, a clay pot, a rock, a fence, a barrel, a crate, firewood,
a signpost, a bench, a bin, a terrace plant, a round table, a stool, a cooking
pot, tomatoes and lemons. At startup the log prints
`EnvironmentLoader: loaded 18 imported prop(s)`. The two texture atlases ship
as `props/Textures/colormap.png` (Food Kit) and `props/Textures/s.png`
(Survival Kit) - Survival GLBs were repathed to `Textures/s.png` so both atlases
can coexist.

To add more:

1. Download a Kenney pack (they are under **License: Creative Commons CC0**,
   so attribution is optional but appreciated - see `assets/manifest.json`).
2. Unzip and move the `.glb` files you want into `new-game-project/assets/environment/props/`.
3. Open the GLB in the Godot editor (auto-import), adjust import if you like.
4. Add a line to `assets/environment/placements.json` with `"enabled": true`.
5. Re-export the web build.

### 2b. Sketchfab (manual, no in-game downloads)

The PRD requires that we do not download Sketchfab models ourselves. So we ship
a documented, manual import workflow:

1. Find a model: https://sketchfab.com/search?q=indian+restaurant+terrace+table+static+furniture (add your own queries; recommended anchors are listed below).
2. Open the model page, review the license (prefer CC0 / CC-BY; respect whatever the author chose), then click **Download** and pick **GLB** (or GLTF zip). If it is not a static model, request a static variant.
3. Unzip into `new-game-project/assets/environment/props/` (rename to something short and local, e.g. `tera_table.glb`).
4. Open the GLB in the Godot editor - it auto-imports. Adjust: import **Exclude** advanced options if you want fewer normals, keep triangles below ~1.5k for props, set shadows to caster-only.
5. Add one line per model to `assets/environment/placements.json` (see 2a).
6. Re-export the web build. If you use another preset, add `assets/environment/props/*` to the export filters.
7. Attribution: add an entry to `assets/manifest.json` with `source`, `url`,
   `author`, and the license text (or `CC0`). See `assets/manifest.json` for the
   schema.

Anchors (world positions) `EnvironmentLoader.anchor_position()` resolves:

| anchor | approx. position |
|---|---|
| entrance | (-8.0, 0.14, 10.2) - front of the stall, facing the queue |
| terrace_left | (-6.2, 0.13, 11.2) - behind the stall |
| terrace_right | (6.2, 0.13, 11.2) |
| counter_left | (-3.4, 0.0, 9.4) |
| counter_right | (3.5, 0.0, 9.3) |
| balcony | (0.0, 3.2, 11.6) |
| street_far | (-20.0, 0.1, 0.5) - near the market street |
| road_far | (-14.0, 0.1, -6.0) - on the far road |

`EnvironmentLoader` runs at world build, prints `EnvironmentLoader: loaded N
imported prop(s)`, and pushes a warning if a referenced file is missing. Set
`enabled: false` to stage a model without placing it.

## 3. Mixamo (optional, manual)

Mixamo needs an Adobe account, so it is not scripted. Workflow:

1. Download the animation/FBX from Mixamo (Everest default), unzip.
2. In Blender: File -> Import -> FBX, then export GLB.
3. Retarget if you need it (this game's customers are static, so animations
   are optional). Keep ~2k triangles and pack the texture at 512.

## 4. Performance budgets (target: low-end mobile, WebGL2/Compatibility)

- Customers: ~6.5k tris each (7 files, ~2.3 MB total with JPEGs).
- Environment props: keep each under ~1.5k tris and share a common texture.
- Street/world stays procedural: ~10-20 materials shared by reference.
- Use the Compatibility renderer (`gl_compatibility`), see `project.godot`.

## 5. Customer voice lines (Hindi / Hinglish)

18 short lines are generated with the Eleven Labs API and shipped as OGG files
in `assets/audio/dialogues/`. `Audio.play_dialogue()` plays them positionally
from the customer and emits a Devanagari + English subtitle rendered with
`NotoSansDevanagari-Regular.ttf` (SIL OFL 1.1).

To regenerate them, set `ELEVENLABS_API_KEY` in your environment and run:

```
powershell -File tools/tts/generate_dialogues.ps1
```

The key is read from the environment only - never commit it. The OFL licence for
the subtitle font is in `assets/fonts/OFL.txt`; attribution for both is in
`assets/manifest.json`.

## 6. Export presets

`export_presets.cfg` has `Web`, `Windows` and `Android` presets.

```
# regenerate, then build:
godot --headless --path new-game-project --import
godot --path new-game-project --resolution 1280x720 -- --smoke
godot --path new-game-project --resolution 1280x720 -- --shots
```

Screenshot tour names: `01_menu` .. `04_customer`, `05_plate`, `06_inventory`,
`07_upgrades`, `09_restaurant`, `10_palace`, `08_report` (written to
`new-game-project/build/screenshots`).
