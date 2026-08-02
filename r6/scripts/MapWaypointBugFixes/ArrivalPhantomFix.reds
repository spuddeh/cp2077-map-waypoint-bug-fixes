// ======================================================================================
// Mod Name: Map Waypoint Bug Fixes
// File: ArrivalPhantomFix.reds
// Author: Spuddeh
// Description: A custom waypoint's HUD/minimap marker is stranded when the waypoint is destroyed
//              after being reached (on foot or by autodrive): the pin leaves the manually-tracked
//              slot and is unregistered, but its marker controller is not torn down, so the widget
//              outlives the mappin. Vanilla clears it only when a player-model menu (Inventory or
//              Stats) or an autosave rebuilds the HUD.
//
//              Marker controllers watch the manually-tracked slot; once a controller's pin is no
//              longer the slot, SetRootVisible(false) hides its widget. This hides the
//              already-stranded widget directly, so the arrival-untrack timing does not matter.
//              SetMappinActive is NOT usable here - it releases the widget only when called before
//              the untrack, and the arrival untrack is native with no pre-hook.
//
//              The trigger is the MappinSystem slot, NOT the controller's tracked flags
//              (IsPlayerTracked / IsTracked / IsCustomPositionTracked) - those do not flip when a
//              pin is reached. There is no per-controller edge state: marker controllers are pooled,
//              so the instance that sees the untrack is usually not the one that saw the track.
//
//              CTD SAFETY IS LOAD-BEARING. UpdateTrackedState also runs while mappins are being
//              destroyed, where a wref to a destroyed mappin reads non-null; dereferencing it
//              (GetVariant/GetDisplayName) crashes the game. So the variant and id are read ONLY in
//              the icon path (UpdateIcon, where the mappin is guaranteed bound) and cached; the
//              tracked hook reads those cached fields and the slot id, never the mappin.
//
//              Scope: CustomPositionVariant (21) only - the player's own waypoint and mod Set Pins.
//              Quest, POI and other variants are left alone. Visibility is driven from the slot both
//              ways, so a pin that is re-tracked comes back.
// File Version: 0.3.0
// Credits: Spuddeh. Substrate is a base-game bug.
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
