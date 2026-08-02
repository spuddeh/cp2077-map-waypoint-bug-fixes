# Features — Map Waypoint Bug Fixes

An umbrella mod for base-game bugs a player experiences as broken waypoints / mappins /
tracked locations. Pure redscript, zero dependencies.

## Implemented

- **Input leak fix** — unregister the world map's four global input callbacks on
  `OnUninitialize`, closing the base-game leak that leaves `WorldMapMenuGameController`
  instances registered after the map closes. Prevents leaked controllers from being
  dispatched as "ghosts" that fire stray Track-Waypoint actions. *(Verified in-game
  2026-07-16.)*
- **Stranded-marker fix** — whenever a custom waypoint leaves the tracked slot and is destroyed —
  untracked from the map, its slot switched to a quest/POI, or **reached** on foot or by autodrive —
  its HUD/minimap marker controller is not torn down and the widget strands until Inventory/Stats or
  an autosave rebuilds the HUD. Marker controllers watch the manually-tracked slot in
  `UpdateTrackedState` and `SetRootVisible` their widget off the instant their pin is no longer the
  slot. CTD-safe (variant/id cached in the icon path, never dereferenced in the tracked hook). Covers
  every variant-21 custom-position pin — the player's own and mod Set Pins alike.
  *(Verified in-game 2026-08-02, Testing — untrack, switch, foot arrival, autodrive arrival, SLM pin.)*

## Planned

- If other world-map / mappin base-game bugs that read as broken waypoints turn up, they
  belong here as additional wraps first documented in this list.
