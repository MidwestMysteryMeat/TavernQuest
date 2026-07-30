# Architecture

Tavern Quest is a LÖVE 11.4 game. 81 Lua modules, ~101k lines. This document is
the map: what the layers are, how they talk to each other, and which patterns are
load-bearing versus which are legacy you should not copy.

---

## Boot and the state machine

```
conf.lua        sets the window, detects `--test`
  └── main.lua  owns the love.* callbacks and the shared globals
        ├── stateModules   table-driven dispatch, one entry per screen
        └── overlays       PauseMenu, Cutscenes, InteractiveTutorial, KnowledgeCenter
```

`main.lua` is the only place that defines cross-module globals. Everything it
publishes is listed in `.luacheckrc` under `globals`:

| Global | Meaning |
|---|---|
| `GameState` | `{ current = <state name>, player }` — `current` is always a key of `stateModules` |
| `PlayerData` | the active save slot, in memory |
| `AudioSystem` | music playback |
| `FPSCounter` | F3 overlay |
| `RENDER_MODE` | `"sprite"` or `"classic"`, toggled with F4 (owned by `renderer2d.lua`) |

### States

A state module is a plain table with `init`, `update(dt)` and `draw`, optionally
`mousepressed`, `mousereleased`, `wheelmoved`, `keypressed`, `textinput`.
`main.lua` forwards each `love.*` callback to `stateModules[GameState.current]`
and skips anything the module does not implement.

The registered states are:

```
menu        credits     statspage   textrpg     lore        tutorial
fishing     forge       hunting     wizardtower alchemist
```

`textrpg` is the hub — it is what "Tavern Quest" on the main menu launches, and
almost everything the player does happens under it.

To add a state: create the module, add one line to `stateModules`, and add its
name to `STATE_MODULES` in `tests/run.lua`. The test suite fails if a registered
state is missing `init`/`update`/`draw` — that check is what caught
`prison_escape` being registered as a state when it is really a subsystem.

---

## The text-RPG layer (`rpg_*.lua`)

This is the bulk of the codebase (~50k lines) and it does **not** follow the
state-module pattern. `textrpg.lua` is the single registered state; the `rpg_*`
files are slices of it, split by concern rather than by lifecycle:

| Module | Concern |
|---|---|
| `rpg_core` | update loop, phase machine, shared draw entry |
| `rpg_input` | every click and key for every phase |
| `rpg_draw_world`, `rpg_draw_creation` | rendering |
| `rpg_data` | static data tables (races, classes, portraits, dialogue) |
| `rpg_town`, `rpg_world`, `rpg_travel`, `rpg_dungeon` | locations and movement |
| `rpg_npc`, `rpg_dialogue` | NPCs, schedules, conversation |
| `rpg_combat`, `rpg_stats`, `rpg_karma` | combat, progression, crime/faction standing |
| `rpg_save` | serialises the RPG state into `PlayerData.textRPG` |
| `rpg_vampire` | vampire epidemic events |

### ⚠️ The `F` dispatch table — legacy, do not extend

`textrpg.lua` builds a table `F` of shared functions and then installs a
metatable on the global environment:

```lua
-- textrpg.lua
setmetatable(_G, {
    __index = function(t, k)
        if F[k] then return F[k] end
        return rawget(t, k)
    end
})
```

Sibling `rpg_*` modules therefore call injected functions as if they were bare
globals — `log(...)`, `calculateStats()`, `gainXP(...)`, `movePlayer(...)`.

This works, but it is the single worst pattern in the codebase:

- static analysis cannot see through it, so every typo becomes a silent nil
  lookup at runtime instead of a load-time error;
- it makes module boundaries fictional;
- it means load order matters in ways nothing documents.

The names actually used this way are enumerated in `.luacheckrc` under
`read_globals`. **Treat that list as a ceiling, not a foundation** — new code
should take `F` as an explicit parameter (as `rpg_karma.register(state, F)`
already does) and the list should shrink over time.

---

## Save system

`savesystem.lua` owns three slots (`save_slot_N.lua` in the LÖVE save
directory). A slot is a Lua chunk returning a table; it is loaded with
`setfenv(chunk, {})` so a hand-edited or corrupted save cannot execute code.

- `SaveSystem.defaultPlayerData` is the schema. Add fields here, not ad hoc.
- `SaveSystem.getSlotInfo(n)` reads a slot without loading it, for the
  save/load UI. The RPG character lives at `data.textRPG.player`.
- `SaveSystem.describeSlot(info)` formats the one-line summary
  (`"Bran  -  Level 7 Ranger"`). Both the pause menu and the options screen use
  it, so slot rendering stays consistent.

The RPG layer round-trips through `rpg_save.lua`, which writes into
`PlayerData.textRPG*`. `PlayerData.coins` is the authoritative currency; the
RPG's `state.player.gold` is synced to it on save and load.

---

## Rendering

Two paths, switched by `RENDER_MODE` (F4):

- **`sprite`** — `lpcloader` + `renderer2d` + `spritemanager` + `tile_quad_maps`
  draw LPC atlases through `camera2d`.
- **`classic`** — text/shape fallback.

Sprite mode degrades cleanly: with no art present every atlas fails to load, the
renderer reports `0 atlases loaded`, and the game still boots and plays. That is
by design — see the licensing note in the README.

`assetpipeline.lua` is the single asset loader (it absorbed the old
`assetconfig`/`assetloader`/`assetscanner` modules; the compatibility shims for
those names were deleted on this branch).

---

## NPC dialogue

`chatbot_fallback.lua` is a hand-rolled keyword/synonym matcher with 51 NPC
profiles under `chatbot/profiles/`. **It is not an LLM** — no model, no network,
fully offline and deterministic.

`chatbot_bridge.lua` will hand off to the optional Python engine in `chatbot/`
over file IPC if it is running, and otherwise uses the Lua engine. The Lua path
is the default and the supported one.

> Gotcha: `chatbot_fallback` has retry loops that spin forever under a permissive
> `love` stub. Do not sweep-require modules with a stubbed `love`; boot through
> LÖVE (`love . --test`) instead. This is why the test suite runs inside LÖVE
> rather than under bare `lua`.

---

## Conventions

**Declare before you call.** Lua resolves an undeclared name to a global at the
call site. A `local function` defined *below* its first use is not in scope
there, so the call silently becomes a nil global and crashes at runtime. This
shipped twice (`lore.lua`, `fishing.lua` — see `BUGS_FOUND.md`). If a function
must be defined after its call site, forward-declare it:

```lua
local drawOverview, drawPlaces      -- forward declarations
...
function Lore.draw() ... drawOverview(...) ... end
...
drawOverview = function(x, y, w, h) ... end
```

**No new globals.** If you genuinely need one, add it to `.luacheckrc` with a
comment saying who owns it. `luacheck` fails on undeclared globals precisely so
this stays a deliberate decision.

**Avoid `if Module and Module.fn then`** for modules you could simply `require`.
That idiom turns "I forgot the import" into silently dead code rather than a
loud error — exactly what happened in `interactivetutorial.lua`.

**Lazy-require inside functions** only to break a genuine cycle. Otherwise
require at the top of the file.

---

## Checks

```
luacheck .          # 0 errors required
love . --test       # headless suite, exit 0 required
love .              # boots to the main menu
```

`tests/run.lua` covers: every registered state exposes its callbacks, every
support module loads, the save schema has no leftover card-game fields, removed
modules stay removed, portrait mappings cover all races and classes, and
settlement placement validation accepts/rejects correctly.
