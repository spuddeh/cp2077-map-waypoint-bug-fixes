# Changelog — Map Waypoint Bug Fixes

## [1.1.0] - 2026-10-17

- **New: mappin request overflow fix** (`plugin/src/Main.cpp`, RED4ext plugin, first native code in
  the mod). `MappinSystem` queues every mappin add/remove request in a
  `red::MultipleProducersSingleConsumerLockFreeQueue<SharedStorage<IMappinRequest>, 4096>` at
  `MappinSystem + 0x2C0`. Nothing drains it while a save loads; once it is full `Push` returns
  `false`, and every `Register*` caller ignores that, so the request is destroyed while its
  `NewMappinID` has already been returned to script. The fast-travel rebuild
  (`FastTravelSystem.RestoreFastTravelMappins`) is queued last, so fast-travel and NCART pins are
  lost first; a larger overflow takes every load-time pin type.
  - Hooks `Push` (`0x0B4A5D27`) and `Pop` (`0x05FD5C5E`) by address-library hash, covering all 28
    callers. A refused request is moved into a per-queue overflow list; while the list is non-empty,
    new requests go behind it, keeping order. `Pop` hands the oldest kept request to the consumer
    once the ring is empty, releasing the out slot's previous content with
    `SharedStorage<IMappinRequest>::~SharedStorage` (`0xF7D023D1`) as the engine's Pop does. The
    queue destructor (`0xAF3E3A1F`) releases anything still kept.
  - Logs `Recovered N mappin requests the queue refused` through the RED4ext logger when a burst is
    handed back.
  - Verified: Testing, clean load unchanged (82 / 347 / 586 world / minimap / map pins); 300-dummy
    overflow 158 fast-travel pins lost -> 0 (`Recovered 219`); 4,096-dummy teardown overflow world
    map 586 -> 0 without, 586 with (`Recovered 4017`). Gameplay, QuickSave-9 with VendorsXL: missing
    fast-travel pins 95 -> 1 (a mod point with no loaded record), `Recovered 154`.
  - Build: `build.ps1` (VS 2022 Build Tools, CMake + Ninja, header-only RED4ext.SDK from `_source`);
    the DLL is committed at `red4ext/plugins/MapWaypointBugFixes/` and `release-manifest.json` ships
    `red4ext` + `r6`.
- New requirement: RED4ext.

## [1.0.0] — first public release

- First public release. Ships two fixes: `InputLeakFix.reds` (world-map input leak) and
  `ArrivalPhantomFix.reds` (stuck HUD/minimap markers on every path a custom waypoint leaves the
  tracked slot — untrack, switch, on-foot arrival, autodrive arrival). Both verified in-game on
  Testing; `release-check` PASS; compiles clean both configs. The 0.x entries below are internal
  pre-release dev history and were never published.

## [0.3.0] — 2026-08-02

- **New: arrival phantom fix.** `ArrivalPhantomFix.reds`. When a custom waypoint is *reached*
  (walked or driven to), vanilla untracks and destroys it, but never tears down its HUD/minimap
  marker controller — so the marker strands until an Inventory/Stats open or an autosave rebuilds
  the HUD. This hides the stranded widget directly.
  - Marker controllers wrap `UpdateTrackedState` (`BaseMappinBaseController` + the
    `GameplayMappinController` override) and compare their mappin id to the **manually-tracked
    slot** (`GetManuallyTrackedMappinID`). A custom-position pin that is no longer the tracked slot
    gets `SetRootVisible(false)`; the slot drives visibility both ways, so a re-tracked pin returns.
  - **Why `SetRootVisible`, not `SetMappinActive`:** measured that `SetMappinActive(false)` only
    releases the widget when called *before* the untrack (as `PhantomWaypointFix` does on the
    scripted map path). The on-foot untrack is native with no pre-hook, and post-untrack
    deactivation does not release the widget even while the mappin is still registered.
    `SetRootVisible` hides the already-stranded widget directly, so timing is irrelevant.
  - **Never dereferences the mappin in the tracked hook.** `UpdateTrackedState` is also called while mappins are being
    destroyed, where dereferencing the mappin crashes the game. Variant + id are cached only in the
    icon path (`UpdateIcon`, mappin guaranteed live); the tracked hook reads those fields and the
    slot id — never the mappin.
  - Scope is every `CustomPositionVariant` (21): the player's own waypoint and mod Set Pins alike.
  - **Verified in-game** (Testing): marker clears on arrival, both on foot and by
    autodrive. Compiles clean both configs; release-check PASS.
