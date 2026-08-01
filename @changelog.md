# Changelog — Map Waypoint Bug Fixes

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
  - **Not yet verified in-game.**
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
