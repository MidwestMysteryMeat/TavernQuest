# ASSETS_NEEDED — user-supplied asset manifest

TavernQuest ships **no art, audio, or fonts**. Every media file was a purchased
pack licensed to the project owner only, so media is stripped from the repo and
blocked by `.gitignore` (all image/audio/font extensions). **Never commit media
files to this repository.**

The game boots and plays fully without any of these files: every load site is
`pcall`- or `love.filesystem.getInfo`-guarded, and each screen falls back to
placeholder rendering (colored rectangles, "?" portraits, text labels) or
silence. Supply your own files at the paths below to re-skin the game.

Column notes:
- **dimensions** are the actual sizes of the reference files on the owner's dev
  machine. Replacements do not have to match exactly — everything is scaled at
  draw time — but aspect ratio should be close, and atlases/spritesheets must
  match the stated grid or the quads will slice wrong.
- **required?** — everything is *optional*; the column flags how visible the
  gap is without the file.
- Filename case matters if you ever run from a `.love` archive or on Linux:
  match the `.PNG` / `.png` / `.WAV` casing shown.

---

## 1. Character portraits — `assets/characters/`

Portrait art for the player, NPCs, poker opponents, pets, creature cards, and
enemies. Reference set is **487 PNGs, all 256x256**. Loaded by
`uiassets.lua` (`UIAssets.getCharacter` → `assets/characters/<name>.PNG`),
`rpg_core.lua` (`getPortraitImage` / `getCreationPortrait` via
`Data.portraitMappings` in `rpg_data.lua`), `employees.lua`, `hunting.lua`
(animal sprites).

Drawn scaled-to-fit: 250x410 panel in character creation (`rpg_draw_creation.lua`),
120x120 tiles in the portrait picker, small squares in dialogs/poker/pets.

| path | type | format | dimensions | used for | required? | fallback |
|---|---|---|---|---|---|---|
| `assets/characters/Human/Men_Human/*.PNG` | portrait | PNG | 256x256 | male human NPCs, player classes | optional | gray box + "?" |
| `assets/characters/Human/Women_Human/*.PNG` | portrait | PNG | 256x256 | female human NPCs, player classes | optional | gray box + "?" |
| `assets/characters/ELF/Men_ELF/*.PNG`, `ELF/Women_Elf/*.PNG` | portrait | PNG | 256x256 | elf NPCs / ranger class | optional | gray box + "?" |
| `assets/characters/ORC/Men_ORC/*.PNG`, `ORC/Women_ORC/*.PNG` | portrait | PNG | 256x256 | orc NPCs / enemies | optional | gray box + "?" |
| `assets/characters/Animals/*.PNG` | portrait | PNG | 256x256 | pets, hunting animals, creature cards | optional | gray box + "?" |
| `assets/characters/Monsters/*.PNG` (+ `Monsters/Undead/`) | portrait | PNG | 256x256 | enemies, creature cards | optional | gray box + "?" |
| `assets/characters/Dwarves/`, `Gnomes/`, `Goblin/`, `Demons/` | portrait | PNG | 256x256 | race/enemy portraits | optional | gray box + "?" |
| `assets/characters/*.PNG` (root: gods, undead, giants, misc) | portrait | PNG | 256x256 | gods, special NPCs | optional | gray box + "?" |

Exact expected filenames: see the lists in `uiassets.lua`
(`characterCategories`, `malePortraits`, `femalePortraits`) and
`rpg_data.lua` (`Data.portraitMappings`, `CLASS_PORTRAIT_OPTIONS`), plus
`ASSET_GUIDE.txt` for the folder convention.

Known mappings with **no file even in the reference set** (always fall back):
`assets/characters/BeastFolk/Catfolk/Men_Catfolk/Catfolk_01.PNG` (monk/catfolk),
`assets/characters/BeastFolk/Lizardfolk/Lizardfolk_01.PNG` (lizardfolk),
`assets/characters/Undead_11.PNG` (lich/necromancer).

## 2. Tavern / game-mode backgrounds — `assets/` root and `assets/Explore/`

Full-screen backdrops, scaled cover-style to any window size
(`uiassets.lua` `gameBackgrounds` / `exploreBackgrounds`, `menu.lua`,
`game.lua`). Reference art is **1536x1024** (landscape) except
`Slots.png` and `MageTowerMode.png` at **1024x1536**.

