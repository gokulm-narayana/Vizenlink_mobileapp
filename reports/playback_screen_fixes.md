# Playback Screen Audit & Fixes Report
**Date:** 2026-08-26

## Overview
An audit of the Playback screen (`_PlaybackTab` in `camera_live_screen.dart` and `CameraTimeline` widget) was conducted to identify and resolve bugs, incomplete features, and UX issues. The screen is primarily functional for UI interaction but required fixes for state synchronization during video playback.

## Identified Issues & Resolutions

### 1. Timeline Needle Sync (Frozen Needle)
**Issue:** When the dummy video played in the background, the timeline needle (`_dayFraction`) remained static. The UI and video would become completely unsynchronized because the timeline was only updated upon manual scrubbing.
**Resolution:** Updated `_onTick()` within `_PlaybackTabState` to continuously synchronize `_dayFraction` with the `VideoPlayerController`'s playback progress as long as the video is playing. 

### 2. Tab Switching Video State
**Issue:** Switching from the "Live" tab to the "Playback" tab snapped the video to the timeline needle but failed to pause the video. This meant the video would continue playing immediately, which is jarring when entering a playback/scrubbing view.
**Resolution:** Added `widget.controller.pause()` when the Playback tab becomes active, and `widget.controller.play()` when switching back to the Live tab.

### 3. Infinite Looping on Prev/Next Event
**Issue:** The "Next Event" and "Prev Event" buttons used `firstWhere` and `lastWhere` with an `orElse` clause that looped back to the beginning or end of the day's events. This caused an abrupt jump across the entire day when reaching the edge of the event list.
**Resolution:** Implemented `_hasNextEvent` and `_hasPrevEvent` properties to explicitly check if there are more events in the given direction. If there are none, the buttons are disabled, preventing the infinite loop.

### 4. Unimplemented Action Buttons
**Issue:** The "Snapshot" and "Download clip" buttons were present but had empty `onPressed` callbacks, providing no feedback when tapped.
**Resolution:** Wired up the `onPressed` callbacks to show a `SnackBar` indicating that the features are not yet implemented. This provides immediate feedback to the user while the backend is being built.

## Remaining Technical Debt
- **Mock Data:** The Playback screen heavily relies on mock data (`_recordingDays`, `_mockRecordedRanges`, `_mockDayEvents`). This needs to be replaced with a real backend integration as detailed in `CLAUDE.md`.
- **Action Buttons:** The snapshot and clip download functionality still needs to be implemented.
