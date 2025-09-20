# Ballerburg Godot Remake – Architecture Notes

## Engine
- Godot Engine 4.2 (compatible with 4.x branch), 2D project.
- Scripts in GDScript 2.0 (Python-like syntax) for rapid iteration and clarity.

## Core Scenes
- `Main.tscn`: Root scene handling game state, menus, and turn coordination.
- `GameWorld.tscn`: Contains terrain, castles, projectiles, wind indicator; instanced by `Main`.
- `Castle.tscn`: Multi-layer castle sprite with hitboxes per segment; supports health values per layer and destruction feedback.
- `Projectile.tscn`: PhysicsBody2D (RigidBody2D) with custom gravity + wind force handling.
- `UI/`: Simple Control scenes for main menu, in-game HUD, pause menu, and turn summary.

## Gameplay Systems
- **Turn Manager**: Alternates player controllers; supports Human vs Human, Human vs AI, AI vs AI.
- **Wind System**: Randomized wind strength/direction each round; displayed in HUD; affects projectiles (extra horizontal force).
- **Terrain**: Heightmap-like polygon created from a simple spline; collision via `CollisionPolygon2D`. Supports multiple presets.
- **Damage Model**: Castles consist of stacked sections (e.g. wall, tower, core). Each section has HP and yields visual destruction when depleted.
- **AI**: Initial simple heuristic (angle/velocity estimation with random variance). Roadmap for multiple difficulty levels by adjusting precision and prediction steps.

## Roadmap
1. **Prototype (Milestone M1)**
   - Static terrain preset with central hill.
   - Two castles with shared HP bar (no layered destruction yet).
   - Hotseat controls (keyboard/mouse) and wind indicator.
   - Projectile physics and basic hit detection.
2. **Visual Upgrade (M2)**
   - Replace placeholder art with improved procedurally generated sprites or external assets.
   - Add destruction states per castle layer; screen shake, particle effects.
3. **AI Opponent (M3)**
   - Implement aiming solver using projectile equations & wind compensation.
   - Difficulty tier knobs: prediction accuracy, randomness, information access.
4. **Menus & Quality-of-Life (M4)**
   - Start menu, mode selection, options (wind range, terrain presets).
   - Sound effects & music hooks, key rebinds.
5. **Extended Features (Future)**
   - Multiple terrain types, destructible ground, economy/shop.
   - Online multiplayer (out of scope for initial release).

## Assets Strategy
- Placeholder art generated as simple vector-like shapes via Godot primitives or programmatic textures.
- Art upgrade path: integrate open-licensed assets later or collaborate with artist tools.

## Build & Distribution Notes
- Ensure `project.godot` at repository root to simplify Godot editor usage.
- Use Godot's export presets for Linux (X11) and Windows (Win64); maintain in `export_presets.cfg`.
- Automate builds via `godot --headless --export-release` in future CI.

