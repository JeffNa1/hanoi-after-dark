# Sources and attribution: Hanoi After Dark

This is a playable review build, not a claim of photorealistic art or human approval. Original asset files and revisions 01–03 remain separate. Only runtime derivatives are packaged.

## Pistol and supplied FPS arms

Low Poly Pistol by **DJMaesen**, modified by **ImageParSeconde** for FPS animation; distributed by CoinCoin on OpenGameArt under **CC-BY 4.0**.

Source: https://opengameart.org/content/animated-pistol
Original model: https://sketchfab.com/3d-models/low-poly-pistol-0342cf497fef4b07804b32b4ab7271e5
License: https://creativecommons.org/licenses/by/4.0/

The integration retains supplied geometry, skinning and selected actions. It changes the coordinate frame, texture paths, material setup, action names and playback speed. These changes are not work supplied by the original authors. Source archives and editable derivatives remain in the working revision.

## AK and rifle arms

AK-47 geometry by **taradavies**, published under **CC0**.
Source: https://opengameart.org/content/ak-47-1
Original blend SHA-256: `f3e4d7708eeb95dbebe9e240c868148c4f03beda363fb904141861ffc8ec1392`.

Original wood images were missing and their origin was unclear. They are not used. Replacement wood maps: **Poly Haven**, `lacquered_cherry_wood`, **CC0**.
Asset: https://polyhaven.com/a/lacquered_cherry_wood
License: https://polyhaven.com/license

The integration normalizes the source control meshes, omits Blender-only modifiers, assigns complete rigid gun components, and authors a left-hand approach, rock-and-lock magazine extraction/insertion and recovery. Right-hand/fire motion derives from the existing FPS rig. This is not reload animation supplied by the static gun author.

## M4A1 and rifle arms

M4A1 static geometry and maps by **3dmodelscc0**, **CC0**.
Source: https://opengameart.org/content/m4a1-assault-rifle
Original archive SHA-256: `ed5779ec82718861964227e2aad2a900978ea087081154365d6d86246be62f0d`.

The integration binds source components to the existing FPS rig and authors left-hand reach, magazine extraction/insertion and recovery. Existing right-hand/fire actions remain. The source gun package does not supply FPS arms or animation.

AK and M4 arms use **Quaternius, Hoodie Character**, **CC0**.
Source: https://poly.pizza/m/gKLBoRsyKe
Creator: https://quaternius.com/packs/ultimatemodularcharacters.html
Original SHA-256: `0de1bcd789d409214cf82f66f61daeb53d2f7de6d914b23e7b3660bfb3dee61e`.

These derivatives retain stylized source hand/arm topology, remove the non-visible body, and use authored FPS poses. Smooth shading is not a replacement for realistic anatomy. No full-body player or visible legs are claimed.

## Lever-action shotgun and supplied FPS arms

**Winchester 1887 (low poly)** by **ValeGoG**, modified by **ImageParSeconde** for animation; distributed by CoinCoin under **CC-BY 4.0**.
Source: https://opengameart.org/content/animated-shotgun
Original model: https://sketchfab.com/3d-models/winchester-1887-low-poly-e6d17faf7a684e9b9e0f0930b8ea7b5c
License: https://creativecommons.org/licenses/by/4.0/
Archive SHA-256: `ee79e1c4ee3df32f4ef2cfa880388a7e5fa3bb358934ba1ced480067c9dfd77b`.

The integration retains source meshes, skinning, shells and mechanism actions; adapts textures and coordinates; and maps firing/reloading action durations to the gameplay clocks. It is a lever-action model, not a pump shotgun. No manufacturer endorsement or exact physical simulation is claimed.

## Recorded gun audio

**The Free Firearm Sound Library**, **CC0**, created and recorded by **Ben Jaszczak, Brian Nelson, Kevin Heras and Matthew Nanney**.
Source: https://opengameart.org/content/the-free-firearm-sound-library
License: https://creativecommons.org/publicdomain/zero/1.0/

Source selection follows the archive's `Prepared Master Sheet.csv`: 1911 `A_42P.wav`, AK-47 `C_28P.wav`, AR-15 `D_32P.wav`, and Mossberg `N_30P.wav`. These are recorded firearm sources, not exact recordings of every displayed mesh. The Mossberg recording is not a Winchester recording.

