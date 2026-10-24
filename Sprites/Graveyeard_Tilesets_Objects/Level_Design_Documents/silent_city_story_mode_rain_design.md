# Silent City - Story Mode Rain and Storm Design

## Status and scope

This is a planning document only. Do not change game files, scenes, scripts, shaders, particles, collisions, characters, enemies, story logic, online mode, multiplayer systems, or shared resources until the design is approved.

The rain idea applies to **Medium** and **Hard** story-mode difficulty. Easy remains dry or uses only occasional atmospheric droplets unless separately approved. Rain must strengthen the dark atmosphere without hiding platforms, hazards, enemies, checkpoints, exits, or story events.

## Core idea

- **Medium - Steady Rain:** readable rainfall, light wind, wet-looking surfaces, soft distant thunder, and occasional controlled lightning. The rain adds tension but does not change movement, traction, jumping, attacks, enemy accuracy, or damage.
- **Hard - Violent Storm:** denser rain, stronger wind gusts, darker clouds, louder thunder, more dramatic but safely timed lightning, and stronger visual reactions around major encounters. The storm increases emotional pressure, while actual difficulty still comes from approved enemies, hazards, and encounter design.
- Rain is never allowed to create blind jumps, hide attack telegraphs, cover UI, or cause unavoidable damage.
- Puddles, wet stone, splashes, mist, drips, and reflections are visual by default. They are not slippery or damaging unless a later gameplay design explicitly approves that behavior.

## Visual layers

1. **Background layer:** slow diagonal rain, moving clouds, distant lightning, and atmospheric haze behind gameplay.
2. **Gameplay layer:** restrained rain streaks and small ground splashes that never cover the player silhouette or enemy telegraphs.
3. **Foreground layer:** sparse larger droplets near the camera, reduced around combat and precision jumps.
4. **Surface response:** subtle wet tint and lantern reflections using only project-approved materials and effects.
5. **Interior response:** roof drips, window rain, leaks, and distant thunder instead of full-screen indoor rainfall.

## Difficulty profiles

### Medium

- Rain density target: approximately 35-50 percent of the approved maximum.
- Wind remains gentle and mostly visual.
- Lightning is infrequent, never pure white, and cannot coincide with a critical jump or dangerous enemy telegraph.
- Ambient sound stays below combat, dialogue, checkpoint, and warning sounds.
- Foreground droplets fade during boss attacks and tight platforming.

### Hard

- Rain density target: approximately 70-85 percent of the approved maximum, not a completely opaque curtain.
- Stronger gusts and angled rain communicate the storm, but do not push the character unless separately approved.
- Lightning can support encounter rhythm and boss phases, but every flash has an accessibility-safe intensity and cooldown.
- Thunder may become louder near the Wizard's Sanctum, while essential sounds remain clear.
- The player, enemies, hazards, platform edges, checkpoints, and exits retain strong silhouettes and contrast.

## Scene plan

### Outer Graveyard

- Medium begins dry or with a very light drizzle, then becomes steady after the first major story trigger or checkpoint.
- Hard begins with visible rain and grows heavier near the crypt and exit to the Forgotten Path.
- Lanterns, gravestones, fences, wet ground, and short splashes create the mood without changing collision.

### Forgotten Path

- Outdoor ruins and broken ceilings receive visible rain shafts.
- Underground areas use dripping water, runoff, distant thunder, and small pools instead of impossible full-screen rain.
- Medium uses quieter drips and limited mist. Hard uses stronger leaks, short gusts through openings, and darker storm light.
- The Minotaur approach can use a temporary reduction in rain sound so footsteps, roars, and warning cues are clear.

### Wizard's Sanctum

- Full rain appears only through broken roofs, windows, balconies, or exposed courtyards.
- The storm remains visible outside and may react to magical corruption.
- Lightning can silhouette the Sanctum and support the Wizard's entrance, teleportation, barriers, and phase changes.
- During the final boss, reduce foreground rain around the combat space so projectiles, portals, hazards, and the Wizard remain readable.
- After victory, the storm weakens, rain becomes lighter, clouds open, and the return of light supports the ending.

## Scene and transition rules

- Use zone-based rain intensity with smooth fades rather than instantly switching effects.
- A suggested transition lasts 1.5-3 seconds for visual density and 2-4 seconds for ambience.
- Attach weather to the active camera or use bounded story-mode weather zones so the effect does not end at screen edges.
- Pause or reduce rain during dialogue, important story reveals, checkpoint activation, and visually complex attacks when needed.
- Reset weather correctly after death, checkpoint reload, pause, scene transition, and return to menu.

## Readability, performance, and accessibility