| path | type | format | dimensions | used for | required? | fallback |
|---|---|---|---|---|---|---|
| `assets/mainmenu.png` | background | PNG | 1536x1024 | main menu | optional | flat color menu |
| `assets/Fishing background art.png` | background | PNG | 1536x1024 | fishing mode | optional | flat color scene |
| `assets/ForgeBackgroundart.png` | background | PNG | 1536x1024 | forge/crafting | optional | flat color scene |
| `assets/Petsim.png` | background | PNG | 1536x1024 | pet sim | optional | flat color scene |
| `assets/Slots.png` | background | PNG | 1024x1536 | slots minigame | optional | flat color scene |
| `assets/WageModeBackground.png` | background | PNG | 1536x1024 | cafe/wage mode | optional | flat color scene |
| `assets/Tavern Poker Table.png` | background | PNG | 1536x1024 | poker table (also loaded by `game.lua`) | optional | felt-colored table |
| `assets/Camp exploration.png` | background | PNG | 1536x1024 | camp/exploration | optional | flat color scene |
| `assets/Hunt1.png`, `Hunt2.png`, `Hunt3.png` | background | PNG | 1536x1024 | hunting mode | optional | flat color scene |
| `assets/MageTowerMode.png` | background | PNG | 1024x1536 | wizard tower | optional | flat color scene |
| `assets/AlchemistTowerMode.png` | background | PNG | 1536x1024 | alchemist | optional | flat color scene |
| `assets/Backpack.png` | background | PNG | 1536x1024 | inventory screen | optional | flat color panel |
| `assets/MarketBuy.png`, `assets/StallMarketSelling.png` | background | PNG | 1536x1024 | market buy/sell | optional | flat color scene |
| `assets/Race Track.png` | background | PNG | 1536x1024 | (present in reference set, not referenced by code) | optional | n/a |
| `assets/Explore/*.png` (12 files, same names as above) | background | PNG | 1536x1024 | random Text-RPG exploration backdrops | optional | flat color scene |

## 3. UI element sheets — `assets/ui/`

27 files listed in `uiassets.lua` `UIAssets.elements` (buttons, frames,
panel backgrounds, HP bars, name bars): `button.PNG`, `button2.PNG`,
`button_agree.PNG`, `button_cancel.PNG`, `button_frame.PNG`,
`button_ready_on/off.PNG`, `button2_ready_on/off.PNG`, `button3_ready.PNG`,
`Frame_big.PNG`, `Frame_mid.PNG`, `Frame_mid_2.PNG`, `big_background.PNG`,
`mid_background.PNG`, `Mini_background.PNG`, `big_roundframe.PNG`,
`lil_roundbackground.PNG`, `lil_roundframe.PNG`, `lil_roundframe_ready.PNG`,
`lil_roundframe_ready2.PNG`, `Mini_frame0/1/2.PNG`, `Hp_frame.PNG`,
`Hp_line.PNG`, `bar_ready.PNG`, `barmid_ready.PNG`, `name_bar.PNG`,
`name_bar2.PNG`, `name_bar3.PNG`.

| path | type | format | dimensions | used for | required? | fallback |
|---|---|---|---|---|---|---|
| `assets/ui/*.PNG` (27 files) | UI skin | PNG | any (stretched to fit) | buttons, frames, bars everywhere | optional | drawn rectangles (fully styled fallback) |

**Note:** this folder is absent even from the reference set — the shipped game
currently runs entirely on the rectangle fallback. Any images you drop in are
stretched to the target widget size, so dimensions are free.

## 4. Item icons — `assets/icons/` (by category dir)

Square item/skill icons, **256x256 PNG** in the reference set (2,667 files),
drawn scaled to slot size. Loaded via `UIAssets.getIcon`/`getIconByName`
(`uiassets.lua` `iconPaths` + `iconRegistry`), plus direct paths in
`backpack.lua`, `stockmarket.lua`, `hunting.lua`, `rpg_world.lua`,
`alchemist.lua`, etc.

| path | type | format | dimensions | used for | required? | fallback |
|---|---|---|---|---|---|---|
| `assets/icons/weapons/` (514: `Sword_NN.PNG`, `Axe_NN.PNG`, `Bow_NN.PNG`, ...) | icon | PNG | 256x256 | weapon items | optional | colored square + label |
| `assets/icons/armor/` (526: `Helm_NN.PNG`, `Chest_NN.PNG`, `Boots_NN.PNG`, ...) | icon | PNG | 256x256 | armor items | optional | colored square + label |
| `assets/icons/items/` (77: `Potion_NN.PNG`, `Alchemy_*.PNG`) | icon | PNG | 256x256 | potions/consumables | optional | colored square + label |
| `assets/icons/loot/` (203: `Loot_NN_*.PNG`) | icon | PNG | 256x256 | chests, keys, loot | optional | colored square + label |
| `assets/icons/resourcesandfood/` (304) | icon | PNG | 256x256 | coins, food, resources | optional | colored square + label |
| `assets/icons/skills/` (70) | icon | PNG | 256x256 | skill icons | optional | colored square + label |
| `assets/icons/quest/` (159: `Quest_NN_*.PNG`) | icon | PNG | 256x256 | quest items, scrolls | optional | colored square + label |
| `assets/icons/tech/` (70: `Tech_*.PNG`) | icon | PNG | 256x256 | tech/upgrade icons | optional | colored square + label |
| `assets/icons/buildingmaterialicons/` (105) | icon | PNG | 256x256 | building materials | optional | colored square + label |
| `assets/icons/professions/ProfessionAndCraftIcons/<Profession>/` (639 in 11 subdirs) | icon | PNG | 256x256 | crafting/profession UI | optional | colored square + label |

