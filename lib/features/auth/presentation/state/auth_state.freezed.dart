// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthState {

 Organization? get selectedOrg; Branch? get selectedBranch; StaffMember? get loggedInStaff; bool get isShiftStarted; bool get isLocked; DateTime? get shiftStartTime; String? get errorMessage;
/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthStateCopyWith<AuthState> get copyWith => _$AuthStateCopyWithImpl<AuthState>(this as AuthState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthState&&(identical(other.selectedOrg, selectedOrg) || other.selectedOrg == selectedOrg)&&(identical(other.selectedBranch, selectedBranch) || other.selectedBranch == selectedBranch)&&(identical(other.loggedInStaff, loggedInStaff) || other.loggedInStaff == loggedInStaff)&&(identical(other.isShiftStarted, isShiftStarted) || other.isShiftStarted == isShiftStarted)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked)&&(identical(other.shiftStartTime, shiftStartTime) || other.shiftStartTime == shiftStartTime)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,selectedOrg,selectedBranch,loggedInStaff,isShiftStarted,isLocked,shiftStartTime,errorMessage);

@override
String toString() {
  return 'AuthState(selectedOrg: $selectedOrg, selectedBranch: $selectedBranch, loggedInStaff: $loggedInStaff, isShiftStarted: $isShiftStarted, isLocked: $isLocked, shiftStartTime: $shiftStartTime, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $AuthStateCopyWith<$Res>  {
  factory $AuthStateCopyWith(AuthState value, $Res Function(AuthState) _then) = _$AuthStateCopyWithImpl;
@useResult
$Res call({
 Organization? selectedOrg, Branch? selectedBranch, StaffMember? loggedInStaff, bool isShiftStarted, bool isLocked, DateTime? shiftStartTime, String? errorMessage
});




}
/// @nodoc
class _$AuthStateCopyWithImpl<$Res>
    implements $AuthStateCopyWith<$Res> {
  _$AuthStateCopyWithImpl(this._self, this._then);

  final AuthState _self;
  final $Res Function(AuthState) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? selectedOrg = freezed,Object? selectedBranch = freezed,Object? loggedInStaff = freezed,Object? isShiftStarted = null,Object? isLocked = null,Object? shiftStartTime = freezed,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
selectedOrg: freezed == selectedOrg ? _self.selectedOrg : selectedOrg // ignore: cast_nullable_to_non_nullable
as Organization?,selectedBranch: freezed == selectedBranch ? _self.selectedBranch : selectedBranch // ignore: cast_nullable_to_non_nullable
as Branch?,loggedInStaff: freezed == loggedInStaff ? _self.loggedInStaff : loggedInStaff // ignore: cast_nullable_to_non_nullable
as StaffMember?,isShiftStarted: null == isShiftStarted ? _self.isShiftStarted : isShiftStarted // ignore: cast_nullable_to_non_nullable
as bool,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,shiftStartTime: freezed == shiftStartTime ? _self.shiftStartTime : shiftStartTime // ignore: cast_nullable_to_non_nullable
as DateTime?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthState].
extension AuthStatePatterns on AuthState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthState value)  $default,){
final _that = this;
switch (_that) {
case _AuthState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthState value)?  $default,){
final _that = this;
switch (_that) {
case _AuthState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Organization? selectedOrg,  Branch? selectedBranch,  StaffMember? loggedInStaff,  bool isShiftStarted,  bool isLocked,  DateTime? shiftStartTime,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthState() when $default != null:
return $default(_that.selectedOrg,_that.selectedBranch,_that.loggedInStaff,_that.isShiftStarted,_that.isLocked,_that.shiftStartTime,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Organization? selectedOrg,  Branch? selectedBranch,  StaffMember? loggedInStaff,  bool isShiftStarted,  bool isLocked,  DateTime? shiftStartTime,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _AuthState():
return $default(_that.selectedOrg,_that.selectedBranch,_that.loggedInStaff,_that.isShiftStarted,_that.isLocked,_that.shiftStartTime,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Organization? selectedOrg,  Branch? selectedBranch,  StaffMember? loggedInStaff,  bool isShiftStarted,  bool isLocked,  DateTime? shiftStartTime,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _AuthState() when $default != null:
return $default(_that.selectedOrg,_that.selectedBranch,_that.loggedInStaff,_that.isShiftStarted,_that.isLocked,_that.shiftStartTime,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _AuthState implements AuthState {
  const _AuthState({this.selectedOrg, this.selectedBranch, this.loggedInStaff, this.isShiftStarted = false, this.isLocked = false, this.shiftStartTime, this.errorMessage});
  

@override final  Organization? selectedOrg;
@override final  Branch? selectedBranch;
@override final  StaffMember? loggedInStaff;
@override@JsonKey() final  bool isShiftStarted;
@override@JsonKey() final  bool isLocked;
@override final  DateTime? shiftStartTime;
@override final  String? errorMessage;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthStateCopyWith<_AuthState> get copyWith => __$AuthStateCopyWithImpl<_AuthState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthState&&(identical(other.selectedOrg, selectedOrg) || other.selectedOrg == selectedOrg)&&(identical(other.selectedBranch, selectedBranch) || other.selectedBranch == selectedBranch)&&(identical(other.loggedInStaff, loggedInStaff) || other.loggedInStaff == loggedInStaff)&&(identical(other.isShiftStarted, isShiftStarted) || other.isShiftStarted == isShiftStarted)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked)&&(identical(other.shiftStartTime, shiftStartTime) || other.shiftStartTime == shiftStartTime)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,selectedOrg,selectedBranch,loggedInStaff,isShiftStarted,isLocked,shiftStartTime,errorMessage);

@override
String toString() {
  return 'AuthState(selectedOrg: $selectedOrg, selectedBranch: $selectedBranch, loggedInStaff: $loggedInStaff, isShiftStarted: $isShiftStarted, isLocked: $isLocked, shiftStartTime: $shiftStartTime, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$AuthStateCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory _$AuthStateCopyWith(_AuthState value, $Res Function(_AuthState) _then) = __$AuthStateCopyWithImpl;
@override @useResult
$Res call({
 Organization? selectedOrg, Branch? selectedBranch, StaffMember? loggedInStaff, bool isShiftStarted, bool isLocked, DateTime? shiftStartTime, String? errorMessage
});




}
/// @nodoc
class __$AuthStateCopyWithImpl<$Res>
    implements _$AuthStateCopyWith<$Res> {
  __$AuthStateCopyWithImpl(this._self, this._then);

  final _AuthState _self;
  final $Res Function(_AuthState) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? selectedOrg = freezed,Object? selectedBranch = freezed,Object? loggedInStaff = freezed,Object? isShiftStarted = null,Object? isLocked = null,Object? shiftStartTime = freezed,Object? errorMessage = freezed,}) {
  return _then(_AuthState(
selectedOrg: freezed == selectedOrg ? _self.selectedOrg : selectedOrg // ignore: cast_nullable_to_non_nullable
as Organization?,selectedBranch: freezed == selectedBranch ? _self.selectedBranch : selectedBranch // ignore: cast_nullable_to_non_nullable
as Branch?,loggedInStaff: freezed == loggedInStaff ? _self.loggedInStaff : loggedInStaff // ignore: cast_nullable_to_non_nullable
as StaffMember?,isShiftStarted: null == isShiftStarted ? _self.isShiftStarted : isShiftStarted // ignore: cast_nullable_to_non_nullable
as bool,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,shiftStartTime: freezed == shiftStartTime ? _self.shiftStartTime : shiftStartTime // ignore: cast_nullable_to_non_nullable
as DateTime?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
