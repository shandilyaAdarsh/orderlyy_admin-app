class RuntimeInitializationException implements Exception {
  final String message;

  RuntimeInitializationException(this.message);

  @override
  String toString() => 'RuntimeInitializationException: $message';
}

String requireContextValue({
  required String? value,
  required String field,
  String? source,
}) {
  if (value == null || value.trim().isEmpty) {
    final origin = source == null ? '' : ' from $source';
    throw RuntimeInitializationException(
      'Missing required runtime context field "$field"$origin.',
    );
  }
  return value;
}
