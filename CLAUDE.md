# CLAUDE.md

## Rules

1. **Zero output on file writes** — after Read, Edit, or Write, confirm with ONE sentence max. Never echo contents.
2. **Terse** — no summaries, recaps, bullet lists of changes, or preambles ("Sure!", "Let me..."). 1-2 sentences.
3. **No re-reads** — Edit/Write confirm success. Trust it.
4. **Batch tool calls** — parallelize independent reads/edits. No redundant Glob/Grep.
5. **No speculative exploration** — only read files relevant to the current task.
6. **Use explicit GDScript types** — `: Type =` not `:=` to avoid inference errors.
7. **Use assigned skills** — always use the godot skill for GDScript/testing, pixel-art skills (creator, animator, professional, exporter) for sprite work via Aseprite MCP. Never bypass skills with raw implementations.
8. **No unnecessary additions** — no extra comments, docstrings, type annotations on unchanged code, feature flags, or speculative abstractions.

## Project

"Escape From Hell" — 2D top-down arena combat, Godot 4.6 (Forward Plus, D3D12, Jolt Physics). 10 waves of enemies, upgrades between waves.

## Run

```bash
godot --path .
```

## Test

```bash
godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests
```

Tests in `test/arena/` using GdUnit4 (`extends GdUnitTestSuite`).

## Scene Flow

`MainMenu.tscn` → `Arena.tscn` → `WinScreen.tscn` (victory) / game-over overlay (defeat → MainMenu)

## AutoLoads

- `GameData` — persistent state (player stats, wave, inventory)
- `MusicManager` — procedural sine-wave music
- `EnemyStats` — enemy base stats, wave compositions, per-wave overrides

## Sprite System

All character/object sprites use `AnimatedSprite2D` + `SpriteFrames` from `.tres` files. Spritesheets generated via Python/Pillow in `tools/`.

| Base Class | Script | Loads |
|---|---|---|
| SpriteBase.gd | PlayerArenaSprite.gd | player.tres |
| SpriteBase.gd | EnemyArenaSprite.gd | {demon,imp,hellhound,warlock,abomination}.tres (by `etype`) |
| standalone | VanityBossSprite.gd | procedural (520 lines, 20 arms, continuous tweens) |

**SpriteBase API** (used by PlayerBody.gd / EnemyBody.gd via `Node2D.new()` + `set_script()`):
`start_idle()`, `start_walk()`, `_stop_walk()`, `_is_walking`, `set_facing_from_vec(dir)`, `play_attack()`, `play_hurt()`, `play_die()`, `play_cast()`

**Animation naming**: `{action}_{direction}` — idle_down, walk_right, attack_up. LEFT = RIGHT frames + `flip_h = true`.

**Hurt flash**: `self_modulate` tween (SpriteBase) or `_tc()` lerp (VanityBoss).

## Asset Pipeline

```
tools/generate_*.py → assets/sprites/**/*.png + .json
tools/generate_spriteframes.py → assets/spriteframes/*.tres
```

| Generator | Output |
|---|---|
| generate_player_sprite.py | player spritesheet (36 frames) |
| generate_enemy_sprites.py | 5 enemy spritesheets |
| generate_object_sprites.py | obstacle, projectile, chest |
| generate_item_icons.py | 4 item icons (64x64) |
| generate_upgrade_icons.py | 8 upgrade icons (64x64) |
| generate_tiles.py | floor + wall tiles (32x32) |
| generate_spriteframes.py | JSON → .tres conversion |

## Key Scripts

| Script | Role |
|---|---|
| arena/ArenaGame.gd | Core: waves, spawning, overlays, game-over |
| arena/PlayerBody.gd | CharacterBody2D: movement, attack, dash, hurtbox |
| arena/EnemyBody.gd | CharacterBody2D: AI chase/attack, hurtbox |
| arena/ArenaFloor.gd | Tiled floor/wall textures + procedural crack/glow overlays |
| arena/Projectile.gd | Area2D + AnimatedSprite2D, color via `self_modulate` |
| arena/ChestPickup.gd | AnimatedSprite2D chest + procedural "Press E" text |
| arena/ObstacleVisual.gd | Static Sprite2D from PNG |
| ItemThumbnail.gd | Item icons from PNG textures |
| UpgradeThumbnail.gd | Upgrade icons from PNG textures |

**Stays procedural** (no sprite benefit): HealthBar, DamageNumber, ExpandingRing, attack/telegraph arcs, portal vortex, "Press E" prompts.

## Physics Layers

1=world, 2=player_body, 3=enemy_body, 4=player_attack, 5=enemy_attack, 6=interactable

## Conventions

- All UI built procedurally — `.tscn` files have only root node + script, children added in `_build_ui()`
- All `await` paths check `is_inside_tree()` for scene-change safety
- Combat log uses BBCode via `RichTextLabel`
- Enemy `etype` set BEFORE `add_child(sprite)` so `_ready()` loads correct SpriteFrames
