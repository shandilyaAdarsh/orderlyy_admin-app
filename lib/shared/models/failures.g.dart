// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'failures.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServerFailure _$ServerFailureFromJson(Map<String, dynamic> json) =>
    ServerFailure(
      message: json['message'] as String,
      statusCode: (json['statusCode'] as num?)?.toInt(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$ServerFailureToJson(ServerFailure instance) =>
    <String, dynamic>{
      'message': instance.message,
      'statusCode': instance.statusCode,
      'runtimeType': instance.$type,
    };

NetworkFailure _$NetworkFailureFromJson(Map<String, dynamic> json) =>
    NetworkFailure(
      message: json['message'] as String,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$NetworkFailureToJson(NetworkFailure instance) =>
    <String, dynamic>{
      'message': instance.message,
      'runtimeType': instance.$type,
    };

CacheFailure _$CacheFailureFromJson(Map<String, dynamic> json) => CacheFailure(
  message: json['message'] as String,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$CacheFailureToJson(CacheFailure instance) =>
    <String, dynamic>{
      'message': instance.message,
      'runtimeType': instance.$type,
    };

NotFoundFailure _$NotFoundFailureFromJson(Map<String, dynamic> json) =>
    NotFoundFailure(
      message: json['message'] as String,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$NotFoundFailureToJson(NotFoundFailure instance) =>
    <String, dynamic>{
      'message': instance.message,
      'runtimeType': instance.$type,
    };

ValidationFailure _$ValidationFailureFromJson(Map<String, dynamic> json) =>
    ValidationFailure(
      message: json['message'] as String,
      errors: (json['errors'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$ValidationFailureToJson(ValidationFailure instance) =>
    <String, dynamic>{
      'message': instance.message,
      'errors': instance.errors,
      'runtimeType': instance.$type,
    };

UnauthorizedFailure _$UnauthorizedFailureFromJson(Map<String, dynamic> json) =>
    UnauthorizedFailure(
      message: json['message'] as String,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$UnauthorizedFailureToJson(
  UnauthorizedFailure instance,
) => <String, dynamic>{
  'message': instance.message,
  'runtimeType': instance.$type,
};

UnknownFailure _$UnknownFailureFromJson(Map<String, dynamic> json) =>
    UnknownFailure(
      message: json['message'] as String,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$UnknownFailureToJson(UnknownFailure instance) =>
    <String, dynamic>{
      'message': instance.message,
      'runtimeType': instance.$type,
    };
