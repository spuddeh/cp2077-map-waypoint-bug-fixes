# Features — Map Waypoint Bug Fixes

An umbrella mod for base-game bugs a player experiences as broken waypoints / mappins /
tracked locations. Redscript plus one RED4ext plugin; requires RED4ext.

## Implemented

- **Mappin request overflow fix** (RED4ext plugin, 1.1.0): the 4,096-slot mappin request queue
  fills while a save loads and refused requests are dropped unchecked, so fast-travel and metro pins
  (and, under heavier load, every load-time pin type) never appear. The plugin keeps every refused
  request and hands them to the consumer, in order, once the queue drains.
  *(Verified in Testing with 300- and 4,096-dummy overflows, and on the Gameplay save.)*

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
  *(Verified in-game on Testing: untrack, switch, foot arrival, autodrive arrival, SLM pin.)*

## Planned

- If other world-map / mappin base-game bugs that read as broken waypoints turn up, they
  belong here as additional wraps first documented in this list.
