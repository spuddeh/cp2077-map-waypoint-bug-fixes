### [Unreleased - v1.1.0]

- Fix: Fast travel points you have already discovered no longer go missing from the map after
  loading a save. With a lot of mods installed, the game could run out of room for map markers
  while a save loads and silently drop the ones that came last, which is usually fast travel and
  metro stations. Visiting the terminal again did not bring them back. With a big enough mod list,
  vendors, quest markers and other map icons could go missing the same way; those are covered too.
- New requirement: RED4ext.

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
