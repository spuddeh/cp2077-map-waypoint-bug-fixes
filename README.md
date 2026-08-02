# Map Waypoint Bug Fixes

Fixes two base-game bugs you see as broken waypoints and stuck map markers. Pure redscript,
no gameplay changes, safe with everything.

Nexus Mods: <!-- TODO: add the Nexus link after the first upload -->

## What it fixes

**Stuck HUD and minimap markers.** When a custom waypoint is removed, its marker can stay on
your HUD and minimap after the waypoint itself is gone.

**World-map input leak.** Opening the world map repeatedly leaves "ghost" copies of the map
controller running in the background. With some other mods installed, one press of Track
Waypoint then drops several stray waypoints at once, and one of them silently takes your tracked
marker and kills the GPS route line.

## How to see the bugs (in vanilla, with this mod off)

Stuck marker:

1. **Set a waypoint.** Open the map and right-click a spot to place a custom waypoint.
2. **Get rid of it.** Walk or drive to it, or reopen the map and un-track it.
3. **Check your HUD and minimap.** The marker is still there, even though the waypoint is gone.
4. **Open Inventory or Stats.** Now it clears. (An autosave clears it too.)

Input leak (needs the right mods loaded to trigger):

1. **Open and close the world map a few times.**
2. **Press Track Waypoint once.** Several stray waypoints drop at once instead of one, and your
   tracked marker and route line can vanish.

With this mod installed, neither happens.

## Requirements

- [Redscript](https://www.nexusmods.com/cyberpunk2077/mods/1511)

Nothing else.

## Install

Install with your mod manager, or extract the archive into your Cyberpunk 2077 folder so that
`r6\scripts\MapWaypointBugFixes\` ends up in place.

## Compatibility

Added with `@wrapMethod` throughout, so it stacks with other mods instead of replacing parts of
the game. It only touches custom-position waypoints (yours, and the "Set Pin" markers some mods
add). Quest, point-of-interest, apartment and stash markers are left alone. No saved-game
changes.

## For mod authors

If your mod places custom "Set Pin" waypoints, the stuck-marker fix covers them too. You can
list this as a requirement instead of handling that bug yourself.

## License

Licensed under the [PolyForm Noncommercial License 1.0.0](LICENSE). Use, modify, and share for
any noncommercial purpose, with credit. No commercial use or paid mods.

## Disclaimer

This mod was developed with the assistance of an LLM. All in-game testing and code validation
was performed by a human. No rogue AIs were permitted through the Blackwall.
