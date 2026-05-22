// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'orders_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OrdersState {

 List<Order> get orders; LoadingStatus get status; DateTime get lastSyncedAt; Set<String> get optimisticIds; Set<String> get failedIds; AppFailure? get error;
/// Create a copy of OrdersState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrdersStateCopyWith<OrdersState> get copyWith => _$OrdersStateCopyWithImpl<OrdersState>(this as OrdersState, _$identity);

  /// Serializes this OrdersState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrdersState&&const DeepCollectionEquality().equals(other.orders, orders)&&(identical(other.status, status) || other.status == status)&&(identical(other.lastSyncedAt, lastSyncedAt) || other.lastSyncedAt == lastSyncedAt)&&const DeepCollectionEquality().equals(other.optimisticIds, optimisticIds)&&const DeepCollectionEquality().equals(other.failedIds, failedIds)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(orders),status,lastSyncedAt,const DeepCollectionEquality().hash(optimisticIds),const DeepCollectionEquality().hash(failedIds),error);

@override
String toString() {
  return 'OrdersState(orders: $orders, status: $status, lastSyncedAt: $lastSyncedAt, optimisticIds: $optimisticIds, failedIds: $failedIds, error: $error)';
}


}

/// @nodoc
abstract mixin class $OrdersStateCopyWith<$Res>  {
  factory $OrdersStateCopyWith(OrdersState value, $Res Function(OrdersState) _then) = _$OrdersStateCopyWithImpl;
@useResult
$Res call({
 List<Order> orders, LoadingStatus status, DateTime lastSyncedAt, Set<String> optimisticIds, Set<String> failedIds, AppFailure? error
});


$AppFailureCopyWith<$Res>? get error;

}
/// @nodoc
class _$OrdersStateCopyWithImpl<$Res>
    implements $OrdersStateCopyWith<$Res> {
  _$OrdersStateCopyWithImpl(this._self, this._then);

  final OrdersState _self;
  final $Res Function(OrdersState) _then;

/// Create a copy of OrdersState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orders = null,Object? status = null,Object? lastSyncedAt = null,Object? optimisticIds = null,Object? failedIds = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
orders: null == orders ? _self.orders : orders // ignore: cast_nullable_to_non_nullable
as List<Order>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LoadingStatus,lastSyncedAt: null == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime,optimisticIds: null == optimisticIds ? _self.optimisticIds : optimisticIds // ignore: cast_nullable_to_non_nullable
as Set<String>,failedIds: null == failedIds ? _self.failedIds : failedIds // ignore: cast_nullable_to_non_nullable
as Set<String>,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as AppFailure?,
  ));
}
/// Create a copy of OrdersState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppFailureCopyWith<$Res>? get error {
    if (_self.error == null) {
    return null;
  }

  return $AppFailureCopyWith<$Res>(_self.error!, (value) {
    return _then(_self.copyWith(error: value));
  });
}
}


