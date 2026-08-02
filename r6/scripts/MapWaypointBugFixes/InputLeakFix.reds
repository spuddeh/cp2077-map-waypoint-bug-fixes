// ======================================================================================
// Mod Name: Map Waypoint Bug Fixes
// File: InputLeakFix.reds
// Author: Spuddeh
// Description: Cyberpunk's WorldMapMenuGameController registers four global input
//              callbacks in OnEntityAttached (worldMap.swift:482-485) but unregisters
//              them ONLY in OnEntityDetached (:519-522) - which never fires. Every
//              world-map open therefore leaks a controller into the global input
//              callback list. Bare, those leaked controllers are dead and harmless; but
//              any mod that keeps one alive turns it into a live "ghost" that re-fires
//              Track Waypoint on a single press - spawning a stray custom waypoint that
//              steals the tracked slot and kills the GPS trail.
//
//              This wrap does, in OnUninitialize (which DOES fire on every map close and
//              touches none of these callbacks - :252), exactly what OnEntityDetached
//              should have done: unregister the four callbacks. Copied verbatim from
//              worldMap.swift:519-522, so no signature is guessed. With it installed, no
//              controller is ever left registered, so there is nothing to turn into a
//              ghost - regardless of which other mods are present.
// Mod Version: 1.0.0
// Credits: Spuddeh. Fixes a base-game (vanilla) bug.
// ======================================================================================

@wrapMethod(WorldMapMenuGameController)
protected cb func OnUninitialize() -> Bool {
  // The unregister vanilla forgot to reach. OnEntityDetached (:519-522) is the only place
  // vanilla removes these, and it never fires; OnUninitialize does. Unregistering a
  // callback that is not registered is a safe no-op, so this is unconditional, exactly as
  // vanilla is at the detach site.
  this.UnregisterFromGlobalInputCallback(n"OnPostOnAxis", this, n"OnAxisInput");
  this.UnregisterFromGlobalInputCallback(n"OnPostOnPress", this, n"OnPressInput");
  this.UnregisterFromGlobalInputCallback(n"OnPostOnHold", this, n"OnHoldInput");
  this.UnregisterFromGlobalInputCallback(n"OnPostOnRelease", this, n"OnReleaseInput");
  return wrappedMethod();
}
