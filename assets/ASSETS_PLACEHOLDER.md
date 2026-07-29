# Assets removed — licensing

The art/audio that lived under this folder are purchased packs licensed to
the project owner only, so they are **not in the repo**. The game expects
the files at these same paths; fresh clones run with missing-asset
placeholders/silence where the engine allows it. Originals live on the
owner's dev machine. **Never commit media files here** — `.gitignore`
blocks all image/audio extensions.

Full path-by-path replacement manifest (formats, dimensions, fallbacks):
see [`ASSETS_NEEDED.md`](../ASSETS_NEEDED.md) at the repo root.

## What belongs under `assets/`

| subpath | contents | reference format |
|---|---|---|
| `assets/*.png` | 16 full-screen mode backgrounds + `mainmenu.png` | PNG 1536x1024 (Slots/MageTower 1024x1536) |
| `assets/Explore/*.png` | 12 exploration backdrops (same names as root backgrounds) | PNG 1536x1024 |
| `assets/characters/**` | 487 portraits (Human/ELF/ORC/Animals/Monsters/Dwarves/Gnomes/Goblin/Demons + root specials) | PNG 256x256 |
| `assets/icons/<category>/` | 2,667 item/skill icons (weapons, armor, items, loot, resourcesandfood, skills, quest, tech, buildingmaterialicons, professions) | PNG 256x256 |
| `assets/ui/` | 27 button/frame/bar sheets listed in `uiassets.lua` (folder optional — rectangle fallback is the shipped look) | PNG, any size |
| `assets/lpc/**` | LPC tile atlases + Universal Spritesheet characters/creatures (atlas sizes are load-bearing — see `renderer2d.lua` and root manifest) | PNG, 32px/16px grids, 64x64 frames |
| `assets/music/*.WAV` | 10 looping music tracks (combat/exploration/town/menu) | WAV 44.1 kHz 16-bit stereo |
| `assets/dungeon_crawl/`, `assets/rpg_gui_kit/`, `assets/moderna/` | optional legacy packs for `assetpipeline.lua`; not present even in the reference set | PNG/PSD |

Filename lists live in code: `uiassets.lua` (elements, backgrounds, portraits,
icons, music), `rpg_data.lua` (`portraitMappings`), `renderer2d.lua`
(`ATLAS_CONFIG`), `main.lua` (track lists), plus `ASSET_GUIDE.txt` for the
character-folder convention.
