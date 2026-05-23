import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../cart/domain/entities/cart_state.dart';

class CartLocalDataSource {
  static const String _kCartStateKey = 'commerce_cart_persistent_state';
  final SharedPreferences _prefs;

  CartLocalDataSource(this._prefs);

  Future<void> saveCart(CartState state) async {
    try {
      final jsonStr = jsonEncode(state.toJson());
      await _prefs.setString(_kCartStateKey, jsonStr);
      debugPrint('[CartLocalDataSource] Saved cart: $jsonStr');
    } catch (e) {
      debugPrint('[CartLocalDataSource] Error saving cart: $e');
    }
  }

  Future<CartState?> getCart() async {
    return getCartSync();
  }

  CartState? getCartSync() {
    try {
      final jsonStr = _prefs.getString(_kCartStateKey);
      if (jsonStr == null) return null;
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return CartState.fromJson(map);
    } catch (e) {
      debugPrint('[CartLocalDataSource] Error retrieving cart sync: $e');
      return null;
    }
  }

  Future<void> clearCart() async {
    try {
      await _prefs.remove(_kCartStateKey);
      debugPrint('[CartLocalDataSource] Cleared cart state');
    } catch (e) {
      debugPrint('[CartLocalDataSource] Error clearing cart: $e');
    }
  }
}
