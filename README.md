# Map Waypoint Bug Fixes

Fixes three base-game bugs you see as broken waypoints, stuck map markers and missing fast
travel points. No gameplay changes.

Nexus Mods: <https://www.nexusmods.com/cyberpunk2077/mods/32175>

## What it fixes

**Missing fast travel points.** With a lot of mods installed, fast travel points you have already
discovered can be missing from the map after loading a save, and visiting the terminal again does
not bring them back. While a save loads, the game queues every map marker it needs to create, and
the queue has a fixed size. Once it is full, the game silently drops the rest. Fast travel and metro
stations are queued last, so they go first; with a big enough mod list, vendors, quest markers and
other map icons go missing the same way. This keeps every marker the queue turns away and adds it
once there is room, so nothing is lost.

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

Input leak. This one is a vanilla leak that only bites when another mod keeps a leaked map
controller alive. I confirmed it with `World Builder` and `Native Interactions Framework`
loaded together; other combinations may do the same. It is not those mods' fault, they just
surface a base-game leak.

1. **Load a stack that includes those two mods.**
2. **Open and close the world map a few times.**
3. **Press Track Waypoint once.** Several stray waypoints drop at once instead of one, and your
   tracked marker and route line can vanish.

Missing fast travel points. This one depends on how many map markers your mods add while a save
loads, so there is no fixed vanilla recipe. A large mod list, especially one with mods that add
many map icons, is the usual way to see it.

1. **Load a save.**
2. **Open the map.** Some fast travel points you have discovered are missing.
3. **Visit one of the missing terminals.** It still does not come back.

With this mod installed, none of these happen.

## Requirements

- [RED4ext](https://www.nexusmods.com/cyberpunk2077/mods/2380)
- [Redscript](https://www.nexusmods.com/cyberpunk2077/mods/1511)

## Install

Install with your mod manager, or extract the archive into your Cyberpunk 2077 folder so that
`red4ext\plugins\MapWaypointBugFixes\` and `r6\scripts\MapWaypointBugFixes\` end up in place.

## Compatibility

The script fixes are added with `@wrapMethod` throughout, so they stack with other mods instead
of replacing parts of the game. The stuck-marker fix only touches custom-position waypoints
(yours, and the "Set Pin" markers some mods add). The missing-markers fix does not change any
marker; it only stops markers being lost while a save loads. No saved-game changes.

If you use "Register all Fast Travel Points - Restore Mappins Workaround", you can remove it.

## For mod authors

If your mod places custom "Set Pin" waypoints, the stuck-marker fix covers them too. You can
list this as a requirement instead of handling that bug yourself.

## License

Licensed under the [MIT License](LICENSE). Use, change and share this mod and its source,
including in your own mods. Keep the licence notice with any copy.

## Disclaimer

This mod was developed with the assistance of an LLM. All in-game testing and code validation
was performed by a human. No rogue AIs were permitted through the Blackwall.
