# Public build checks

## Enemy animation diagnosis

Checked only this public repository with Godot 4.7.2, the native OpenGL compatibility renderer and an RTX 3060. The parent authoring project was not used or changed.

A clean import did **not** reproduce a total loss of imported animations on this machine: the baseline walk, attack and death poses changed on the GPU. It did reproduce these narrower gameplay failures:

- The bottle carrier's blocked/idle pose changed only two silhouette pixels across 36 frames despite an advancing animation clock. Some carry-preserving source idles contain held upper-body poses. A clock/bone-only check was insufficient.
- `run` existed in every model but gameplay never selected it.
- A fixed 3.3 playback rate cut the differently sized hit clips short when the 0.28-second flinch ended. Repeated `play("hit")` calls resumed the existing reaction rather than restarting it.

The new runtime test failed on these behaviors before the repair. Corrections were checked separately: hit timing/restart, idle motion, then sprint pursuit. No GLB, texture, sound, map, navigation data or import setting changed.

## Runtime behavior

Idle adds a small chest breathing motion above the existing planted feet. This is a render-time skeleton adjustment; it does not bob the actor, change collisions or overwrite the supplied clips. Walk keeps the original 1.35 m/s pace and measured foot planting.

An enemy pursues at 2.7 m/s when the player moves faster than 4.5 m/s and remains more than four metres away. Actual movement speed selects walk or run and controls playback speed. Stopping the sprint returns the enemy to walking. This is an explicit chase-speed change, not merely a renamed walk clip.

A hit restarts its reaction and fits the full supplied clip inside the existing flinch duration. It cancels the current attack. The existing attack contact/dodge rules and death/corpse timing remain. Death holds its final pose until corpse cleanup, including after victory.

## Reproduce the focused native check

Run from the repository root:

```sh
godot --headless --path godot --editor --import
godot --path godot --fixed-fps 60 --script res://tests/test_zombie_animation.gd
```

The test creates its ignored `reports` directory. Add `-- --capture` to the second command for optional local first/peak/last images in `evidence/zombie_animation`. Neither directory belongs in Git. The test rejects `--headless`: real rendered silhouettes are part of the assertions.

The regression uses the real survival director, zombie physics, navigation, player input and damage methods. It isolates one enemy at a time without disabling that enemy's AI. It never calls `AnimationPlayer.play`, `seek` or `advance`.

It checks all six states for all 13 roster entries: 78 model/state samples. Each must advance its clock, change bone poses and change the native GPU silhouette. A following camera cancels actor translation and yaw; alpha-only comparisons exclude lighting changes and background movement. It also checks blocked idle, walking displacement, input-driven sprint/run/walk transitions, pause/resume, contact damage, flinch interruption, repeated hits, death counting, corpse collision, final-pose retention, cleanup and restart.

## Executed results

A fresh import with no `.godot` directory passed. The following 22 runtime scripts passed after the final changes, for 23 successful processes including import:

- `test_render_bindings`, `test_weapon_state`, `test_four_weapons`, `test_fps_slice`
- `test_encounter`, `test_encounter_e2e`, `test_navigation_detour`, `test_recorded_audio`
- `test_reload_sync`, `test_shotgun_cycle`, `test_gait_runtime`, `test_gait_corners`
- `test_roster_runtime`, `test_survival`, `test_native_gameplay`, `test_native_visibility`
- `test_melee`, `test_attack_milestone`, `test_zombie_animation`, `test_feedback`
- `test_complete_run`, `test_quit`

All process exits were zero. Logs had no script/engine errors or leaked-instance messages. The new animation check passed all 78 samples; the smallest observed silhouette change was 805 pixels at 320 x 320. The bottle carrier changed 805 idle pixels, 5,351 attack pixels and 3,216 hit pixels in the checked windows.

The native complete playthrough reached victory with 27 kills, 108 shots and 100 health in approximately 67.24 simulated seconds. It uses automated aim with normal spawning, ammunition, reloads and damage, not a human difficulty evaluation. Existing all-roster support-foot and gait checks also passed.

The baseline encounter test exposed a separate test defect: walking around a corner need not immediately reduce straight-line distance to the player. Its assertion now requires actual body displacement and reduced remaining navigation-path length, while retaining the connected-path check. It no longer mistakes legitimate detours for stationary pursuit.

## Limits

Still-image pairs do not prove every intermediate frame is artistically correct. First/peak/last captures were reviewed, but source-model grip and skinning quality remain inherited. No replacement art or blanket artistic approval is claimed. Native checks on this machine do not guarantee the same result on a different Godot version or GPU. Local logs, captures, caches and ZIPs are not committed.