Random-icon pickers assume numbered sequences (e.g. `Sword_01.PNG` ...
`Sword_66.PNG`); see `getRandomWeaponIcon` / `getRandomArmorIcon` in
`uiassets.lua` for the expected counts per prefix.

Paths referenced by `hunting.lua` that do not exist even in the reference set
(always fall back): `assets/icons/resources/Res_68_cloth.PNG` (the dir is
`resourcesandfood/`), `assets/icons/loot/Feather.png`,
`assets/icons/loot/Bone.png`.

## 5. Card art — `CardsImages/`

See `CardsImages/ASSETS_PLACEHOLDER.md`. Loaded by `cards.lua`
(`Cards.getCardImagePath`).

| path | type | format | dimensions | used for | required? | fallback |
|---|---|---|---|---|---|---|
| `CardsImages/CardDeck/4ColorCards/726X1044/Deck1/T_4ColorCards_Deck1_HighRes_<Suit><Rank>_Diffuse.PNG` (52 files) | card face | PNG | 726x1044 | poker / card minigames | optional | vector-drawn cards (suit glyph + rank text) |

Suits: `Hearts`, `Diamonds`, `Clubs`, `Spades`; ranks `2`–`10`, `J`, `Q`, `K`,
`A` (e.g. `..._HeartsA_Diffuse.PNG`). Wild cards reuse Spades art.

## 6. LPC tilesets / atlases — `assets/lpc/`

2D world rendering (`renderer2d.lua` `ATLAS_CONFIG`, `lpcloader.lua`,
`lpc_tilemap.lua`). **Atlas dimensions and tile grid are load-bearing** —
quads are computed from the sizes below.

| path | type | format | dimensions | used for | required? | fallback |
|---|---|---|---|---|---|---|
| `assets/lpc/tilesets/terrain/terrain_atlas.png` | atlas | PNG | 1024x1024, 32px tiles | terrain rendering | optional | `RENDER_MODE="classic"` colored rects |
| `assets/lpc/tilesets/terrain/terrain.png` | atlas | PNG | 1024x1024 | fallback terrain atlas | optional | colored rects |
| `assets/lpc/tilesets/terrain/base_out_atlas.png` | atlas | PNG | 1024x1024, 32px tiles | outdoor objects, fences, crops | optional | colored rects |
| `assets/lpc/tilesets/walls/lpc-walls/walls.png` | atlas | PNG | 2048x3072, 32px tiles | walls | optional | colored rects |
| `assets/lpc/tilesets/buildings/castle_tiles.png` | atlas | PNG | 512x512, 32px tiles | castle buildings | optional | colored rects |
| `assets/lpc/tilesets/buildings/magecity.png` | atlas | PNG | 256x1450, 32px tiles | city buildings | optional | colored rects |
| `assets/lpc/tilesets/town_objects/cobblestone_paths.png` | atlas | PNG | 512x512, 32px tiles | paths, town objects | optional | colored rects |
| `assets/lpc/tilesets/worldmap/worldmap_tileset.png` | atlas | PNG | 256x336, 16px tiles | world map | optional | colored rects |
| `assets/lpc/tilesets/desert/desert_tileset.png` | atlas | PNG | 208x384, 16px tiles | desert areas | optional | colored rects |
| `assets/lpc/tilesets/vegetation/trees-and-bushes.png` | atlas | PNG | 288x160, variable | trees/bushes | optional | colored rects |
| `assets/lpc/tilesets/stone_house_interior.png` | tileset | PNG | 512x512 | interiors | optional | colored rects |
| `assets/lpc/characters/**` (LPC layer sheets; ref set ~22,400 files) | spritesheet | PNG | 832x1344 (64x64 frames, 9 cols) or per-layer variants | walking character sprites | optional | circle/rect player marker |
| `assets/lpc/creatures/**` (63 files) | spritesheet | PNG | mostly 512x512 | creature sprites | optional | colored marker |
| `assets/lpc/animations/**` (150 files) | spritesheet | PNG | 832x1344 / 1152x768 | weapon & action animations | optional | none (skipped) |

