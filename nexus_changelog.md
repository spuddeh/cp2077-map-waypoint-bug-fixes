### [Unreleased - v0.1.0]

- Fixes a base-game bug where opening the world map repeatedly can leave "ghost" copies of
  the map running in the background. With certain other mods installed, pressing Track
  Waypoint then drops several stray waypoints at once, one of which silently steals your
  tracked marker and kills the GPS route line.
- The fix cleans up the map's input hooks every time you close it — exactly what the game
  intended to do but never did. No dependencies, safe with everything, no gameplay change.