Edits: mono downmix, 48 kHz resample, onset/tail trimming, DC removal, peak normalization and short edge fades. No pitch substitution or synthesis is used in current gameplay. `reports/recorded_audio_assets.json` lists exact source and derivative hashes. The listening board uses actual native master-bus recordings. Signal checks and playback checks are not human listening approval. Earlier synthesized audio is retained only in the comparison evidence and revision 03, not as a runtime fallback.

## Zombie candidates

Existing project art, not newly downloaded Quaternius characters. The retained roster has 13 characters: the three existing walkers and `vn_zombie_12_xiec_lua` through `vn_zombie_21_phuot_thu`. Exact IDs and source hashes are in `attack_authoring/final_manifest.json`.

Inherited source metadata labels idle motion CC0 from Mesh2Motion and other original motions Adobe Mixamo royalty-free, not CC0. This continuation authors character-specific attacks and extends the measured walk to the complete roster. Candidate-only weight/carry repairs retain their individual provenance reports. The mechanic uses a source-preserving shoulder-driven hook instead of independent wrist roll. One independently identified floating bottle island is removed from the bar character's derivative; the held bottle and other components remain. Frozen inputs are not overwritten.

These characters are game components, not a standalone redistributable motion library. Preserve their mixed motion provenance and check applicable terms before a public asset-pack or commercial release. All 13 are integrated and runtime-checked. Human animation approval remains separate from numeric tests and native evidence.

## Hanoi-inspired neighborhood

The approved 300 × 300 m environment, 25 routes and 18 loops are retained. Buildings, signage, districts and props are authored approximations, not survey data. The layout uses OpenStreetMap-derived anchors.

**© OpenStreetMap contributors**: https://www.openstreetmap.org/copyright
Open Database License 1.0: https://opendatacommons.org/licenses/odbl/1.0/

`MAP_PROVENANCE.md` retains the original map notes. Reference photographs and font binaries are not runtime dependencies.

## New melee assets

**Crowbar 01**, **Alexander Otterbeck**, Poly Haven, **CC0**. Source: https://polyhaven.com/a/crowbar_01 . License: https://polyhaven.com/license . The integration uses the 1K glTF asset and its original maps, checks the published file digests, and changes placement/scale for the local quick-strike presentation. No preview image is included as game content.

**Adjustable wrench**, from Tool Pack 1 by **LonesomeDucky**, **CC0**. Source: https://opengameart.org/content/tool-pack-1 . The original low-poly GLB is retained and placed as a workshop repair detail. It is not a selectable player weapon.

**Chainsaw**, **Clint Bellanger**, **CC0**, was evaluated only. Source: https://opengameart.org/content/chainsaw . Its untextured source does not match the finished material style, so it is not included in runtime. CC0 summary: https://creativecommons.org/publicdomain/zero/1.0/ .

## New recorded music and effects

**Ancient caverns (horror ambient loop)** by **congusbongus**, **CC0**: https://opengameart.org/content/ancient-caverns-horror-ambient-loop . The original `caverns_0.ogg` is used as a quiet looping horror music/ambient bed. It is not a recording of Hanoi street ambience.

**Zombies Sound Pack** by **artisticdude**, **CC0**: https://opengameart.org/content/zombies-sound-pack . Selections: `zombie-1.wav`, `zombie-5.wav`, `zombie-10.wav`, `zombie-20.wav`. Runtime roles are arrival/groan, injury and death; role names are local choices, not titles assigned by the source author.

**Fantozzi's Footsteps**, recorded by **Fantozzi**, sliced/submitted by **qubodup**, **CC0**: https://opengameart.org/content/fantozzis-footsteps-grasssand-stone . Original recordings: http://www.freesound.org/people/Fantozzi/packs/10338/ . The four stone OGG clips `L1`, `R1`, `L2`, `R2` are copied unchanged.

**3 Melee sounds** by **remaxim**, based on **qubodup** bamboo swishes, **CC0**: https://opengameart.org/content/3-melee-sounds . The generic `melee sound.wav` provides crowbar movement, not a claimed physical recording of this crowbar model.

New WAV derivatives use mono downmix, DC removal, peak normalization and 3ms edge fades. Original sample rates are retained. The source/member/output digests and signal measurements are in `reports/survival_audio_assets.json`. Small runtime voice-pitch variations prevent identical repeats. No generated audio replaces the recordings.

## Current tools and review scope

Tested with Godot 4.7.2 and Blender 4.2. Engine executables and export templates are not bundled. The launcher requires Godot on PATH. Native captures use controlled fixtures and are not human balance playtests. Material, grip and full-motion artistic approval remain separate from file integrity, geometry/contact tests and native render checks.