- Keep the player and enemy silhouettes brighter or more separated from the background than the rain.
- Never draw dense foreground rain over UI, subtitles, dialogue, boss health, or interaction prompts.
- Provide weather-quality scaling: Low reduces particles and splashes; Medium preserves the intended look; High adds density and secondary effects.
- Provide a reduced-lightning option and avoid rapid repeated flashes.
- Separate rain, thunder, and wind volume from critical gameplay cues.
- Test at the lowest supported resolution and performance target.
- If a weather effect is shared with online mode, duplicate or isolate a story-mode copy before any future implementation. Do not change online behavior.

## Available Rain shader analysis

The newly supplied weather asset contains:

- Shader: `../Rain/rain_and_snow_shader.gdshader`
- License: `../Rain/Rain and Snow Shader MIT Licence.rtf`
- Author: Brian Smith (`steampunkdemon.itch.io`), copyright 2023.
- License: MIT. Keep the copyright and permission notice with copies or substantial portions of the shader.

### What the shader does

- It is a procedural Godot `canvas_item` shader. It draws repeating near and far falling streaks across the UV area of the CanvasItem receiving the material.
- `rain_amount` controls approximate streak density; near/far length, width, transparency, speed, color, and slant are exposed as uniforms.
- Randomized near/far values create depth without needing a rain texture or particle sprite.
- The shader uses Godot's built-in `TIME`, so the effect continues automatically. Its own comments describe an optional custom time uniform if later implementation needs explicit pause control.
- It only draws rain or snow streaks. It does **not** provide splashes, puddles, wet-ground reflections, mist, thunder, lightning, wind physics, collision, or gameplay effects.

### Important current-state finding

The smooth **blurred-trail rain line is currently commented out**, while the sharp **no-trail snow line is active**. Used exactly as supplied, the visual will look more like sharp snow or short falling marks than soft rain trails. For the rain presentation, a future approved implementation should activate the blurred-trail expression and deactivate the no-trail expression. Do not edit the shader during planning.

### Starting values for later testing

These values are tuning starting points, not final approved settings:

| Uniform | Medium steady rain | Hard storm |
| --- | --- | --- |
| `rain_amount` | 140-180 | 220-300 |
| `near_rain_length` | 0.18-0.24 | 0.24-0.34 |
| `far_rain_length` | 0.08-0.12 | 0.12-0.18 |
| `near_rain_width` | 0.45-0.70 | 0.65-0.90 |
| `far_rain_width` | 0.20-0.40 | 0.35-0.55 |
| `near_rain_transparency` | 0.55-0.75 | 0.70-0.90 |
| `far_rain_transparency` | 0.25-0.45 | 0.40-0.60 |
| `base_rain_speed` | 0.45-0.60 | 0.65-0.85 |
| `additional_rain_speed` | 0.25-0.45 | 0.35-0.55 |
| `slant` | 0.10-0.25 | 0.25-0.45 |

Never set `rain_amount` to zero because the shader divides by that value. Fade the owning CanvasItem or material visibility when rain must disappear, or add a separately approved intensity control during implementation.

### Recommended scene use

- Apply the shader to a story-mode-only screen-sized CanvasItem, such as a ColorRect or TextureRect, placed behind UI and in front of the distant background.
- Keep the shader's drawing rectangle larger than the viewport so camera motion never reveals uncovered edges.
- Use one material instance per active story scene or weather controller so Medium and Hard values can be changed without affecting shared resources.
- Test `rain_color` against each level background. A slightly cool gray-blue should remain visible without becoming a bright white curtain.
- Reduce the CanvasItem opacity or shader visibility during dialogue, precision jumps, and complex Wizard attacks.
- This shader can supply the main rain streak layer, but additional approved project assets are still needed for splashes, thunder, lightning, mist, leaks, and wet surfaces.

## Available rain and thunder sound analysis

- Audio: `../Rain/Rain_And_Thunder_5min.flac`
- Format: FLAC, stereo, 44.1 kHz, 24-bit.
- Exact duration: 319.929 seconds, or approximately 5 minutes 19.9 seconds.
- File size: 60,332,138 bytes, approximately 57.5 MiB.
- Average compressed bitrate: approximately 1,509 kbps.
- Embedded title, author, copyright, and license tags: none found.

This is suitable as a long ambient rain-and-thunder bed, but it is not yet verified as a seamless loop. Before implementation, listen specifically to the first and last several seconds and test a short crossfade. Do not assume the end can jump directly back to the beginning without an audible seam.

The shader's MIT license applies to the shader only. It does **not** prove that the FLAC may be redistributed in the game. Record the audio source and license or obtain permission before shipping or distributing it.

