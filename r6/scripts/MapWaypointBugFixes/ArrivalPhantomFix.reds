// ======================================================================================
// Mod Name: Map Waypoint Bug Fixes
// File: ArrivalPhantomFix.reds
// Author: Spuddeh
// Description: Cyberpunk strands a custom waypoint's HUD/minimap widget when the waypoint is
//              destroyed after being reached. Measured on v2.31 (MappinLab, 2026-08-02): on
//              arrival the tracked flag flips false while the mappin is still registered, and
//              the mappin is UnregisterMappin'd ~2 frames later - but the marker's controller
//              is NOT torn down, so its widget outlives the mappin. It clears only when a
//              player-model menu (Inventory/Stats) or an autosave rebuilds the HUD.
//
//              The on-foot arrival destroy is native, but the tracked-state change is scripted:
//              UpdateTrackedState fires on the untrack while the mappin is still registered.
//              SetMappinActive(id, false) there is what the container observes to RELEASE the
//              pooled widget before the destroy strands it (measured; SetRootVisible only hides
//              the root and the coming destroy undoes it). Restores active on re-track.
//
//              CTD SAFETY IS THE WHOLE DESIGN. UpdateTrackedState is also called WHILE mappins
//              are being destroyed; a wref to a destroyed mappin reads non-null, so dereferencing
//              it (GetVariant/GetDisplayName) crashes the game - measured by NCZoningDistrictGuide
//              on 2026-08-02, "CTD on every world-map open". So the mappin is touched ONLY in the
//              icon path (UpdateIcon), where it is guaranteed bound; the variant is cached to a
//              field, and the tracked hook reads that field plus the controller-native
//              IsPlayerTracked() - never the mappin. Pattern mirrored from MapMarker.reds.
//
//              Scope is every CustomPositionVariant (21): the player's own waypoint and any mod
//              Set Pin alike (NCZDG's markers are variant-10 and untouched). A restore-on-retrack
//              branch keeps a mod pin that survives an untrack from being left hidden.
// File Version: 0.3.0
// Credits: Spuddeh. Substrate is a base-game bug; the cache-in-icon-path CTD workaround is the
//          technique NCZoningDistrictGuide's MapMarker.reds documents.
// ======================================================================================

// Cached per controller. Resolved only where the mappin is live (icon path), read where it is not.
@addField(BaseMappinBaseController)
let mwbf_isWaypoint: Bool;

@addField(BaseMappinBaseController)
let mwbf_wasTracked: Bool;

// The mappin's id (a VALUE), cached so the tracked hook can deactivate by id without ever
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
// field read and exits. Only a variant-21 controller acts, and only on the tracked edge - once per
// untrack, not every frame. SetMappinActive(false) is what the container observes to RELEASE the
// pooled widget (measured; SetRootVisible only hides the controller's root and the coming destroy
// undoes it). Acts on the cached id, never the mappin handle - so it is safe on the destroy path.
@addMethod(BaseMappinBaseController)
protected final func MWBF_SyncWaypointVisibility() -> Void {
  if !this.mwbf_isWaypoint {
    return;
  }
  let tracked = this.IsPlayerTracked();
  if NotEquals(this.mwbf_wasTracked, tracked) {
    let ms = GameInstance.GetMappinSystem(GetGameInstance());
    if IsDefined(ms) {
      // untracked -> release the widget before the imminent destroy; re-tracked -> restore.
      ms.SetMappinActive(this.mwbf_id, tracked);
    };
  };
  this.mwbf_wasTracked = tracked;
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

// --- Tracked hook: acts on the untrack edge from the cached flag only. UpdateTrackedState is
//     declared on the base and overridden by GameplayMappinController, so both need the wrap. ---

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
