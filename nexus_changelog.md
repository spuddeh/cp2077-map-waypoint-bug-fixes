### [Unreleased - v0.2.0]

- Renamed to **Map Waypoint Bug Fixes**. It now fixes two base-game waypoint bugs, not one.
- **New:** fixes a base-game bug where a map marker can get stuck on your HUD and minimap
  after you untrack a waypoint or switch your tracked location to a quest or point of
  interest. The stuck marker normally only clears after an autosave or opening your
  Inventory or Stats — so with autosaves off it can hang around. This makes the marker clean
  up the moment it should. No dependencies, no gameplay change.

### [Unreleased - v0.1.0]

- Fixes a base-game bug where opening the world map repeatedly can leave "ghost" copies of
  the map running in the background. With certain other mods installed, pressing Track
  Waypoint then drops several stray waypoints at once, one of which silently steals your
  tracked marker and kills the GPS route line.
- The fix cleans up the map's input hooks every time you close it — exactly what the game
  intended to do but never did. No dependencies, safe with everything, no gameplay change.
