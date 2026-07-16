# Changelog — World Map Input Leak Fix

## [0.1.0] — 2026-07-16 — Initial

- `@wrapMethod(WorldMapMenuGameController) OnUninitialize`: unregisters the four global
  input callbacks (`OnAxisInput`, `OnPressInput`, `OnHoldInput`, `OnReleaseInput`) that
  vanilla registers in `OnEntityAttached` (`worldMap.swift:482-485`) and only ever
  unregisters in `OnEntityDetached` (`:519-522`), which never fires.
- Root cause is a base-game leak: every world-map open leaves a `WorldMapMenuGameController`
  registered in the global input callback list. Harmless alone (leaked controllers are
  dead), but any mod that keeps one alive turns it into a "ghost" that re-fires Track
  Waypoint on a single press → stray waypoints that steal the tracked slot and break the
  GPS trail.
- Reproduced minimally with **worldBuilder - Akiway + Native Interactions Framework**
  loaded together (neither alone). See wiki `concepts/mappin-system-reference` §6.
- Zero dependencies; pure redscript; `@wrapMethod` for compatibility.
