# Bugs found and fixed — 2026-07-30 audit

Ten pre-existing bugs, surfaced by adding `luacheck` and a test suite to the
codebase for the first time. Two are guaranteed crashes on code paths a player
can reach.

**This branch (`fix/latent-bugs`) contains the fixes and nothing else** — no
scope changes, no file deletions. The companion branch `redesign/slim` contains
the same fixes plus a large scope cut; if you merge that one, you get these too.

Every bug was verified against `main` with
`git show main:<file> | grep -c '<broken line>'` before being fixed, and the two
crashes were confirmed by forcing the affected screens open, reverting the fix to
reproduce the crash, then re-applying it.

Severity key:

- **Crash** — throws at runtime, kills the frame
- **Silent** — wrong behaviour, no error
- **Latent** — broken, but the code path is currently unreachable

---

## 1. `lore.lua` — tab renderers called before they are declared

| | |
|---|---|
| **Severity** | Crash |
| **Fixed** | `lore.lua` — forward-declared the seven functions above `Lore.draw` |
| **Was on `main`** | Yes — fixed by this branch |

`Lore.draw` (was line 763) dispatches to `drawOverview`, `drawPlaces`,
`drawPeople`, `drawFactions`, `drawHistory`, `drawMagic` and `getContentHeight`.
All seven were declared with `local function` *below* that call site (line 867+),
so at the call site the names were not in lexical scope and resolved to nil
globals:

```
lore.lua:824: attempt to call global 'drawOverview' (a nil value)
```

Opening the Lore screen crashes instantly. On `main` this is masked because the
Lore button is hidden behind a dev-mode password (`menu.lua:179`,
`buttons[3].devOnly = true`) — so it is a **latent crash on `main`** and only
became reachable here when the dev gate was removed.

**Fix:** `local drawOverview, drawPlaces, ... , getContentHeight` before
`Lore.init`, and changed each definition from `local function X(` to
`X = function(`.

---

## 2. `fishing.lua` — overlay renderers called before they are declared

| | |
|---|---|
| **Severity** | Crash |
| **Fixed** | `fishing.lua` — forward-declared the three overlays above `Fishing.draw` |
| **Was on `main`** | Yes — fixed by this branch |

Identical bug class to #1. `Fishing.draw` calls `drawShopOverlay`,
`drawCollectionOverlay` and `drawEmployeesOverlay`; all three are declared
`local function` afterwards.

Unlike the Lore case this is **reachable in normal play on `main`** — the shop
overlay is opened by an ordinary in-game button (`state.showShop = true`,
`fishing.lua:439` and the toggle at line 3001). Opening the fishing shop should
crash.

---

## 3. `hunting.lua` — call to a field that does not exist

| | |
|---|---|
| **Severity** | Crash |
| **Fixed** | `hunting.lua:846` |
| **Was on `main`** | Yes — fixed by this branch |

```lua
local locW = math.max(150, love.graphics.UI.fonts.get():getWidth(locName) + 30)
```

There is no `love.graphics.UI`. The line above it already set the font via
`love.graphics.setFont(UI.fonts.get(16))`, so the intent was to measure with the
current font.

**Fix:** `love.graphics.getFont():getWidth(locName)`.

---

## 4. `rpg_travel.lua` — operator precedence inverts a guard

| | |
|---|---|
| **Severity** | Silent |
| **Fixed** | `rpg_travel.lua:541` |
| **Was on `main`** | Yes — fixed by this branch |

```lua
if town and not town.type == "capital" then  -- Not in capitals
```

Lua parses this as `(not town.type) == "capital"`. `not town.type` is a boolean,
which is never equal to the string `"capital"`, so the condition is **always
false** and `RumorSystem.spawnSerialKiller` is never called. The serial-killer
event has therefore never fired in any build.

**Fix:** `if town and town.type ~= "capital" then`.

---

## 5. `rpg_npc.lua` — quest-marker loop exits on the first iteration

| | |
|---|---|
| **Severity** | Silent |
| **Fixed** | `rpg_npc.lua`, in the NPC quest-marker helper |
| **Was on `main`** | Yes — fixed by this branch |

```lua
for _, questInfo in ipairs(availableQuests) do
    local meetsReq, reason = F.checkQuestRequirements(questInfo, npc.id)
    if meetsReq then
        return "❗"
    else
        return "?"      -- <-- returns on iteration 1 regardless
    end
end
```

Both branches return, so only the *first* quest is ever considered. An NPC whose
first quest is locked but whose second is available shows `?` instead of `❗`.
`reason` was also assigned and never used.

**Fix:** scan the whole list, return `❗` on the first qualifying quest, and only
fall back to `?` after the loop if at least one locked quest was seen.

---

## 6. `settlement_expansion.lua` — undefined variable in the building-cap check

| | |
|---|---|
| **Severity** | Silent |
| **Fixed** | `settlement_expansion.lua`, `validateBuildingPlacement` |
| **Was on `main`** | Yes — fixed by this branch |

```lua
local settlement = state.player.properties.settlements[x .. "_" .. y] or
                  state.player.properties.settlements[(claim and claim.x or 0) .. "_" .. (claim and claim.y or 0)]
```

`validateBuildingPlacement(state, PropertySystem, grid, x, y, footprint, buildingType)`
has no `claim` parameter and no `claim` upvalue — it was copy-pasted from
`placeBuilding`, which does. `claim` is always nil, so the second lookup is
always `settlements["0_0"]`.

