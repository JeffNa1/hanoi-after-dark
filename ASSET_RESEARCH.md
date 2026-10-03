# Melee asset research and selection

Source pages and their asset-specific license labels were checked directly. The local `asset_research` directory retains source-page captures and downloaded archives for inspection. Those webpage captures are not runtime assets and are not included in the playable ZIP.

## Selected: Crowbar 01

Creator: Alexander Otterbeck. Provider: Poly Haven. Asset: https://polyhaven.com/a/crowbar_01 . Primary license: https://polyhaven.com/license . License: CC0. The provider's public asset-info response confirms the creator and weathered-metal material description.

Selected the 1K glTF version with diffuse, normal and packed material maps. The published API file records supplied expected digests; every downloaded file matched its published MD5. The worn metal, compact silhouette and small mesh fit the existing street and character aesthetic. Runtime use is the F-key quick strike, not a replacement for the authored enemy tools. Placement and uniform scale are local presentation changes.

## Selected: adjustable wrench from Tool Pack 1

Creator: LonesomeDucky. Primary page: https://opengameart.org/content/tool-pack-1 . License shown on that page: CC0. The published pack includes low-poly GLB files and editable Blender sources. Its wrench is described as 961 vertices, 1,240 triangles and 1K textures.

The exact wrench GLB is used as a small dropped repair detail beside the parked scooter near the starting street. The runtime positions it flat on the measured collision surface. It is not advertised as a selectable player weapon. The pack's hand saw and tape measure were also inspected as similar improvised-tool candidates; they are not added merely to increase item count.

## Evaluated, not imported: Chainsaw

Creator: Clint Bellanger. Primary page: https://opengameart.org/content/chainsaw . License shown on the page: CC0. The source describes a 344-triangle, UV-unwrapped but untextured model.

Its silhouette is a useful chainsaw reference. Its missing texture/material finish does not match the finished street assets without another material-authoring pass. It is therefore not a runtime asset and not a promised playable weapon. This avoids shipping an unfinished placeholder or assigning a license based only on a search snippet.

## License and provenance limits

A second, textured chainsaw reference was also checked: https://opengameart.org/content/chainsaw-1 by loafbrr_1. Its current primary page states CC0, 5,954 triangles, 1K maps, and supplied Blender, glTF/FBX and Godot files. The page's old license-wording correction is visibly resolved. This is the stronger reference for a future usable chainsaw. It is not imported into this release: a motorized attack needs its own contact timing and motor/audio behavior, rather than relabeling the tested crowbar swing or adding another decorative item solely to increase item count. Both chainsaw source-page captures remain available in `asset_research`.

CC0 summary: https://creativecommons.org/publicdomain/zero/1.0/ . The primary pages, not preview-image availability, informed these selections. Original runtime file hashes are recorded in `reports/asset_sources.json`. New audio sources and their exact selections are separately identified in `CREDITS.md` and `reports/survival_audio_assets.json`.

These checks concern the newly downloaded assets. They do not relabel the existing mixed-provenance character animations as CC0 or establish rights for distributing a standalone motion library. The working project preserves the original character files.
