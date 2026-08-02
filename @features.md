# Features — Map Waypoint Bug Fixes

An umbrella mod for base-game bugs a player experiences as broken waypoints / mappins /
tracked locations. Pure redscript, zero dependencies.

## Implemented

- **Input leak fix** — unregister the world map's four global input callbacks on
  `OnUninitialize`, closing the base-game leak that leaves `WorldMapMenuGameController`
  instances registered after the map closes. Prevents leaked controllers from being
  dispatched as "ghosts" that fire stray Track-Waypoint actions. *(Verified in-game
  2026-07-16.)*
- **Phantom waypoint fix** — deactivate the manually-tracked mappin before vanilla destroys
  it in `TryTrackQuestOrSetWaypoint`, so its HUD/minimap widget is not stranded when a
  waypoint is untracked or the tracked slot is switched to a quest/POI; re-activate it only
  if it survived. *(Verified in-game 2026-08-02, A/B on Testing.)*
- **Arrival phantom fix** — when a custom waypoint is reached and vanilla destroys it, its
  HUD/minimap marker controller is not torn down and the widget strands. Hides the marker on
  the tracked→untracked edge (`UpdateTrackedState`), before the destroy; CTD-safe (variant
  cached in the icon path, never dereferenced in the tracked hook). Covers every variant-21
  custom-position pin. *(Compiles clean; pending in-game verify.)*

## Planned

- If other world-map / mappin base-game bugs that read as broken waypoints turn up, they
  belong here as additional wraps first documented in this list.
