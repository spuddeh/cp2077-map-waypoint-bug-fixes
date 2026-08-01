// ======================================================================================
// Mod Name: Map Waypoint Bug Fixes
// File: PhantomWaypointFix.reds
// Author: Spuddeh
// Description: Cyberpunk strands a mappin's HUD/minimap widget when a mappin that has ever
//              been tracked is destroyed. It fires on ordinary use - untracking a waypoint,
//              or switching the tracked slot to a quest/POI from the world map - and leaves
//              a "phantom" marker on the HUD until an event that rebuilds the player model
//              (autosave, Inventory, Stats) clears it. With autosaves off, it lingers.
//
//              The world-map's waypoint-set/untrack paths all funnel through the scripted
//              TryTrackQuestOrSetWaypoint (worldMap.swift:845); the mappin it destroys is
//              always the manually-tracked slot, via the NATIVE UntrackCustomPositionMappin
//              (:186) which cannot be wrapped. The wrap targets the scripted caller instead:
//              it deactivates the manually-tracked mappin BEFORE vanilla runs, so the widget
//              tears down cleanly through the normal deactivate path instead of being
//              orphaned, then re-activates it if it survived the call.
//
//              The survive-check keeps this safe against the exact manual-slot semantics:
//              a mappin vanilla destroyed reads back as null and stays gone (no ghost
//              route); a mappin vanilla left alive is restored, at worst a one-frame flicker
//              on a marker that was not going to change. No census, no per-frame work: the
//              wrap runs only on the Track-Waypoint press. Signatures verified vs the RTTI dump.
// File Version: 0.2.0
// Credits: Spuddeh. Substrate is a base-game bug (mappin widget stranding on destroy).
// ======================================================================================

@wrapMethod(WorldMapMenuGameController)
private final func TryTrackQuestOrSetWaypoint() -> Void {
  let ms: ref<MappinSystem> = GameInstance.GetMappinSystem(this.GetOwner().GetGame());
  let invalidId: NewMappinID;
  let doomedId: NewMappinID = ms.GetManuallyTrackedMappinID();
  let hadTracked: Bool = NotEquals(doomedId, invalidId);

  // Deactivate the manually-tracked mappin so its widget returns to the pool cleanly,
  // BEFORE the native untrack inside vanilla can orphan it.
  if hadTracked {
    ms.SetMappinActive(doomedId, false);
  }

  wrappedMethod();

  // Restore only a survivor. A destroyed mappin reads back as null here, so a survivor is
  // never left hidden and a casualty is never left routing invisibly.
  if hadTracked && IsDefined(ms.GetMappin(doomedId)) {
    ms.SetMappinActive(doomedId, true);
  }
}