### Recommended audio behavior

- Use a story-mode weather or ambience audio bus, separate from dialogue, combat, UI, and critical warning sounds.
- Medium can use the track at a restrained baseline level. Hard may raise it modestly and use stronger thunder emphasis, but critical cues must remain louder and clearer.
- Duck the weather bus during dialogue, memory scenes, Minotaur warning cues, Wizard attacks, checkpoint sounds, and important story events.
- Fade in and out over several seconds when entering or leaving rain zones; do not start or stop the track abruptly.
- Prefer a streaming/import mode appropriate for a five-minute ambience file and test actual memory use on the target build. The compressed file is 57.5 MiB, while raw decoded audio can require substantially more memory.
- Do not alter pitch or playback speed merely to represent Hard mode; that can make thunder sound unnatural. Change volume, layering, and timing instead.
- Test whether the thunder events align badly with dialogue or boss telegraphs. If necessary, use a rain-only layer plus separately controlled thunder assets when those assets become available.

## Asset and path rules

- Use only rain, particles, textures, sounds, lighting, shaders, and scene resources already present in the Silent City project unless the user later supplies or approves additional assets.
- Do not use external artwork or copy visual material from another game.
- Before implementation, inventory available weather assets and report what is missing.
- Confirm and document the source and redistribution license for `../Rain/Rain_And_Thunder_5min.flac`; the shader's MIT license does not cover this audio file.
- Reference every related PDF, image, scene, asset folder, or supporting file with a **relative path from this document or the agreed project root**. Never use a fixed drive letter, Windows username, home folder, or computer-specific absolute path.

## Copy-paste implementation prompt

```text
Design and later implement a story-mode-only rain and storm system for Silent City after receiving explicit approval. Do not modify online mode, multiplayer systems, online maps, networking, or shared resources. If a needed effect is shared, duplicate or isolate a story-mode copy first.

Medium difficulty uses steady, readable rain with light wind, subtle wet surfaces, restrained splashes, soft thunder, and occasional accessibility-safe lightning. Hard difficulty uses a denser and darker storm, stronger visual gusts, more dramatic thunder and lightning, and stronger scene reactions. Rain and wind do not change character physics, traction, jumping, attacks, damage, or enemy behavior unless separately approved.

Keep the player, enemies, hazards, platform edges, checkpoints, exits, projectiles, attack telegraphs, UI, subtitles, and story events clearly visible. Never create blind jumps or hide danger with rain. Reduce foreground rain during precision platforming, dialogue, and complex boss attacks.

For Outer Graveyard, build from drizzle to steady rain on Medium and from steady rain to a heavier storm on Hard. For Forgotten Path, use rain through ruined openings and use leaks, drips, runoff, and mist underground. For Wizard's Sanctum, keep the storm visible outside and use rain only through exposed architecture; let lightning support the Wizard's arrival and boss phases without obscuring combat. After the Wizard is defeated, weaken the storm and allow light to return.

Use the supplied shader at `../Rain/rain_and_snow_shader.gdshader` as the candidate main rain-streak layer, and keep its MIT notice from `../Rain/Rain and Snow Shader MIT Licence.rtf`. The shader's blurred rain-trail line is currently commented out and its sharp no-trail snow line is active; propose the exact story-mode-only change before editing it. First inventory any additional rain, splash, sound, lighting, mist, and wet-surface resources. If required assets do not exist, stop and report what is missing instead of downloading or generating replacements.

Use `../Rain/Rain_And_Thunder_5min.flac` as the candidate long ambience track. It is a 5:19.929 stereo, 44.1 kHz, 24-bit FLAC and is not yet confirmed as a seamless loop. Test its beginning/end transition, import memory, thunder timing, dialogue ducking, and weather-bus mixing before implementation. The file contains no embedded ownership or license tags, and the shader MIT license does not cover it; confirm the audio source and redistribution permission before shipping.

Use relative paths for every referenced PDF, image, scene, asset folder, or supporting file. Never use a drive letter, Windows username, home folder, or machine-specific absolute path.

Before changing the game, return: an asset inventory, proposed story-only scene structure, Medium and Hard weather settings, per-level weather zones, transitions, readability safeguards, accessibility settings, performance budget, test plan, and exact files that would change. Wait for approval before implementation.
```

## Approval decisions for later

- Confirm whether Easy is fully dry or may use a very light decorative drizzle.
- Confirm whether rain is visual only or whether any approved wet-ground mechanic will exist.
- Confirm available rain, thunder, wind, splash, mist, and wet-surface assets after the project inventory.
- Confirm exact Medium and Hard intensity after testing with the real characters and levels.
