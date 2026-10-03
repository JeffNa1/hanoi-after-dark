# Hanoi: After Dark

A complete short-session Windows survival game on a Hanoi-inspired neighborhood. Survive three waves of 6, 9 and 12 enemies. Clear all 27 to win. This is a finite survival session, not an endless campaign.

## Play

Open `Open_FPS.cmd`. Godot 4.7 or newer must be on PATH. This project was checked with Godot 4.7.2. The engine is not bundled.

Press Enter or click ENTER STREET. WASD moves, Shift sprints, Space jumps, and the mouse looks. LMB fires, RMB aims, R reloads, and 1-4 or the mouse wheel selects a gun. F performs an ammunition-free crowbar strike. Escape pauses or resumes. M mutes or unmutes the ambient music. Enter restarts after death or victory.

Pistol and shotgun are semi-automatic. The rifles support held fire. Shotgun reload inserts individual shells and can be interrupted by firing. Cover blocks bullets and the crowbar. Melee has a windup, one damage event, and recovery. It cannot overlap gunfire.

## Survival rules

Enemies spawn at least ten metres away, outside the expanded current view, on navigation connected to the player. A full safe spawn search can defer a spawn. The game does not substitute a visible spawn. At most eight enemies are alive at once. A directional growl and brief ground debris mark arrivals.

Between waves, the game grants up to 20 health and two magazines of reserve ammunition per gun, capped at the starting reserve. The seven-second respite lets the player reload and move. Death, victory and pause stop new spawns. Restart clears enemies, timers, ammunition state, melee state and feedback.

The roster contains all 13 approved source characters. Ten carry character-specific authored weapon or free-hand attacks. Three retain their unarmed attack. All models share the existing pursuit and damage rules.

## Presentation and assets

Recorded firearm audio is retained. New licensed recordings add positional zombie warnings, injury and death voices, stone footsteps, crowbar movement and a quiet looping horror bed. Audio voices and debris bursts use fixed pools. A small camera roll and world muzzle light complement the gun animations and hit markers.

Cool dusk lighting, restrained warm street lights, distance haze, a short-range camera light and a mild shadow or vignette pass replace daylight. The grade affects the world, not the HUD. It does not cover the game with a flat hue overlay.

The CC0 Poly Haven crowbar is playable with F. LonesomeDucky's CC0 wrench is a dropped workshop repair detail beside a scooter, not a selectable weapon. A chainsaw was researched but not imported. See `ASSET_RESEARCH.md`, `CREDITS.md` and `MAP_PROVENANCE.md`.

## Public distribution note

This repository contains runtime files and credited third-party assets. Read `CREDITS.md` and `ASSET_RESEARCH.md` before redistribution or commercial use. No blanket license is granted for third-party assets.

The large Godot import cache, local worker files, research captures, reports, evidence media and the 378 MB ZIP are not included. The launcher creates a fresh import cache on the first run.

## Limits

There is no save system, loot or building system, multiplayer, infinite progression or standalone engine executable. The engine must be installed separately. Automated runtime checks are not human difficulty, listening or artistic approval.
