// lib/core/utils/uuid.dart
import 'dart:math';

class UuidGenerator {
  static final Random _secureRandom = Random.secure();

  static String generateV4() {
    final bytes = List<int>.generate(16, (_) => _secureRandom.nextInt(256));

    // Set version to 4
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    // Set variant to RFC 4122
    bytes[8] = (bytes[8] & 0x3F) | 0x80;

    return _bytesToUuid(bytes);
  }

  /// UUIDv7-style generator with millisecond timestamp prefix and secure random tail.
  static String generateV7() {
    final bytes = List<int>.filled(16, 0);
    final timestampMs = DateTime.now().millisecondsSinceEpoch;

    // 48-bit unix timestamp (big endian)
    bytes[0] = (timestampMs >> 40) & 0xFF;
    bytes[1] = (timestampMs >> 32) & 0xFF;
    bytes[2] = (timestampMs >> 24) & 0xFF;
    bytes[3] = (timestampMs >> 16) & 0xFF;
    bytes[4] = (timestampMs >> 8) & 0xFF;
    bytes[5] = timestampMs & 0xFF;

    // Fill remaining bytes with secure randomness.
    for (var i = 6; i < 16; i++) {
      bytes[i] = _secureRandom.nextInt(256);
    }

    // Set version to 7.
    bytes[6] = (bytes[6] & 0x0F) | 0x70;
    // RFC4122 variant.
    bytes[8] = (bytes[8] & 0x3F) | 0x80;

    return _bytesToUuid(bytes);
  }

  static String generateRuntimeId({String? prefix}) {
    final id = generateV7();
    if (prefix == null || prefix.isEmpty) return id;
    return '$prefix-$id';
  }

  static String _bytesToUuid(List<int> bytes) {
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).toList();
    return '${hex[0]}${hex[1]}${hex[2]}${hex[3]}-'
        '${hex[4]}${hex[5]}-'
        '${hex[6]}${hex[7]}-'
        '${hex[8]}${hex[9]}-'
        '${hex[10]}${hex[11]}${hex[12]}${hex[13]}${hex[14]}${hex[15]}';
  }
}
