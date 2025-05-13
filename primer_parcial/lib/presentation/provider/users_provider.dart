import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:primer_parcial/domain/models/user.dart';

import 'dart:ui';

final userNotifierProvider = StateNotifierProvider<UserNotifier, UserProvider>(
  (ref) => UserNotifier(),
);

class UserNotifier extends StateNotifier<UserProvider> {
  UserNotifier() : super(UserProvider());

  void setUserId(int id) {
    state = state.copyWith(id: id);
  }
}
