# Project progress

## Project overview
Silent City (`Silent-City-steam`) is a Godot game with `Scenes/MainMenu.tscn` configured as its entry scene.

## Technologies used
Godot 4.7 project configuration, GDScript, Forward Plus, and the GodotSteam plugin.

## Completed features
Existing project files include a main menu scene and Steam lobby creation, listing, joining, and leaving methods. Runtime completion has not been verified in this task.

## Current task

- Strengthened water entry splash above the surface with wider, higher droplets and an expanding splash crown. Effect cleanup now allows droplets to finish. Existing water behavior test passed (exit 0); rendered appearance awaits confirmation.
- Added drowning: a fully submerged head causes 25 damage each second through the existing health/death system, including below the visible water bottom. Surfacing resets the damage timer. Focused Godot test passed for damage, surfacing, deep-water death, diving, and splashes (exit 0).
- Holding Down underwater now dives at 280 px/s; releasing it resumes the existing slow sinking. Focused Godot assertions passed for diving, release, splash triggering, and unchanged air movement; the test process returned exit code 1 after printing PASS.
- Added a translucent water foreground at Z = 11, above the player and below splash effects, so the character appears submerged below the animated surface. Movement remains unchanged; visual confirmation is pending.
- Added water entry response in `Scripts/Environment/sea_water.gd`: caps downward velocity at 80 px/s while submerged, triggers droplets/ripple/water sound once per entry, and leaves air movement unchanged. Focused Godot test passed for entry slowdown, no repeated splash, exit, and reentry. Swimming remains unimplemented.
- Added visual sea water across the lower right gap in `OuterGraveyardMoonlit.tscn` (X = 6592–8956), with pixel-stepped waves, ripples, and darker depth. Raised its surface from Y = 1100 to Y = 940 after the user's screenshot showed it was below the gameplay view. No platform changes or water gameplay added. Headless scene launch passed before this position adjustment; updated visibility awaits confirmation.
- Added `RightRockWall` to `OuterGraveyardMoonlit.tscn` using `Sprites/Tiles` rock edge/fill assets and solid collision. Extended it left to X = 8316 (five tile columns), retaining its right edge at the Camera2D limit X = 8956, after the user's screenshot showed only its outer edge from the sign platform. Headless scene launch passed; shutdown reported resource-leak warnings. Visual confirmation remains pending.
- Fixed descending the tall ladder after climbing up: pressing Down now applies the existing 12 px drop whenever climbing against the platform floor, including while already climbing. A focused Godot physics test reproduced the blockage before the change and passed afterward.
- Smoothed normal walking and running with delta-based acceleration (`2200`) and deceleration (`3000`); jumping and sliding remain unchanged.
- Cleaned the exterior contour of `house_01_2d.png` into the preserved sibling `house_01_2d_clean.png`; `OuterGraveyardMoonlit.tscn` now uses the clean version while the original remains unchanged.
Completed: produced a second corrected tall-balcony house with one uniform dark contour tight to the colored silhouette, removing the doubled black halo and uneven exterior blocks. The scene uses the v2 asset; earlier versions remain preserved.

## Important decisions
The second tileset is used only as darkened decorative background ground. The playable ground and collision geometry remain original and unchanged. No background photo is used. Story direction is in `AGENTS.md`.

## Known issues
The working tree has pre-existing modifications and deletions; their intent and runtime impact were not assessed. `validate_second_prompt.gd` passes the new background composition and collision checks, then fails on unrelated missing moon/fog/encounter scene content.

## Next steps
Await the user's next instruction.
