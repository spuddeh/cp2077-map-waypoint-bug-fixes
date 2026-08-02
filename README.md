# Map Waypoint Bug Fixes

A small, pure-redscript Cyberpunk 2077 mod that fixes two base-game bugs you experience as
broken waypoints and stuck map markers. No dependencies, no gameplay changes, safe with
everything.

- Nexus Mods: <!-- TODO: add the Nexus mod link after the first upload -->

## What it fixes

**1. Stuck HUD/minimap markers.** When a custom waypoint is removed, its marker can hang on
your HUD and minimap long after the waypoint is gone. It happens on ordinary use — reaching a
waypoint (on foot or by autodrive), un-tracking one from the map, or switching your tracked
location to a quest or point of interest. Vanilla only clears the leftover marker when you open
your Inventory or Stats, or when an autosave fires — so with autosaves off it can linger. This
makes the marker clear the moment the waypoint is gone.

**2. World-map input leak.** Opening the world map repeatedly leaves "ghost" copies of the map
controller registered in the background. Alone they're harmless, but with certain other mods
installed they come alive: one press of Track Waypoint then drops several stray waypoints at
once, one of which silently steals your tracked marker and kills the GPS route line. This cleans
up the map's input hooks every time you close it — exactly what the game intended to do but
never did.

## Requirements

None. It uses only base-game methods.

## Install

Install with your mod manager, or extract the archive into your Cyberpunk 2077 folder so that
`r6\scripts\MapWaypointBugFixes\` sits alongside the game. Requires
[redscript](https://www.nexusmods.com/cyberpunk2077/mods/1511) (bundled with most script mods /
Redscript, and included in the common modding toolchains).

## Compatibility

- Pure redscript, using `@wrapMethod` throughout — it adds to the game's behaviour rather than
  replacing it, so it stays compatible with other mods that touch the same systems.
- Only affects custom-position waypoints (the kind you set yourself, and the "Set Pin" markers
  some mods add). Quest markers, points of interest, apartment and stash markers are untouched.
- No saved-game changes, no new content, no persistent state.

## For mod authors

If your mod places custom "Set Pin" style waypoints, the stuck-marker cleanup here covers them
too — you don't need to work around that base-game bug yourself. It's a good shared dependency
for any mod that adds map markers.

## License

Licensed under the [PolyForm Noncommercial License 1.0.0](LICENSE). You may use, modify, and
share this mod and its source for any noncommercial purpose, as long as you credit the original
creator. Commercial use, including paid mods or selling, is not permitted.

## Disclaimer

This mod was developed with the assistance of an LLM. All in-game testing and code validation
was performed by a human. No rogue AIs were permitted through the Blackwall.
