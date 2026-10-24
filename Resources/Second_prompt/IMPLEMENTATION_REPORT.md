# Second Prompt 0.1 implementation report

Source specification: `Second_prompt/0.1_second_prompt_master.pdf` and its three supporting PDFs.

## Result

- Easy/offline remains routed to `Scenes/OuterGraveyardMoonlit.tscn`.
- Squad and Online/Steam Friends entry points are hidden from Home, Start mode, Difficulty, and Character Select. Original character artwork remains untouched, while the four generated squad SpriteFrame `.tres` import manifests were removed.
- The cemetery uses the supplied PNG artwork without renaming, deleting, or redrawing source images.
- One moon and layered depth are built at runtime: the supplied single-moon image provides its own rear hill bands, with two subtle static fog layers. The opaque `distant_hills.png` card is no longer tiled over the sky.
- The moon/sky and both fog layers are now screen-locked with a zero scroll factor and zero automatic drift. Fog opacity is reduced to a restrained `0.09-0.115` charcoal haze, preventing distracting background motion while retaining depth.
- Responsive native soil rows keep their top edge at world `y = 620` and add two rows of vertical overscan when viewport or zoom changes.
- A later environment-art pass added three new transparent pixel houses to the runtime back layer: a cottage in the teaching stretch, a longhouse in the pressure zone, and a manor in the final grave row. The earlier supplied house and broken-chimney source PNGs remain untouched; the bridge waterfall remains the only animated environmental landmark.
- The bridge contains the only waterfall. It uses the supplied cliff/back/front/mist/splash layers and all 8 waterfall frames at 8 FPS, with positional procedural water audio and no collision.
- The whole cemetery contains one Zombie Villager in one grave encounter. No other enemy instances are created.
- Zombie Villager and Skeleton Warrior each expose all 17 supplied animation folders and all 207 frames. Runtime textures are imported at a 256-pixel limit and animations are shared/lazy-loaded instead of eagerly retaining all 414 decoded frames.
- Enemies are invulnerable while emerging, use one telegraphed melee hit window, and report to the existing HUD enemy group only after activation.

## Gameplay tuning

| Enemy | Speed | Player-walk ratio | Life | Attack | Windup | Recovery |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Zombie Villager | 95 | 38% | 75 | 10 | 0.62 s | 0.95 s |
| Skeleton Warrior | 130 | 52% | 50 | 10 | 0.46 s | 0.72 s |

## Project paths implemented or updated

- `Scenes/OuterGraveyardMoonlit.tscn` — generated playable story level.
- `Scenes/Enemies/ZombieVillager.tscn` — zombie tuning resource.
- `Scenes/Enemies/SkeletonWarrior.tscn` — skeleton tuning resource.
- `Scenes/Environment/CemeteryBackground.tscn` — runtime parallax background wrapper.
- `Scenes/Environment/BridgeWaterfall.tscn` — unique waterfall landmark wrapper.
- `Scripts/build_outer_graveyard_moonlit.gd` — deterministic level builder.
- `Scripts/Enemies/story_enemy.gd` — complete on-disk animation inventory and enemy state machine. The one runtime enemy deliberately retains only its shared 18-frame idle animation; movement, attack, hurt, and death state changes reuse it so combat cannot trigger texture-loading freezes.
- `Player/player.gd` and `Scripts/online_manager.gd` — all direct squad-character SpriteFrame preloads/import references were removed from startup/runtime character selection; legacy squad selections safely fall back to the story player.
- `Scripts/Enemies/enemy_health_bar.gd` — compact world-space health display.
- `Scripts/Enemies/grave_encounter.gd` — grave telegraph, staging, and concurrency control.
- `Scripts/Environment/cemetery_background.gd` — camera-driven parallax and drifting fog.
- `Scripts/Environment/bridge_waterfall.gd` — exact-layer waterfall animation, matte cleanup, and positional sound.
- `Scripts/Environment/responsive_ground.gd` — native repeated soil rows with dynamic overscan.
- `Scripts/validate_second_prompt.gd` — source inventory and gameplay acceptance checks.
- `Scripts/validate_outer_graveyard_moonlit.gd` — updated graveyard regression assertions.
- `Scripts/capture_second_prompt_visuals.gd` — repeatable visual captures at 1280x720, 1920x1080, and 2560x1440.
- `Second_prompt/**/*.png.import` — 466 Godot-generated import sidecars next to the untouched supplied PNGs.

Godot also owns the corresponding `.uid` files beside imported GDScript files.

## Verification completed

- Second-prompt acceptance validator: passed.
- Outer Graveyard scene validator: passed (`133` sprites, `105` graveyard PNGs).
- Sagging bridge regression: passed.
- Pause/resume/Main Menu regression: passed.
- Native background preloader: passed after RAM optimization (`load 898 ms`, `instantiate 7 ms`, `ready 346 ms` in the final sequential run).
- Direct target-scene runtime: passed for 5 seconds with exit code `0`.
- Visual inspection: passed at 1280x720, 1920x1080, and 2560x1440; no bottom soil gaps were visible.
- Final six-second gameplay trace: peak observed Godot working set was `438.5 MiB`, stable instead of continuously climbing to roughly `2.7 GiB`. The principal issue was the shared player script preloading all four squad-character libraries in story mode; these are now selected-character-only resources.

Godot reports the existing Windows root-certificate warning and shutdown-only dummy-renderer RID leak warnings in headless tests. A forced 10-second automated GUI shutdown can also terminate inside the existing native menu optimizer; the dedicated native-preloader check itself passes.

## Licensing note

The supplied Zombie Villager and Skeleton Warrior folders retain their Craftpix license links and Moon Get font readmes. Confirm the project's Craftpix entitlement before release.
