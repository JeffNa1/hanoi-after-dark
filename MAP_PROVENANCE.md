# Hanoi Old Quarter street study — references and provenance

## Scope and fidelity

This is an **authored, approximate game environment**, not a survey-accurate reconstruction of Hanoi and not photogrammetry. The geographical anchor is the Tạ Hiện / Lương Ngọc Quyến intersection at **21.0347124 N, 105.8521568 E**, OSM node **81794512**. The scene follows the first northbound Tạ Hiện segment to the Ngõ Đào Duy Từ junction (node **320446997**), and includes truncated east/west Lương Ngọc Quyến branches and a truncated eastbound alley. It is a bounded excerpt with invented work barriers, not a claim that the real streets end there.

The main alignment and junction distance are derived from downloaded OSM coordinates. Side-road bearings use nearby source nodes. Curved streets are simplified to short straight segments. Widths, shophouse footprints, heights, floor counts, shop names, signs, props and closures are authored. Building names are fictional/generic Vietnamese business descriptions, not recreated real businesses.

## Downloaded geographical source

- Publisher: **OpenStreetMap contributors**; retrieved through the public Overpass API.
- Source endpoint: https://overpass-api.de/api/interpreter
- Query: `[out:xml][timeout:30];way[highway](21.0340,105.8506,21.0367,105.8531);(._;>;);out body;`
- Original saved data: `old_quarter.osm`, including Overpass generator, database timestamp and ODbL note.
- Source ways: **765597030**, **599638071** (Tạ Hiện); **601571386**, **1298765554** (Lương Ngọc Quyến); **29127986** (Ngõ Đào Duy Từ).
- License: **Open Database License 1.0**, https://opendatacommons.org/licenses/odbl/1.0/
- Attribution: **© OpenStreetMap contributors**, https://www.openstreetmap.org/copyright
- Preserve the attribution for distributed map-derived outputs. The saved coordinate/layout extracts are ODbL-derived data; the scene is an authored produced work, not a cadastral dataset.
- `reference_map.svg` plots downloaded source ways; `authored_layout.svg` shows the deliberately simplified playable layout. Neither is a third-party map tile or screenshot.

The primary OSM API connection was refused. The public Overpass read-only endpoint succeeded; no authentication, paywall or rate limit was bypassed.

## Permitted photographic references

### 1. Tạ Hiện Street

- File: `ta_hien_2015.jpg`, downloaded unmodified.
- Author: **9636137**.
- Photograph date: **February 16, 2015** (file metadata).
- Original source: https://pixabay.com/p-3559133
- Commons record: https://commons.wikimedia.org/wiki/File:Ta-hien-street-3559133.jpg
- License: **CC0 1.0**, https://creativecommons.org/publicdomain/zero/1.0/
- License verified through the Wikimedia file description mirrored at https://vi.wikipedia.org/wiki/Tập_tin:Ta-hien-street-3559133.jpg ; HTML evidence: `license_verified_0.html`.
- Studied cues: narrow street canyon, attached narrow frontages, aged yellow/green plaster, utility cable bundles, shallow curbs, metal shutters, balconies, awnings and parked motorbikes.

### 2. Café on Lương Ngọc Quyến

- File: `luong_ngoc_quyen_cafe_2024.jpg`, downloaded unmodified.
- Author: **Alexey Komarov / Alexkom000**.
- Photograph date: **November 3, 2024**.
- Source: https://commons.wikimedia.org/wiki/File:2024-11-03_A_cafe_in_Hanoi%27s_Old_Quarter.jpg
- License: **Creative Commons Attribution 4.0 International**, https://creativecommons.org/licenses/by/4.0/
- Attribution for the included unmodified photo: **“A cafe in Hanoi's Old Quarter” — Alexey Komarov (Alexkom000), CC BY 4.0, via Wikimedia Commons. No modifications.**
- License evidence: `license_verified_1.html`, obtained from the file page using its ordinary `?uselang=en` variant.
- Location recorded by photographer: **21.034796 N, 105.851780 E**.
- Studied cues: yellow plaster, green trims, dark recessed café, egg-coffee identity, small sidewalk furniture, layered signs, flowering foliage, utility wires, raised stone curb and a parked scooter.

**These photos are reference documents only. They are not used as scene textures, material maps, skyboxes, backdrops or projections.** Attribution does not imply photographer endorsement. Hashes, file sizes and URLs are in `sources.json`.

## Scene asset provenance

All building shells, facade detail, shutters, balconies, railings, AC units, water tanks, scooters, stools, tables, food-shop bowls/pots, bins, plants, lanterns, utility cables, drains, paving, service doors and signs were authored in `build_environment.py` for this project. No commercial marketplace model, external prop library or character mesh was imported.

Material albedos are original deterministic raster patterns created by the build script, not sampled or cropped from the study photographs. They are packed in Blender and embedded in GLB. Their visible weathering is deliberately stylized and does not reproduce real facade damage.

Vietnamese text was outlined from the installed Windows Arial font. No font binary is distributed. Unused font and curve data was removed after mesh conversion. The deliverable contains editable geometry for the lettering, including Vietnamese diacritics.

Blender/Godot are tools, not bundled dependencies. No engine install, source character asset, animation tool, other project or active Blender scene was modified.
