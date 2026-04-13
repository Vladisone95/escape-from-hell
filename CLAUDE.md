# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

"Escape From Hell" is a 2D real-time arena combat game built with **Godot 4.6** (Forward Plus renderer, D3D12 on Windows, Jolt Physics). The player fights through 10 waves of increasingly difficult enemies in top-down action combat, choosing upgrades between waves.

## Running the Game

Open in Godot 4.6 editor and run, or from CLI:
```
# Path to Godot must be on PATH or use full path
godot --path .
```

## Architecture

**All UI is built procedurally in code** — scene files (`.tscn`) are minimal, containing only a root Control node with a script attached. There are no child nodes in the scene tree; everything is constructed in `_build_ui()` methods at runtime.

### Scene Flow

`MainMenu.tscn` → `Arena.tscn` → `WinScreen.tscn` (on victory) or game-over overlay (on defeat, returns to MainMenu)

Scene transitions use `get_tree().change_scene_to_file()`.

### Scripts

- **arena/ArenaGame.gd** — Core gameplay: wave system, real-time arena combat, enemy spawning, upgrade/chest overlays, game-over overlay. Reads wave/player state from GameData autoload.
- **arena/PlayerBody.gd** — Player physics body (CharacterBody2D) with movement, attack hitbox, dash, and hurtbox.
- **arena/PlayerArenaSprite.gd** — Custom `_draw()`-based player sprite with directional facing and walk cycle animations.
- **arena/EnemyBody.gd** — Enemy physics body with AI movement, attack, and hurtbox.
- **arena/EnemyArenaSprite.gd** — Custom `_draw()`-based enemy sprites for four types (DEMON, IMP, HELLHOUND, WARLOCK) with directional facing and walk cycle.
- **arena/ArenaHUD.gd** — In-game HUD showing health, wave info, and combat log.
- **arena/ArenaFloor.gd** — Procedural arena floor rendering.
- **arena/AttackHitbox.gd / Hurtbox.gd / HealthBar.gd / DamageNumber.gd** — Combat system components.
- **arena/Projectile.gd** — Generic projectile (Area2D). Stats (speed, max_distance, radius, colors) passed via config dict. Any enemy can use it by defining a `projectile` block in EnemyStats.BASE.
- **arena/ObstacleVisual.gd** — Arena obstacle rendering.
- **EnemyStats.gd** — AutoLoad singleton. Single source of truth for enemy base stats (`BASE`), wave compositions (`WAVES`), and per-wave stat overrides (`WAVE_OVERRIDES`). All values are human-readable dictionaries keyed by type name.
- **GameData.gd** — AutoLoad singleton for persistent state between scenes (player stats, wave counter, inventory).
- **MusicManager.gd** — AutoLoad singleton. Procedural music via `AudioStreamGenerator` with sine-wave synthesis. Defines three tracks (MENU, IDLE, COMBAT) as note sequences.
- **Inventory.gd** — Player inventory data model.
- **ItemThumbnail.gd** — Procedural item icon rendering.
- **ChestOverlay.gd** — Chest loot selection UI overlay.
- **InventoryOverlay.gd** — Player inventory display overlay.
- **MainMenu.gd** — Title screen with start/settings/exit buttons. Settings overlay with volume slider.
- **WinScreen.gd** — Victory screen after clearing wave 10.

### Key Patterns

- Combat is real-time with physics-based collision (CharacterBody2D, Area2D hitboxes/hurtboxes)
- Physics layers: world (1), player_body (2), enemy_body (3), player_attack (4), enemy_attack (5)
- Enemy AI uses simple chase/attack state machines
- All `await` paths check `is_inside_tree()` to guard against scene changes mid-combat
- Combat log uses BBCode via `RichTextLabel`

## Token Optimization Rules

These rules are critical — follow them to minimize token consumption:

1. **Never echo file contents** — after reading, editing, or writing a file, do NOT print its contents back. Confirm with a single sentence only.
2. **Terse responses** — no summaries, no trailing recaps, no bullet-point lists of what was changed. One or two sentences max.
3. **Do not re-read files you just edited** — the Edit tool confirms success; trust it.
4. **Minimize tool calls** — batch independent reads/edits in parallel. Avoid redundant Glob/Grep when you already know the path.
5. **No speculative exploration** — only read files directly relevant to the current task. Don't browse "just in case."
6. **Skip boilerplate responses** — no "Sure!", "Great question!", "Let me...", "Here's what I did:" preambles.
