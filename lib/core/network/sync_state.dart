// lib/core/network/sync_state.dart

/// Shared SyncState enum used by all realtime providers.
///
/// - [fresh]     — data is up-to-date and the live channel is open.
/// - [stale]     — data may be outdated; channel degraded but still reachable.
/// - [replaying] — catching up on missed events after a reconnect.
/// - [degraded]  — operating in offline / fallback mode.
/// - [unknown]   — initial state before the first connection attempt.
enum SyncState { fresh, stale, replaying, degraded, unknown }
