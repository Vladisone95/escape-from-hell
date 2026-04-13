#!/usr/bin/env python3
"""Generate Godot SpriteFrames .tres from spritesheet JSON metadata."""
import json, sys

def generate_tres(json_path, png_res_path, output_path):
    with open(json_path) as f:
        data = json.load(f)

    frames_data = data["frames"]
    animations = data["animations"]

    # Collect all atlas textures needed
    atlas_entries = []  # (frame_name, x, y, w, h)
    for name, info in frames_data.items():
        f = info["frame"]
        atlas_entries.append((name, f["x"], f["y"], f["w"], f["h"]))

    # Sort by name for consistent ordering
    atlas_entries.sort(key=lambda e: e[0])

    # Assign IDs
    name_to_id = {}
    for i, (name, *_) in enumerate(atlas_entries):
        name_to_id[name] = f"AtlasTexture_{i+1}"

    load_steps = len(atlas_entries) + 2  # ext_resource + sub_resources + resource

    lines = []
    lines.append(f'[gd_resource type="SpriteFrames" load_steps={load_steps} format=3]')
    lines.append('')
    lines.append(f'[ext_resource type="Texture2D" path="{png_res_path}" id="sheet"]')
    lines.append('')

    # Sub resources (AtlasTextures)
    for name, x, y, w, h in atlas_entries:
        sid = name_to_id[name]
        lines.append(f'[sub_resource type="AtlasTexture" id="{sid}"]')
        lines.append(f'atlas = ExtResource("sheet")')
        lines.append(f'region = Rect2({x}, {y}, {w}, {h})')
        lines.append('')

    # Build animation array
    lines.append('[resource]')

    anim_parts = []
    for anim_name, anim_data in sorted(animations.items()):
        frame_names = anim_data["frames"]
        loop_type = anim_data.get("loop", "forward")
        is_loop = loop_type in ("forward", "pingpong")

        # Calculate FPS from frame durations
        durations = [frames_data[fn]["duration"] for fn in frame_names]
        avg_dur = sum(durations) / len(durations)
        fps = 1000.0 / avg_dur if avg_dur > 0 else 5.0

        frame_entries = []
        for fn in frame_names:
            sid = name_to_id[fn]
            dur = frames_data[fn]["duration"]
            # Duration multiplier relative to average
            dur_mult = dur / avg_dur if avg_dur > 0 else 1.0
            frame_entries.append(f'{{"duration": {dur_mult:.2f}, "texture": SubResource("{sid}")}}')

        frames_str = ", ".join(frame_entries)
        loop_str = "true" if is_loop else "false"
        anim_parts.append(
            f'{{"frames": [{frames_str}], "loop": {loop_str}, "name": &"{anim_name}", "speed": {fps:.1f}}}'
        )

    lines.append(f'animations = [{", ".join(anim_parts)}]')

    with open(output_path, 'w') as f:
        f.write('\n'.join(lines) + '\n')

    print(f"Generated {output_path} with {len(animations)} animations, {len(atlas_entries)} atlas textures")


if __name__ == "__main__":
    if len(sys.argv) >= 4:
        generate_tres(sys.argv[1], sys.argv[2], sys.argv[3])
    else:
        # Default: player
        generate_tres(
            "assets/sprites/player/player.json",
            "res://assets/sprites/player/player.png",
            "assets/spriteframes/player.tres"
        )
