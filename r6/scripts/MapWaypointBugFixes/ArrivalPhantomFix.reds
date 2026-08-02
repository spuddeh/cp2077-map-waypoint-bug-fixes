// ======================================================================================
// Mod Name: Map Waypoint Bug Fixes
// File: ArrivalPhantomFix.reds
// Author: Spuddeh
// Description: Cyberpunk strands a custom waypoint's HUD/minimap widget when the waypoint is
//              destroyed after being reached (on foot or by autodrive). Measured on v2.31
//              (MappinLab, 2026-08-02): on arrival the pin leaves the manually-tracked slot and
//              is UnregisterMappin'd a couple of frames later, but the marker's controller is NOT
//              torn down, so its widget outlives the mappin. It clears only when a player-model
//              menu (Inventory/Stats) or an autosave rebuilds the HUD.
//
//              The release lever that works AFTER the fact is SetRootVisible on the controller's
//              own widget - proven by the SweepPhantoms probe. SetMappinActive does NOT work here:
//              it can only release the widget if called BEFORE the untrack (as PhantomWaypointFix
//              does on the scripted map path), and the on-foot untrack is native with no such
//              pre-hook. SetRootVisible hides the already-stranded widget directly, so timing does
//              not matter.
//
//              The trigger is the MappinSystem's manually-tracked SLOT, not the controller's own
//              tracked flags - those never flip on arrival (measured). UpdateTrackedState fires
//              often enough on the marker controllers; each compares its cached mappin id to the
//              current slot and hides its widget when the pin is no longer tracked.
//
//              CTD SAFETY IS LOAD-BEARING. UpdateTrackedState is also called WHILE mappins are
//              being destroyed; a wref to a destroyed mappin reads non-null, so dereferencing it
//              (GetVariant/GetDisplayName) crashes the game - measured by NCZoningDistrictGuide on
//              2026-08-02, "CTD on every world-map open". So the mappin is touched ONLY in the icon
//              path (UpdateIcon), where it is guaranteed bound; the variant and id are cached there,
//              and the tracked hook reads those fields and the slot id - never the mappin. Pattern
//              mirrored from MapMarker.reds.
//
//              Scope is every CustomPositionVariant (21): the player's own waypoint and any mod Set
//              Pin alike (NCZDG's markers are variant-10 and untouched). SetRootVisible is driven
//              from the slot both ways, so a pin that is re-tracked comes back.
// File Version: 0.3.0
// Credits: Spuddeh. Substrate is a base-game bug; the cache-in-icon-path CTD workaround is the
//          technique NCZoningDistrictGuide's MapMarker.reds documents, and the SetRootVisible
//          release is what the MappinLab SweepPhantoms probe proved.
// ======================================================================================

// Cached per controller. Resolved only where the mappin is live (icon path), read where it is not.
@addField(BaseMappinBaseController)
let mwbf_isWaypoint: Bool;

// The mappin's id (a VALUE), cached so the tracked hook can compare it to the slot without ever
// dereferencing the mappin handle - which may already be dangling by then.
@addField(BaseMappinBaseController)
let mwbf_id: NewMappinID;

// Resolve whether this controller's mappin is a custom-position waypoint, and cache its id. Safe
// ONLY from the icon path - the mappin is guaranteed bound there. Never call from the tracked hook.
@addMethod(BaseMappinBaseController)
protected final func MWBF_RefreshWaypointFlag() -> Void {
  let mappin = this.GetMappin();
  if IsDefined(mappin) {
    this.mwbf_isWaypoint = Equals(mappin.GetVariant(), gamedataMappinVariant.CustomPositionVariant);
    this.mwbf_id = mappin.GetNewMappinID();
  }
}

// Runs inside a hot path shared with every mappin on screen: a non-waypoint controller costs one
// field read and exits. A variant-21 controller compares its cached id to the manually-tracked
// slot - the controller's own tracked flags never flip on arrival, only the slot does - and drives
// its widget's visibility from that. NO per-controller edge state, because the marker controllers
// are pooled and the instance that sees the untrack is usually not the one that saw the track.
// SetRootVisible hides the controller's own widget (which SetMappinActive cannot reach post-untrack)
// and reads nothing off the mappin, so it is CTD-safe.
@addMethod(BaseMappinBaseController)
protected final func MWBF_SyncWaypointVisibility() -> Void {
  if !this.mwbf_isWaypoint {
    return;
  }
  let ms = GameInstance.GetMappinSystem(GetGameInstance());
  if !IsDefined(ms) {
    return;
  }
  let isSlot = Equals(ms.GetManuallyTrackedMappinID(), this.mwbf_id);
  this.SetRootVisible(isSlot);
}

// --- Icon path: the mappin is bound here, so identity is refreshed safely on every surface. ---

@wrapMethod(MinimapPOIMappinController)
protected final func UpdateIcon() -> Void {
  wrappedMethod();
  this.MWBF_RefreshWaypointFlag();
}

@wrapMethod(BaseWorldMapMappinController)
protected func UpdateIcon() -> Void {
  wrappedMethod();
  this.MWBF_RefreshWaypointFlag();
}

@wrapMethod(QuestMappinController)
protected func UpdateIcon() -> Void {
  wrappedMethod();
  this.MWBF_RefreshWaypointFlag();
}

@wrapMethod(GameplayMappinController)
private func UpdateIcon() -> Void {
  wrappedMethod();
  this.MWBF_RefreshWaypointFlag();
}

// --- Tracked hook: fires often enough to catch the slot change. UpdateTrackedState is declared on
//     the base and overridden by GameplayMappinController, so both need the wrap. ---

@wrapMethod(BaseMappinBaseController)
protected func UpdateTrackedState() -> Void {
  wrappedMethod();
  this.MWBF_SyncWaypointVisibility();
}

@wrapMethod(GameplayMappinController)
protected func UpdateTrackedState() -> Void {
  wrappedMethod();
  this.MWBF_SyncWaypointVisibility();
}
