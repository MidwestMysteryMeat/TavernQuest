# Tavern Quest

**A single-player fantasy RPG in LÖVE 11.4 — a text-adventure layer over a 2D
sprite overworld, with FFT-style tactical grid combat and offline keyword-driven
NPC conversation.**

> This is the `redesign/slim` branch. It cuts Tavern Quest down to one coherent
> RPG: 147 Lua files became 81, 162k lines became 101k, and the project has a
> linter and a test suite for the first time. See
> [What changed](#what-changed-on-this-branch).

## What it is

Create a character (6 classes, 20 races, 12 backgrounds) and play a hybrid of
narrative text scenes and a tile-based overworld. Two combat systems — turn-based
text combat, and a tactical grid with height, flanking, status effects and 14
battlefield types.

Around that sits a connected set of RPG systems: procedural world and town
generation, day/night and weather, karma with crime and factions, stealth, a
vampire epidemic event chain, property and settlement ownership with employees,
prison escape, and crafting that spans fishing, hunting, farming, the forge, the
alchemist's lab and the wizard tower.

NPCs run on a hand-rolled keyword/synonym matcher with 51 dialogue profiles.
**It is not an LLM** — no model, no API, no network. It runs offline and
deterministically.

## Running it

Requires [LÖVE 11.4](https://love2d.org/).

```sh
love .              # play
lovec .             # play with a console (Windows), for the boot log
love . --test       # headless test suite, exits 0 on pass
luacheck .          # static analysis, must report 0 errors
```

> **No art or audio is bundled** — see [Licensing](#licensing). The game boots
> and plays with placeholder visuals and silence; the renderer reports
> `0 atlases loaded` and carries on. Supply your own sprites per
> `ASSETS_NEEDED.md` to restore graphics.

## Status

Boots clean, `luacheck` reports 0 warnings / 0 errors, and 89 test assertions
pass.

**Honest caveats:**

- **Almost no audio.** 10 music tracks, zero sound effects.
- **Lightly playtested.** The boot path, module graph and save schema are
  verified; deep gameplay is not. Expect rough edges.
- **No autosave**, no key rebinding, gamepad disabled.

Roadmap: [`docs/GAP_ANALYSIS.md`](docs/GAP_ANALYSIS.md).

## What changed on this branch

| | `main` | `redesign/slim` |
|---|---|---|
| Lua files | 147 | 81 |
| Lua lines | 162,265 | ~101,500 |
| Unreachable modules | 39 (35k lines) | 0 |
| Docs | 59 files, 36k lines | 19 files (16 of them lore) |
| Linter | none | `luacheck`, 0 warnings / 0 errors |
| Tests | none | 89 assertions |

**Removed as dead code** — never reachable from `main.lua`:

- `editor_suite/` — a 30-file, 23k-line standalone editor app with its own
  `main.lua` and `conf.lua`, wired to nothing
- 8 orphaned modules (`lore_books`, `loremanager`, `npcmanager`,
  `charactercreator`, `charactercustomizer`, `characterpresets`,
  `combat_ui_simple`, `textrpgutils`)
- 6 deprecated compatibility shims left over from earlier merges

**Removed as scope** — a bolted-on arcade layer that shared nothing with the RPG:

- the Balatro-style poker stack (poker, jokers, deck builder, loot boxes,
  endless mode, card collection ×5, trading cards, card AI)
- stock market, pet sim, cafe minigame, in-game map editor
- the "Game Modes" arcade browser and favourites panel in the main menu
- a dev-mode cheat with a hardcoded password that also gated the Lore screen

Everything cut is still on `main` and in git history; nothing is lost.

**Kept:** character creation, the text RPG, the 2D overworld, both combat
systems, chatbot NPCs, fishing / forge / hunting / alchemy / farming / crafting,
karma, stealth, property and settlements, lore, and the full worldbuilding
corpus under `docs/lore/`.

**Fixed:** 10 pre-existing bugs surfaced by the linter and test suite, including
two guaranteed crashes. All 10 are still present on `main`. Each one is written
up with severity, root cause and fix in
[`docs/BUGS_FOUND.md`](docs/BUGS_FOUND.md).

## Layout

```
main.lua              love.* callbacks, shared globals, state dispatch
conf.lua              window config, --test detection
menu.lua              title screen
textrpg.lua           the hub state; everything else hangs off it
rpg_*.lua             the text-RPG layer (~50k lines)
tactical_combat*.lua  FFT-style grid combat
chatbot_*.lua         offline NPC dialogue engine
tests/run.lua         headless test suite
docs/ARCHITECTURE.md  how the layers fit together — read this first
docs/lore/            worldbuilding corpus (16 files)
chatbot/              optional Python dialogue backend
```

New here? Start with [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md). It documents
the state machine, the save schema, and the one pattern you should not copy (a
`_G` metatable that makes static analysis lie to you).

## Contributing

Before you commit:

```sh
luacheck .          # must be 0 errors
love . --test       # must exit 0
```

Two conventions matter more than the rest, both because breaking them has already
shipped bugs:

1. **Forward-declare any local function you call before defining it.** Lua
   resolves it as a nil global otherwise, and it crashes at runtime.
2. **Don't add globals.** If you must, declare them in `.luacheckrc` with a
   comment naming the owner.

## AI development note

Developed with AI assistance — Anthropic Claude (Claude Code) for implementation
and OpenAI Codex for review. Human direction owns the design, the worldbuilding
corpus and the priorities.

## Licensing

Project code is under the **[Apache License 2.0](LICENSE)** — free to use,
modify, fork and build on, commercially or not.

**Credit is required.** Apache-2.0 §4(c)–(d) obliges you to keep the copyright
notice and reproduce [`NOTICE`](NOTICE) in anything you distribute, including
binaries and hosted builds. Credit as `TavernQuest by MysteryMeat`
(https://github.com/MidwestMysteryMeat/TavernQuest) in your credits screen, About
box, or docs. The project name and the MysteryMeat name are not licensed for
endorsement or promotion (§6).

Apache-2.0 covers **the project's own code only.**

### Art and audio

This repo intentionally contains **no art or audio**. Those are third-party packs
(LPC sprite sets, tilesets, music) licensed to the project owner and stripped
from version control — see `assets/ASSETS_PLACEHOLDER.md`.

The attribution and licence files that ship alongside those packs **are** tracked
under `assets/`, because several are CC-BY or GPL and require their notice to
travel with the work. Read them before redistributing anything built on top.

---

<sub>Support development — <a href="https://ko-fi.com/midwestmysterymeat">Ko-fi</a></sub>