The first lookup is wrong too: `x, y` are *tile coordinates inside the grid*,
while `properties.settlements` is keyed by **claim key**. Both lookups miss, so
`settlement` is always nil and **the settlement building cap is never enforced** —
players can exceed `settlement.maxBuildings` without limit.

**Fix:** added an optional trailing `claimKey` parameter, looked up
`settlements[claimKey]`, and threaded it through both call sites
(`SettlementExpansion.placeBuilding` and `PropertySystem.validateBuildingPlacement`).
When no claim key is supplied the cap check is skipped explicitly rather than by
accident.

---

## 7. `assetpipeline.lua` — load-bearing variable shadowing

| | |
|---|---|
| **Severity** | Latent |
| **Fixed** | `assetpipeline.lua`, `AssetLoader.loadPlayer` |
| **Was on `main`** | Yes — fixed by this branch |

```lua
local basePath = LOADER_PATHS.dungeonCrawl .. "player/"
...
local basePath = basePath .. "base/"     -- redeclares in the same scope
```

Functionally correct today, but fragile: the second declaration silently depends
on shadowing the first, and any edit that separates them breaks sprite loading.
Renaming the second to `bodyPath` immediately exposed a real inconsistency two
lines down, where the female sprite was loaded from `basePath` while its
existence was checked against the `base/` path.

**Fix:** renamed to `bodyPath` and corrected the mismatched load path.

---

## 8. `interactivetutorial.lua` — guards on modules that were never imported

| | |
|---|---|
| **Severity** | Silent |
| **Fixed** | `interactivetutorial.lua` — added the two `require`s |
| **Was on `main`** | Yes — fixed by this branch |

```lua
if PauseMenu and PauseMenu.isActive() then      -- line 312
if KnowledgeCenter and KnowledgeCenter.openToEntry then   -- line 678
```

Neither module was required in this file, and neither is a global. Both
conditions are permanently false, so:

- the tutorial never pauses when the pause menu opens, and
- tutorial steps with a `kcLink` silently do nothing instead of opening the
  Knowledge Center.

The `X and X.y` idiom hid it — without the guard it would have crashed loudly on
day one.

**Fix:** `require("pausemenu")` / `require("knowledgecenter")` at the top (no
require cycle — neither module imports the tutorial), and dropped the now
redundant nil guards.

---

## 9. `rpg_data.lua` — duplicate keys in `portraitMappings`

| | |
|---|---|
| **Severity** | Silent (cosmetic) |
| **Fixed** | `rpg_data.lua` — removed 5 later duplicates |
| **Was on `main`** | Yes — fixed by this branch |

`dwarf`, `orc`, `goblin`, `gnome` and `skeleton_mage` were each assigned twice in
the same table constructor. In Lua the last assignment wins, so the earlier
entries were dead. All five pairs had identical values, so there is no behaviour
change — but the duplication invites a future edit to the "wrong" copy that then
gets silently discarded.

**Fix:** deleted the later duplicate of each.

**Still open:** `skeleton_mage` maps to `"Monster_SkeletonMage"` while every
neighbouring undead maps to `"Monsters/Undead/..."`. That looks like a missing
path prefix, but it cannot be confirmed without the (gitignored) art, so it was
left alone.

---

## 10. `stealth_system.lua` — negated equality

| | |
|---|---|
| **Severity** | Cosmetic |
| **Fixed** | `stealth_system.lua:736` |
| **Was on `main`** | Yes — fixed by this branch |

`if not (timeOfDay == "day")` → `if timeOfDay ~= "day"`. Behaviour is identical;
changed for readability and to clear the last `W581`.

---

## Design defects (not crashes, but wrong)

### `prison_escape` was registered as a top-level game state

`main.lua` listed `prison_escape = PrisonEscape` in `stateModules`, but the
module has no `update` and no `draw` — it is a subsystem driven from `rpg_core`
(guard patrols) and `rpg_combat`. Nothing ever sets
`GameState.current = "prison_escape"`, so entering it would have rendered a blank
screen. Caught by the new test suite's "every registered state exposes
init/update/draw" check.

**Fixed:** unregistered it from `stateModules`; it stays a subsystem.
**Was on `main`:** yes — fixed by this branch.

### Dev-mode cheat with a hardcoded password

`menu.lua` on `main` contains a password prompt (`"Helios"`) that, when entered,
sets `PlayerData.coins = 999999999` and reveals the Lore button. Gating a normal
content screen behind a cheat code is why bug #1 went unnoticed.

**NOT fixed here.** Removing it is a scope/design change, not a bug fix, so it is
out of this branch's remit — `redesign/slim` removes it. Worth deciding on: while
the gate stays, the Lore screen stays unreachable in normal play even though the
crash behind it is now fixed.

---

## Verification

Every fix on this branch was checked with:

- `luajit -bl <file>` on all 117 Lua files — 0 syntax errors
- `lovec .` — clean boot to the main menu, no errors in the log
- the two crashes reproduced and then confirmed fixed by forcing
  `GameState.current` to `"lore"` and `"fishing"` at load and watching a full
  draw cycle of each

The linter and test suite that surfaced these bugs live on `redesign/slim`
(`.luacheckrc`, `tests/run.lua`). They are deliberately **not** on this branch,
which is fixes-only and intended to be trivially reviewable. Adopting them is
the single highest-value follow-up — without a gate, this bug class comes back.
