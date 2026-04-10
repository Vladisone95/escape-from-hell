# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

"Escape From Hell" is a 2D wave-based combat game built with **Godot 4.6** (Forward Plus renderer, D3D12 on Windows, Jolt Physics). The player fights through 10 waves of increasingly difficult enemies, choosing upgrades between waves.

## Running the Game

Open in Godot 4.6 editor and run, or from CLI:
```
# Path to Godot must be on PATH or use full path
godot --path .
```

## Architecture

**All UI is built procedurally in code** — scene files (`.tscn`) are minimal, containing only a root Control node with a script attached. There are no child nodes in the scene tree; everything is constructed in `_build_ui()` methods at runtime.

### Scene Flow

`MainMenu.tscn` → `Game.tscn` → `WinScreen.tscn` (on victory) or game-over overlay (on defeat, returns to MainMenu)

Scene transitions use `get_tree().change_scene_to_file()`.

### Scripts

- **Game.gd** — Core gameplay: wave system, turn-based combat loop (async with `await`), enemy spawning, upgrade overlay, game-over overlay. Reads wave/player state from GameData autoload.
- **GameData.gd** — AutoLoad singleton for persistent state between scenes. Defines wave compositions (`WAVE_ENEMIES`), enemy base stats (`ENEMY_BASE`), and wave scaling functions.
- **MusicManager.gd** — AutoLoad singleton. Procedural music via `AudioStreamGenerator` with sine-wave synthesis. Defines three tracks (MENU, IDLE, COMBAT) as note sequences.
- **PlayerSprite.gd** — Custom `_draw()`-based knight sprite with idle bob, attack (sword swing), hurt (recoil + red flash), and death (topple + fade) animations.
- **EnemySprite.gd** — Custom `_draw()`-based enemy sprites for three types (DEMON, IMP, HELLHOUND), each with unique appearance and shared attack/hurt/death animations.
- **MainMenu.gd** — Title screen with start/settings/exit buttons. Settings overlay with volume slider.
- **WinScreen.gd** — Victory screen after clearing wave 10.

### Key Patterns

- Combat is async: `_run_combat()` uses `await` on timers and tween `.finished` signals to sequence attack/hit/death animations
- All `await` paths check `is_inside_tree()` to guard against scene changes mid-combat
- Enemies are stored as `Array[Dictionary]` with keys: name, health, max_health, attack, alive, visual, hp_label, atk_label
- Combat log uses BBCode via `RichTextLabel`, capped at 5 lines
