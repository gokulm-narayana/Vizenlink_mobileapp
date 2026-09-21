# `camera_api` Change Report — WAN reachability ping fix

**Date:** 2026-09-15
**Package:** `packages/camera_api`
**Files touched:** 3 (2 source, 1 test)
**Wire-format changes:** none
**Breaking changes:** none

---

## 1. Summary

A camera connected over WAN was intermittently displayed as **offline** on the Dashboard while being
fully reachable. Root cause was a dead parameter in `WanDeviceIdentityClient.getDeviceIdentity` —
the `timeout` argument was declared but never forwarded to the transport, so the Dashboard's
reachability ping requested a 5s budget and silently received ~24s (12s default × the one-shot
retry). That overran the Dashboard's own 15s poll interval and tripped an app-side 2-minute WAN
backoff, during which the camera was rendered offline without a single verification attempt.

Two changes were made in this package:

| # | File | Change |
|---|------|--------|
| 1 | `lib/src/wan/wan_device_identity_client.dart` | Forward `timeout` to the transport; add `retryOnTimeout` |
| 2 | `lib/src/wan/iot_command_client.dart` | Add `retryOnTimeout` opt-out for the one-shot retry |
| 3 | `test/iot_command_client_test.dart` | 5 regression tests + transport timeout recorder |

Both new parameters default to prior behaviour, so no existing call site changes behaviour.

---

## 2. Root cause analysis

### 2.1 The dead parameter

`getDeviceIdentity` accepted a `timeout` and then called `sendCommandWithResponse` without it:

```dart
// BEFORE
Future<CameraResult<({String name, String location, String timezone})>> getDeviceIdentity({
  Duration timeout = const Duration(seconds: 15),   // declared…
}) async {
  try {
    final output = await _iot.sendCommandWithResponse(IotCommandClient.getDeviceIdentity);
    //                                                ^ …never forwarded
```

`sendCommandWithResponse` does accept a timeout (`double? timeoutSeconds`) and falls back to a
hardcoded 12s when it is absent. `_publishAndWait` then retries once on a bare timeout, so the
effective worst case was **12s × 2 = ~24s**.

### 2.2 Downstream effect

The caller is `lib/app_state/camera_sync.dart → pingCameraReachability()`, invoked by
`dashboard_screen.dart` on a **15s** timer per camera:

```dart
final result = await WanDeviceIdentityClient(thingName)
    .getDeviceIdentity(timeout: const Duration(seconds: 5));   // asked for 5s, got ~24s
```

Consequences, in order:

1. A single ping could outlive its own 15s poll interval.
2. Two consecutive slow/failed pings incremented `_wanFailureStreak` past `_wanBackoffThreshold`
   (2), arming `_wanBackoffUntil` for `_wanBackoffDuration` (**2 minutes**).
3. Inside that window the WAN probe was skipped entirely and `reachable` stayed `false`, so
   `isOnline: false` was written — i.e. an **outbound-call rate limit was surfaced to the user as
   "camera offline"** for two minutes with zero verification.

### 2.3 Scope of the same defect elsewhere

The identical "declared but never forwarded" pattern remains at **60 call sites across 19 other
`Wan*Client` files**. Those were deliberately **not** changed — see §6.

---

## 3. Change 1 — `lib/src/wan/wan_device_identity_client.dart`

### Diff

```diff
+ /// [retryOnTimeout] — pass `false` from a caller that polls on its own schedule (the Dashboard's
+ /// 15s reachability ping), where retrying doubles this call's worst-case latency to buy a second
+ /// chance the next tick provides anyway a few seconds later.
+ ///
+ /// **Real bug fixed 2026-09-15**: [timeout] was declared here but never passed to
+ /// [IotCommandClient.sendCommandWithResponse], so it silently fell through to that method's own
+ /// 12s default — and, with the one-shot retry on top, took up to ~24s. `pingCameraReachability`
+ /// asks for 5s and was getting ~24s, overrunning the Dashboard's own 15s poll interval and
+ /// tripping its 2-minute WAN backoff, which showed a perfectly healthy camera as offline.
  Future<CameraResult<({String name, String location, String timezone})>> getDeviceIdentity({
    Duration timeout = const Duration(seconds: 15),
+   bool retryOnTimeout = true,
  }) async {
    try {
-     final output = await _iot.sendCommandWithResponse(IotCommandClient.getDeviceIdentity);
+     final output = await _iot.sendCommandWithResponse(
+       IotCommandClient.getDeviceIdentity,
+       timeoutSeconds: timeout.inMilliseconds / 1000,
+       retryOnTimeout: retryOnTimeout,
+     );
```

### Notes

- `timeout.inMilliseconds / 1000` is used rather than `inSeconds` so sub-second precision survives
  the conversion to the `double? timeoutSeconds` the callee expects.
- The default remains `15s`, so any existing caller that did not pass a timeout now gets **15s
  instead of the previous 12s**. This is the declared contract being honoured for the first time;
  it affects only `getDeviceInfo`-adjacent manual flows, not the ping (which passes 5s explicitly).
- `getDeviceInfo` in the same file still has the dead parameter and was left untouched to keep this
  change minimal and reviewable.

---

## 4. Change 2 — `lib/src/wan/iot_command_client.dart`

### Diff

