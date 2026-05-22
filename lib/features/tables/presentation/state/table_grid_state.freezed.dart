// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'table_grid_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TableGridState {

 List<RestaurantTable> get tables; bool get isLoading; String? get errorMessage;
/// Create a copy of TableGridState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TableGridStateCopyWith<TableGridState> get copyWith => _$TableGridStateCopyWithImpl<TableGridState>(this as TableGridState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TableGridState&&const DeepCollectionEquality().equals(other.tables, tables)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(tables),isLoading,errorMessage);

@override
String toString() {
  return 'TableGridState(tables: $tables, isLoading: $isLoading, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $TableGridStateCopyWith<$Res>  {
  factory $TableGridStateCopyWith(TableGridState value, $Res Function(TableGridState) _then) = _$TableGridStateCopyWithImpl;
@useResult
$Res call({
 List<RestaurantTable> tables, bool isLoading, String? errorMessage
});




}
/// @nodoc
class _$TableGridStateCopyWithImpl<$Res>
    implements $TableGridStateCopyWith<$Res> {
  _$TableGridStateCopyWithImpl(this._self, this._then);

  final TableGridState _self;
  final $Res Function(TableGridState) _then;

/// Create a copy of TableGridState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tables = null,Object? isLoading = null,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
tables: null == tables ? _self.tables : tables // ignore: cast_nullable_to_non_nullable
as List<RestaurantTable>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TableGridState].
extension TableGridStatePatterns on TableGridState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TableGridState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TableGridState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TableGridState value)  $default,){
final _that = this;
switch (_that) {
case _TableGridState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TableGridState value)?  $default,){
final _that = this;
switch (_that) {
case _TableGridState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<RestaurantTable> tables,  bool isLoading,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TableGridState() when $default != null:
return $default(_that.tables,_that.isLoading,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<RestaurantTable> tables,  bool isLoading,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _TableGridState():
return $default(_that.tables,_that.isLoading,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<RestaurantTable> tables,  bool isLoading,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _TableGridState() when $default != null:
return $default(_that.tables,_that.isLoading,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _TableGridState implements TableGridState {
  const _TableGridState({final  List<RestaurantTable> tables = const [], this.isLoading = false, this.errorMessage}): _tables = tables;
  

 final  List<RestaurantTable> _tables;
@override@JsonKey() List<RestaurantTable> get tables {
  if (_tables is EqualUnmodifiableListView) return _tables;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tables);
}

@override@JsonKey() final  bool isLoading;
@override final  String? errorMessage;

/// Create a copy of TableGridState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TableGridStateCopyWith<_TableGridState> get copyWith => __$TableGridStateCopyWithImpl<_TableGridState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TableGridState&&const DeepCollectionEquality().equals(other._tables, _tables)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_tables),isLoading,errorMessage);

@override
String toString() {
  return 'TableGridState(tables: $tables, isLoading: $isLoading, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$TableGridStateCopyWith<$Res> implements $TableGridStateCopyWith<$Res> {
  factory _$TableGridStateCopyWith(_TableGridState value, $Res Function(_TableGridState) _then) = __$TableGridStateCopyWithImpl;
@override @useResult
$Res call({
 List<RestaurantTable> tables, bool isLoading, String? errorMessage
});




}
/// @nodoc
class __$TableGridStateCopyWithImpl<$Res>
    implements _$TableGridStateCopyWith<$Res> {
  __$TableGridStateCopyWithImpl(this._self, this._then);

  final _TableGridState _self;
  final $Res Function(_TableGridState) _then;

/// Create a copy of TableGridState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tables = null,Object? isLoading = null,Object? errorMessage = freezed,}) {
  return _then(_TableGridState(
tables: null == tables ? _self._tables : tables // ignore: cast_nullable_to_non_nullable
as List<RestaurantTable>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