- **Removed `PhantomWaypointFix.reds`** — the arrival fix's slot watch also covers the manual
  untrack/switch path it handled, and covers it *better*: the old fix left a world-map marker until
  the next map open, the slot watch removes it immediately. Verified the manual path is still clean
  with the arrival fix alone. `TryTrackQuestOrSetWaypoint` is no longer wrapped.

## [0.2.0] — 2026-08-02

- Renamed the mod from **World Map Input Leak Fix** to **Map Waypoint Bug Fixes** — an
  umbrella for base-game bugs a player experiences as broken waypoints / mappins / tracked
  locations. The input-leak fix is now one of two fixes it carries.
- **New: phantom waypoint fix.** `@wrapMethod(WorldMapMenuGameController) TryTrackQuestOrSetWaypoint`.
  Cyberpunk strands a mappin's HUD/minimap widget when a mappin that has ever been tracked is
  destroyed (untracking a waypoint, or switching the tracked slot to a quest/POI from the
  world map). The stranded "phantom" marker persists until an event that rebuilds the player
  model (autosave, Inventory, Stats) clears it — so with autosaves off it lingers.
  - The wrap deactivates the manually-tracked mappin *before* vanilla's native
    `UntrackCustomPositionMappin` runs, so its widget tears down through the normal deactivate
    path instead of being orphaned, then re-activates it only if it survived the call.
  - Safe against the exact manual-slot semantics: a destroyed mappin reads back as null and
    stays gone (no ghost route); a survivor is restored, at worst a one-frame flicker.
  - No census, no per-frame work — runs only on the Track-Waypoint press. Signatures verified
    against the RTTI dump. Compiles clean (`redscript-check` PASS, both configs).
  - **Verified in-game** (A/B, Testing): fix off → phantom HUD/minimap marker
    stranded after untrack; fix on → no leftover marker.
- Split the source into `InputLeakFix.reds` and `PhantomWaypointFix.reds` under
  `r6/scripts/MapWaypointBugFixes/`.

## [0.1.0] — 2026-07-16 — Initial (as World Map Input Leak Fix)

- `@wrapMethod(WorldMapMenuGameController) OnUninitialize`: unregisters the four global
  input callbacks (`OnAxisInput`, `OnPressInput`, `OnHoldInput`, `OnReleaseInput`) that
  vanilla registers in `OnEntityAttached` (`worldMap.swift:482-485`) and only ever
  unregisters in `OnEntityDetached` (`:519-522`), which never fires.
- Root cause is a base-game leak: every world-map open leaves a `WorldMapMenuGameController`
  registered in the global input callback list. Harmless alone (leaked controllers are
  dead), but any mod that keeps one alive turns it into a "ghost" that re-fires Track
  Waypoint on a single press → stray waypoints that steal the tracked slot and break the
  GPS trail.
- Reproduced minimally with **worldBuilder - Akiway + Native Interactions Framework**
  loaded together (neither alone). See wiki `concepts/mappin-system-reference` §6.
- Zero dependencies; pure redscript; `@wrapMethod` for compatibility.
- **Verified in-game.** One-variable A/B on the reproducing stack (worldBuilder + NIF +
  probe), same drill: fix OFF → one Track press dispatches to 5 controllers (4 ghosts); fix ON → 1
  dispatch (0 ghosts), at identical `live=5`. Compiles clean against GOG 2.31 (`redscript-check` PASS).