```diff
+ /// [retryOnTimeout] (default `true`) opts out of the one-shot retry documented on
+ /// [_publishAndWait]. Only pass `false` from a caller that already polls on its own schedule —
+ /// the Dashboard's 15s reachability ping, where the retry doubles worst-case latency to buy a
+ /// second chance the next tick provides anyway. Every user-initiated Get/Set should keep the
+ /// retry: for those, a missing reply is a one-shot failure the user would otherwise have to
+ /// notice and redo manually.
  Future<Map<String, dynamic>?> sendCommandWithResponse(
    int command, {
    Map<String, dynamic>? params,
    double? timeoutSeconds,
+   bool retryOnTimeout = true,
  }) async {
    final reply = await _publishAndWait(
      command,
      params: params,
      timeout: timeoutSeconds != null
          ? Duration(milliseconds: (timeoutSeconds * 1000).round())
          : const Duration(seconds: 12),
+     // `isRetry: true` on the first attempt makes the no-reply path below throw immediately
+     // instead of scheduling the retry — same branch, no duplicate logic.
+     isRetry: !retryOnTimeout,
    );
```

### Mechanism

No new control flow was introduced. `_publishAndWait` already carries an internal `isRetry` flag
whose only effect is to decide whether a bare timeout re-enters the method or throws:

```dart
if (reply == null) {
  if (isRetry) {
    throw Exception('No response from camera (timed out)');
  }
  return _publishAndWait(command, params: params, timeout: timeout, isRetry: true);
}
```

Seeding that flag as `true` on the first attempt therefore short-circuits the retry using the exact
branch that already existed. `_publishAndWait` itself is unmodified.

### Caveat for reviewers

`isRetry` was previously documented as *"internal — set by the one-shot retry below, never pass it
explicitly."* This change makes `sendCommandWithResponse` the one sanctioned place that seeds it.
If you would prefer an explicit `maxAttempts`/`retries` parameter over reusing `isRetry`, that is a
reasonable alternative — it just costs a second branch.

---

## 5. Change 3 — `test/iot_command_client_test.dart`

`_FakeTransport` gained a timeout recorder:

```diff
+ /// Every `timeout` this transport was actually handed, in call order — backs the
+ /// timeout-pass-through tests below.
+ final List<Duration> timeouts = [];

  @override
  Future<Map<String, dynamic>?> publishAndWait(
    String thingName,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    publishedAndWaited.add(body);
+   timeouts.add(timeout);
    if (replies.isEmpty) return {'status': 'ok'};
    return replies.removeAt(0);
  }
```

Five tests added:

| Test | Asserts |
|------|---------|
| defaults to a 12s wait when given no timeout | `timeouts.single == 12s` — guards the fallback |
| passes `timeoutSeconds` through to the transport | `timeouts.single == 5s` |
| `retryOnTimeout: false` → single attempt | `publishedAndWaited.length == 1` and throws |
| `retryOnTimeout` still defaults to one retry | `publishedAndWaited.length == 2` and throws |
| `getDeviceIdentity` honours its own timeout | `timeouts.single == 5s` — **the actual regression guard** |

---

## 6. Deliberately out of scope

The same dead-`timeout` defect affects **60 call sites in 19 other `Wan*Client` files**. Declared
timeout values across `lib/src/wan/`:

| Declared value | Occurrences |
|---|---|
| 15s | 64 |
| 12s | 3 |
| 25s | 1 |

Because the overwhelming majority declare **15s** while the current *effective* default is **12s**,
mechanically forwarding all of them would make those calls **slower to fail**, not faster — a
latency regression of 3s per attempt (6s with the retry). That is the opposite of the problem being
fixed here.

**Recommendation:** treat it as a separate, deliberate pass where each screen's timeout is chosen on
purpose rather than inherited from a copy-pasted default, ideally alongside a lint or test that
fails when a declared `timeout` is not forwarded.

---

## 7. Risk assessment

| Area | Assessment |
|------|------------|
| Wire format (command numbers, payload shape, topics) | **Unchanged** |
| Existing callers | **Unaffected** — both new params default to prior behaviour |
| Behavioural delta | `getDeviceIdentity` only: honours caller timeout; default 12s → 15s when unspecified |
| New control flow | None — reuses the existing `isRetry` branch |
| Isolate/threading | Untouched |
| Credentials/auth | Untouched |

### Expected runtime effect

Worst-case reachability ping, combined with the app-side changes in `camera_sync.dart` (outside this
package):

```
before:  3s LAN probe + 12s WAN + 12s retry   ≈ 27s   (overruns the 15s poll)
after:   0s LAN probe + 5s WAN, no retry      ≈  5s   (comfortably inside the poll)
```

---

## 8. Verification

```
$ cd packages/camera_api && flutter test
00:04 +141: All tests passed!

$ flutter analyze lib/ packages/camera_api/lib/
No issues found!

$ flutter test          # app suite
00:01 +16: All tests passed!
```

Also deployed to a physical device (Android 16, `I2508`) and confirmed running.

**Not yet verified against real hardware:** the end-to-end latency improvement under a genuine
off-LAN/WAN condition with a live camera. Worth a targeted check before this is considered closed.

---

## 9. Related app-layer changes (outside `camera_api`)

Listed for context — these are in `lib/`, not this package, and required no API approval:

- `lib/app_state/camera_sync.dart`
  - Skip the 3s LAN probe when `Camera.lastKnownWan == true` (mirrors the optimisation
    `syncCameraFromDevice` already had).
  - Ping now calls `getDeviceIdentity(..., retryOnTimeout: false)`.
  - `reachable` changed from `bool` to `bool?`; the backoff window now yields `null` ("unknown")
    and preserves the last confirmed state instead of writing `isOnline: false`.
