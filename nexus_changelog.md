### [1.0.0] first public release

Fixes two base-game bugs you see as broken waypoints and stuck map markers:

- **Stuck HUD and minimap markers.** A custom waypoint's marker can stay on your HUD and minimap
  after the waypoint is gone: after you reach it (on foot or by autodrive), un-track it from the
  map, or switch your tracked location to a quest or point of interest. Vanilla only clears it on
  an Inventory or Stats open, or an autosave. This clears it the moment the waypoint is gone.
- **World-map input leak.** Opening the world map repeatedly leaves "ghost" copies of the map
  controller running in the background. With some other mods installed, pressing Track Waypoint
  then drops several stray waypoints at once, one of which silently takes your tracked marker and
  kills the GPS route line. This cleans up the map's input hooks every time you close it.

No dependencies beyond Redscript, safe with everything, no gameplay change.
