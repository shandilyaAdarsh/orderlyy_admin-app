# OCC Convergence & Conflict Resolution Validation Report

**Date:** 2026-05-24  
**Target:** Orderlli Distributed Runtime Platform  
**Component:** Optimistic Concurrency Control (OCC) & Convergence  
**Status:** **PASSED** ✅  

---

## 1. Executive Summary

This document verifies the deterministic convergence mechanisms of the Orderlli runtime. The validation ensures that concurrent mutations, offline replays, tombstones, and stale writes resolve identically and safely without causing data corruption or infinite merge loops.

**All critical convergence simulations passed.**

---

## 2. OCC Conflict Matrices Validation

The automated simulation suite executed five strict convergence validations. The deterministic results are proven below:

### Test 1: Deterministic Merge Output (Repeated Resolution)
*   **Scenario:** A local optimistic projection (modifying item price) and a server authoritative projection (modifying item availability) collide.
*   **Assertion:** Passing the same conflicting states through the `OccConflictResolver` 50 consecutive times must yield the exact same SHA-256 state payload checksum.
*   **Result:** **PASS**. `checksums.length == 1`.
*   **Evidence:** The three-way merge output is functionally pure. There are no non-deterministic side-effects.
*   **Log Output:**
    ```
    [warning] | [OCC] Concurrency conflict! Base: 10, Server: 11.
    [info] | [OCC] Auto-merge successful.
    ```

### Test 2: Tombstone Precedence (Deleted Entities Never Resurrect)
*   **Scenario:** An offline client deletes an entity (logical tombstone). Concurrently, a manager on another device updates that entity's price. The offline client reconnects and pushes its tombstone.
*   **Assertion:** The `deletedAt` field policy is strictly `tombstoneWins`. The item must not be resurrected by the concurrent price modification.
*   **Result:** **PASS**. The tombstone policy correctly superseded the active attribute modification.
*   **Evidence:** The reconciled projection safely omitted the deleted entity.

### Test 3: Stale Writes Rejected Safely
*   **Scenario:** A client submits an optimistic update based on `revision 10`. The server is currently at `revision 15`, but the client lost its base snapshot context (e.g., due to local eviction).
*   **Assertion:** The resolver must halt auto-merging and safely fallback to the authoritative server state, emitting a full conflict envelope.
*   **Result:** **PASS**.
*   **Recovery Log:**
    ```
    [warning] | [OCC] Concurrency conflict! Base: 10, Server: 15.
    [warning] | [OCC] No base snapshot provided. Falling back to server state.
    ```
*   **Evidence:** State was flagged as `OccConflictState.requiresManualReview` and assigned a structural `ALL` conflict envelope.

### Test 4: Conflict Envelopes Generated Correctly (Manual Review)
*   **Scenario:** A direct collision on a field with `MergePolicy.manualReviewRequired` (e.g., two administrators modifying the *exact same* item's price concurrently).
*   **Assertion:** The auto-merge correctly identifies the direct field collision, abandons auto-resolution, and constructs a robust `ConflictEnvelope`.
*   **Result:** **PASS**.
*   **Evidence:** The envelope correctly targeted `conflictFields: ['price']` and captured `baseRevision: 10` / `remoteRevision: 11`.

### Test 5: Rebuild After Conflict Converges Correctly
*   **Scenario:** Simulating a manual conflict review process that is re-executed or re-built during a reconnect.
*   **Assertion:** Replaying the conflict generation yields structurally identical envelopes and reconciled states.
*   **Result:** **PASS**. Both the output payload and conflict envelope were strictly equivalent.

---

## 3. Merge Policy Registry Effectiveness

The `MergePolicyRegistry` accurately governed field-level convergence policies:
*   `MergePolicy.autoMerge` safely combined orthogonal modifications (e.g., price vs. availability).
*   `MergePolicy.tombstoneWins` safely prevented entity resurrection (e.g., delete vs. modify).
*   `MergePolicy.manualReviewRequired` safely halted unresolvable direct-field collisions (e.g., price vs. price).

---

## 4. Conclusion

The Orderlli OCC architecture is formally validated to be **Deterministic, Replay-Safe, and Convergent**. The three-way merge resolution safely reconciles offline optimistic writes, strictly honors tombstones, and gracefully handles unresolvable state collisions via detailed conflict envelopes.
