# Distributed Runtime Hardening Verification

## Overview
This document summarizes the architectural remediation applied to the Flutter Orderlli platform to transition it into a deterministic, replay-safe distributed runtime.

## Core Pillars Implemented

### 1. Replay & Projection Governance
- **SnapshotRegistry**: Introduced to maintain authoritative snapshot identity, lineage, and replay baseline coordination.
- **Projection Epochs**: `projection_epoch`, `runtime_epoch`, and `rebuild_epoch` introduced to prevent replay of stale runtime generations.
- **ReplayCursorManager**: Persists the strict replay cursor (`lastEventSequence`, `runtimeEpoch`, `projectionChecksum`) into Drift SQLite.
- **ProjectionEventValidator**: Enforces monotonic sequence ordering, rejects gaps, and blocks stale epoch events.

### 2. OCC & Tombstone Safety
- **Conflict Envelope**: All concurrency conflicts now emit a typed envelope defining base/local/remote revisions and the applied policy.
- **Merge Policy Registry**: Hardcoded rules removed in favor of `MergePolicyRegistry` (e.g., price = manual review, availability = LWW, deletion = tombstone wins).
- **Tombstone GC**: Entities now support `deletedAt`. `TombstoneGCService` ensures deleted items remain in the projection for the GC window to satisfy replay continuity.

### 3. Commerce & Transport Foundation
- **Drift SQLite**: `sqflite` and `shared_preferences` deprecated in favor of `drift` for typed, transactional offline persistence.
- **Mutation Journal**: Pending queue operations isolated in `MutationJournalService` to ensure ordering survives restarts and reconnects.
- **Cart Runtime Freeze**: Checkout now explicitly freezes the cart against a specific `snapshotVersion` to prevent concurrent drift during payment orchestration.
- **Replay Coordinator**: WebSocket subscriptions abstracted away from UI Providers into a strict `ReplayCoordinator`.

### 4. Observability & Routing
- **Runtime Diagnostics**: Centralized tracking for Replay Gaps, Rebuilds, OCC Conflicts, and Reconnect Storms.
- **Router Guards**: `app_router.dart` hardened to verify tenant/branch scope and runtime initialization before yielding access to protected routes.

## Next Steps
- Execute `flutter pub run build_runner build` to generate the Drift database schema.
- Wire the actual WebSocket stream into the `ReplayCoordinator`.
- Rebase the dirty GitHub PRs (4, 5, 6, 7) cleanly on top of this stabilized runtime foundation.
