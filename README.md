# Ballerburg Godot Remake

A modernised 2D remake of the artillery classic *Ballerburg*. The project now
uses [Godot Engine 4.2](https://godotengine.org/) with GDScript for fast
iteration, built-in physics, and cross-platform exports (CachyOS/Linux and
Windows).

## Current Prototype
- Central hill terrain built with a `Polygon2D` + collision mesh
- Two placeholder castles with individual health tracking
- Hotseat turn system with adjustable shot angle and velocity
- Wind influence applied as lateral acceleration to projectiles
- Minimal HUD for turn status, wind, inputs, and impact feedback

## Getting Started
1. Install Godot 4.2 (or newer 4.x). On CachyOS/Arch:
   ```bash
   sudo pacman -S --needed godot
   ```
   On Windows download the official editor from godotengine.org.
2. Open the project folder (`/home/sebastian/code/ballerburg`) in Godot.
3. Press <kbd>F5</kbd> to run the prototype. Adjust angle/power in the left
   panel and hit **Feuer** to launch.

## Repository Layout
- `project.godot` – Godot project manifest
- `scenes/` – Main scene graph (`Main.tscn`, `GameWorld.tscn`, `Castle.tscn`, `Projectile.tscn`)
- `scripts/` – GDScript files for gameplay logic
- `assets/` – Placeholder SVG art generated for the prototype
- `docs/design_overview.md` – Architecture notes and roadmap

## Roadmap Highlights
1. **Visual polish** – Improved terrain sprites, destruction states, FX
2. **AI opponent** – Baseline solver with adjustable difficulty
3. **Menus & options** – Mode selection, terrain presets, audio hooks
4. **Extended gameplay** – Layer-specific damage, resource economy, additional terrains

Contributions via issues or pull requests are welcome. If you need a packaged
build, export presets can be added using `godot --headless --export-release`
when we reach the next milestone.