LPC sheets use the standard Universal Spritesheet layout: 64x64 frames, rows =
spellcast/thrust/walk/slash/shoot/hurt, 4 directions (see `lpcloader.lua` and
`assets/lpc/MANIFEST.md` for exact expectations). Only credit/readme text
files from these packs remain tracked.

## 7. Music — `assets/music/`

Streamed, looped, volume from settings (`main.lua` AudioSystem +
`uiassets.lua` `UIAssets.music`). No SFX exist in the game at all —
music is the only audio. Reference tracks are **WAV, 44.1 kHz, 16-bit stereo**.

| path | type | format | dimensions | used for | required? | fallback |
|---|---|---|---|---|---|---|
| `assets/music/01_Horns_Of_War_BattleTrack.WAV` | music | WAV 44.1k/16/stereo | ~12.6 MB | combat | optional | silence |
| `assets/music/SW_Combat_1.WAV` | music | WAV | ~8.7 MB | combat | optional | silence |
| `assets/music/05_Misty_Lands_ExplorationTrack.WAV` | music | WAV | ~9.2 MB | exploration | optional | silence |
| `assets/music/06_Through_The_Lands_-_Atmospheres_Part_I__ExplorationTrack.WAV` | music | WAV | ~37.2 MB | exploration | optional | silence |
| `assets/music/08_Through_The_Lands_-_Atmospheres_Part_II_ExplorationTrack.WAV` | music | WAV | ~33.1 MB | exploration | optional | silence |
| `assets/music/09_The_Journey_Begins__ExplorationTrack.WAV` | music | WAV | ~11.1 MB | exploration, menu | optional | silence |
| `assets/music/10_Through_The_Lands_-_Atmospheres_Part_III_ExplorationTrack.WAV` | music | WAV | ~44.0 MB | exploration | optional | silence |
| `assets/music/SW_Exploration_6.WAV` | music | WAV | ~6.5 MB | exploration | optional | silence |
| `assets/music/SW_Town_1.WAV` | music | WAV | ~9.2 MB | town / cafe / pet sim | optional | silence |
| `assets/music/07_Mountain_Halls__ExplorationTrack.WAV` | music | WAV | ~9.2 MB | menu | optional | silence |
| `WAV_AquaAmbi_loop.WAV`, `WAV_Sonar_Dreams_loop.WAV`, `WAV_Ultramarine_loop.WAV`, `WAV_Vistas_loop.WAV` (repo root) | music | WAV | — | legacy fallback list in `main.lua` | optional | silence (absent even in reference set) |

Any LOVE-supported audio format works if you keep the filenames (OGG at these
paths would need the lists in `main.lua` / `uiassets.lua:390-409` renamed).

## 8. Optional legacy packs — `assetpipeline.lua`

Referenced by the (optional) asset pipeline; **absent even from the reference
set** — these loaders are fully `getInfo`-guarded and currently no-op.

| path | type | format | dimensions | used for | required? | fallback |
|---|---|---|---|---|---|---|
| `assets/dungeon_crawl/Dungeon Crawl Stone Soup Full/` (`dungeon/floor|wall|doors/`, `monster/`, `item/<cat>.png`, `player/base/human_m|f.png`, `effect/`) | tiles/sprites | PNG | 32x32 tiles | dungeon-crawl render mode | optional | not loaded, mode unused |
| `assets/rpg_gui_kit/RPG_GUI_v1.png`, `wood background.png`, `paper background.png` | UI kit | PNG | — | alt GUI skin | optional | not loaded |
| `assets/moderna/` | UI kit | PSD/PNG | — | alt interface | optional | not loaded |

## 9. Fonts

No font files are loaded — all `love.graphics.newFont(size)` calls use LOVE's
built-in default font (`fontcache.lua`, `map_editor.lua`,
`editor_suite/core/fontcache.lua`). Nothing to supply.

---

### Summary

| group | files in reference set | blocking if missing? |
|---|---|---|
| Character portraits | 487 | no — "?" placeholder |
| Backgrounds (root + Explore) | 30 | no — flat colors |
| UI element sheets | 0 (fallback is the shipped look) | no |
| Item icons | 2,667 | no — colored squares |
| Card art | 52 | no — vector cards |
| LPC atlases + sprites | ~22,700 | no — classic render mode |
| Music | 10 | no — silence |
| Legacy packs | 0 | no |

All loaders tolerate missing files; a fresh clone runs the complete game with
placeholder visuals and no audio. Supply files at the paths above (matching
names, and matching grids for atlases) and they are picked up automatically —
**do not commit them**.
