# Changelog — Map Waypoint Bug Fixes

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
  - **CTD-safe by construction.** `UpdateTrackedState` is also called while mappins are being
    destroyed, where dereferencing the mappin crashes the game. Variant + id are cached only in the
    icon path (`UpdateIcon`, mappin guaranteed live); the tracked hook reads those fields and the
    slot id — never the mappin.
  - Scope is every `CustomPositionVariant` (21): the player's own waypoint and mod Set Pins alike.
  - **VERIFIED in-game 2026-08-02** (Testing): marker clears on arrival, both on foot and by
    autodrive. Compiles clean both configs; release-check PASS.

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
  - **VERIFIED in-game 2026-08-02** (A/B, Testing): fix off → phantom HUD/minimap marker
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
- **VERIFIED in-game 2026-07-16.** One-variable A/B on the reproducing stack (worldBuilder + NIF +
  probe), same drill: fix OFF → one Track press dispatches to 5 controllers (4 ghosts); fix ON → 1
  dispatch (0 ghosts), at identical `live=5`. Compiles clean against GOG 2.31 (`redscript-check` PASS).
