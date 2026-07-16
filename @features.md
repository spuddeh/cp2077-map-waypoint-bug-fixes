# Features — World Map Input Leak Fix

## Implemented

- Unregister the world map's four global input callbacks on `OnUninitialize`, closing the
  base-game leak that leaves `WorldMapMenuGameController` instances registered after the
  map closes. Prevents leaked controllers from being dispatched as "ghosts" that fire
  stray Track-Waypoint actions.

## Planned

- Nothing outstanding. This is a single-purpose fix. If the leak turns out to have other
  symptoms (e.g. leaked `OnAxisInput`/`OnHoldInput` effects), document them here first.