/// Adds pattern-matching-related methods to [OrdersState].
extension OrdersStatePatterns on OrdersState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrdersState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrdersState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrdersState value)  $default,){
final _that = this;
switch (_that) {
case _OrdersState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrdersState value)?  $default,){
final _that = this;
switch (_that) {
case _OrdersState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Order> orders,  LoadingStatus status,  DateTime lastSyncedAt,  Set<String> optimisticIds,  Set<String> failedIds,  AppFailure? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrdersState() when $default != null:
return $default(_that.orders,_that.status,_that.lastSyncedAt,_that.optimisticIds,_that.failedIds,_that.error);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Order> orders,  LoadingStatus status,  DateTime lastSyncedAt,  Set<String> optimisticIds,  Set<String> failedIds,  AppFailure? error)  $default,) {final _that = this;
switch (_that) {
case _OrdersState():
return $default(_that.orders,_that.status,_that.lastSyncedAt,_that.optimisticIds,_that.failedIds,_that.error);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Order> orders,  LoadingStatus status,  DateTime lastSyncedAt,  Set<String> optimisticIds,  Set<String> failedIds,  AppFailure? error)?  $default,) {final _that = this;
switch (_that) {
case _OrdersState() when $default != null:
return $default(_that.orders,_that.status,_that.lastSyncedAt,_that.optimisticIds,_that.failedIds,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrdersState implements OrdersState {
  const _OrdersState({required final  List<Order> orders, required this.status, required this.lastSyncedAt, final  Set<String> optimisticIds = const {}, final  Set<String> failedIds = const {}, this.error}): _orders = orders,_optimisticIds = optimisticIds,_failedIds = failedIds;
  factory _OrdersState.fromJson(Map<String, dynamic> json) => _$OrdersStateFromJson(json);

 final  List<Order> _orders;
@override List<Order> get orders {
  if (_orders is EqualUnmodifiableListView) return _orders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_orders);
}

@override final  LoadingStatus status;
@override final  DateTime lastSyncedAt;
 final  Set<String> _optimisticIds;
@override@JsonKey() Set<String> get optimisticIds {
  if (_optimisticIds is EqualUnmodifiableSetView) return _optimisticIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_optimisticIds);
}

 final  Set<String> _failedIds;
@override@JsonKey() Set<String> get failedIds {
  if (_failedIds is EqualUnmodifiableSetView) return _failedIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_failedIds);
}

@override final  AppFailure? error;

/// Create a copy of OrdersState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrdersStateCopyWith<_OrdersState> get copyWith => __$OrdersStateCopyWithImpl<_OrdersState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrdersStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrdersState&&const DeepCollectionEquality().equals(other._orders, _orders)&&(identical(other.status, status) || other.status == status)&&(identical(other.lastSyncedAt, lastSyncedAt) || other.lastSyncedAt == lastSyncedAt)&&const DeepCollectionEquality().equals(other._optimisticIds, _optimisticIds)&&const DeepCollectionEquality().equals(other._failedIds, _failedIds)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_orders),status,lastSyncedAt,const DeepCollectionEquality().hash(_optimisticIds),const DeepCollectionEquality().hash(_failedIds),error);

@override
String toString() {
  return 'OrdersState(orders: $orders, status: $status, lastSyncedAt: $lastSyncedAt, optimisticIds: $optimisticIds, failedIds: $failedIds, error: $error)';
}


}

/// @nodoc
abstract mixin class _$OrdersStateCopyWith<$Res> implements $OrdersStateCopyWith<$Res> {
  factory _$OrdersStateCopyWith(_OrdersState value, $Res Function(_OrdersState) _then) = __$OrdersStateCopyWithImpl;
@override @useResult
$Res call({
 List<Order> orders, LoadingStatus status, DateTime lastSyncedAt, Set<String> optimisticIds, Set<String> failedIds, AppFailure? error
});


@override $AppFailureCopyWith<$Res>? get error;

}
/// @nodoc
class __$OrdersStateCopyWithImpl<$Res>
    implements _$OrdersStateCopyWith<$Res> {
  __$OrdersStateCopyWithImpl(this._self, this._then);

  final _OrdersState _self;
  final $Res Function(_OrdersState) _then;

/// Create a copy of OrdersState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orders = null,Object? status = null,Object? lastSyncedAt = null,Object? optimisticIds = null,Object? failedIds = null,Object? error = freezed,}) {
  return _then(_OrdersState(
orders: null == orders ? _self._orders : orders // ignore: cast_nullable_to_non_nullable
as List<Order>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LoadingStatus,lastSyncedAt: null == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime,optimisticIds: null == optimisticIds ? _self._optimisticIds : optimisticIds // ignore: cast_nullable_to_non_nullable
as Set<String>,failedIds: null == failedIds ? _self._failedIds : failedIds // ignore: cast_nullable_to_non_nullable
as Set<String>,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as AppFailure?,
  ));
}

/// Create a copy of OrdersState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppFailureCopyWith<$Res>? get error {
    if (_self.error == null) {
    return null;
  }

  return $AppFailureCopyWith<$Res>(_self.error!, (value) {
    return _then(_self.copyWith(error: value));
  });
}
}

// dart format on
