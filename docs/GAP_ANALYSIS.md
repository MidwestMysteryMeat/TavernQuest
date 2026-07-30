# Tavern Quest — Gap Analysis

_Rebased 2026-07-30 for the `redesign/slim` branch: 81 Lua files, ~101.5k lines,
`luacheck` 0 errors, 78 test assertions passing, clean boot to the main menu._

The pre-slim version of this document assessed 147 files including an arcade
layer that no longer exists. Anything it recommended for poker, the TCG, the
stock market, the cafe minigame or the editor suite is moot — those were removed.
See the README for the full cut list.

## What the game already has (do not rebuild)

6 classes / 20 races / 12 backgrounds. Turn-based text combat **and** FFT-style
tactical grid combat (height, flanking, 14 map types, 12 status effects).
Procedural world and town generation including desert dungeons and hollow earth.
Prison-escape opening scenario. Fishing (50 fish, 6 tiers, trophy variants),
farming, hunting, alchemy, forge, wizard tower, crafting. Property system with
settlements and employees. Stealth, karma with crime and factions, vampire
infiltration, luminary patrols, rumours. Day/night, weather, auto-travel and
fast travel. Quest journal, achievements, interactive tutorials, knowledge
centre, glossary. Chatbot NPCs with a 51-profile offline Lua engine. LPC sprite
pipeline. Save system with three slots. `autoplay.lua`, an AI that plays the game
toward goals.

---

## A. The one glaring content gap: audio

**10 music tracks. Zero sound effects.** A game with tactical combat, fishing
reels, forges and taverns plays silent apart from looped exploration music. This
is the highest-impact item and it is pure content work, not architecture — 26
modules already reference sound code paths, so the play sites largely exist.

- **SFX pass:** UI click/hover, combat hits/blocks/spells, fishing
  cast/splash/reel, forge hammer, coin/shop, footsteps by terrain, ambient
  tavern chatter. Freesound and Kenney packs cover most of it.
- **Format:** music ships as WAV (one track is 46 MB). Converting to OGG is
  roughly 10:1, is natively streamable in LÖVE, and takes ~400 MB off the
  working tree.

## B. Gameplay and UX gaps

### B1. Autosave — HIGH, cheap

`savesystem.lua` has three slots but nothing saves automatically. A crash or
force-quit eats the session. Add interval saves plus on-scene-transition saves to
a dedicated rotating slot. The save schema was cleaned on this branch, so this is
a good moment to do it.

### B2. Input: key rebinding and gamepad — MEDIUM

No rebinding code, and `t.modules.joystick = false` in `conf.lua` switches
controller support off entirely. Table stakes for a Steam-viable RPG. The options
menu already exists to host the UI.

### B3. Tavern relationship mechanics — MEDIUM, and it is the identity feature

Romance and relationships appear only in lore text; there is no favour or
friendship mechanic. For a game named Tavern Quest, Stardew-style regulars
(favour tiers, gifts, dialogue unlocked by standing) is the thematic centrepiece
gap — and the 51-profile chatbot engine is an asset nothing else in the genre
has. Favour tiers gating dialogue depth is the obvious first cut.

### B4. Tavern activity loop — NEW GAP, created by this branch

The cafe minigame was the tavern's only active-play loop, and it was cut as part
of the arcade layer. Tavern ownership, employees and passive income still work,
but "work a shift" no longer exists — the tavern interior now offers only *Talk*
and *Rent Room*.

If tavern management is meant to stay central, this needs a replacement built
inside the RPG layer rather than as a separate arcade state: a shift resolved as
a text scene with skill checks, feeding karma, reputation and NPC standing.
Pairs naturally with B3.

### B5. Lighting — LOW-MEDIUM

The day/night cycle exists but is a colour tint; there are no shaders. One canvas
plus a multiply-blend light layer (torches, forge glow, tavern windows) would
transform night scenes for roughly a day of work.

### B6. Steam packaging — LATER

No integration. Port the pattern from MMOLite, which already solved Steam libs
and `steamcloud.lua` for LÖVE.

## C. Engineering gaps

### C1. Soak testing via `autoplay.lua` — the cheap win

`tests/run.lua` now covers module loading, the save schema, data integrity and
placement validation — but nothing exercises gameplay. `autoplay.lua` is an AI
that already plays the game toward goals. Wiring it to a soak runner (boot, run
N minutes, assert no errors and invariants like HP in bounds, gold ≥ 0,
inventory weight ≤ capacity) would give integration coverage most indie projects
never get. This is the single highest-value engineering item.

### C2. Retire the `_G` metatable — MEDIUM, incremental

`textrpg.lua` installs a metatable on `_G` that falls back to its `F` dispatch
table, so sibling `rpg_*` modules call injected functions as bare globals. It
defeats static analysis: every typo becomes a silent runtime nil lookup instead
of a load-time error. Two of the ten bugs fixed on this branch were of exactly
that shape.

The names relied on are enumerated in `.luacheckrc` under `read_globals`. Shrink
that list module by module — pass `F` explicitly, as `rpg_karma.register(state, F)`
already does. Do not add to it.

### C3. Split the two god-files — MEDIUM

`rpg_draw_world.lua` (~6.7k lines) and `rpg_input.lua` (~5.1k lines) are the
largest files by a wide margin, and both are flat phase dispatchers. Splitting
per phase (town, world, dungeon, combat, creation) would make them navigable and
would let the remaining shadowing warnings be cleaned safely.

### C4. Clear the remaining lint debt — LOW

~65 `luacheck` warnings remain, all `W311`/`W231` dead stores. Individually
trivial; worth clearing so the count stays at zero and future warnings are
signal.

### C5. Agent conventions file — LOW

No `CLAUDE.md`. `docs/ARCHITECTURE.md` now covers most of what one would say;
a short conventions file pointing at it, plus the two check commands, would
finish the job.

## Suggested sequencing

1. **A** — audio SFX pass and OGG conversion; biggest felt improvement per hour
2. **B1 + C1** — autosave, and the autoplay soak harness; protect players and the codebase
3. **B4 + B3** — restore a tavern activity loop and build relationships on top of it
4. **B2** — rebinding and gamepad; Steam prerequisite
5. **C2 + C3** — retire the `_G` metatable, split the god-files
6. **B5 → B6** — lighting, then Steam packaging
