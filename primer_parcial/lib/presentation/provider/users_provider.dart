import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:primer_parcial/data/football_teams_repository.dart';
import 'package:primer_parcial/data/users_list.dart';
import 'package:primer_parcial/domain/models/team.dart';
import 'package:primer_parcial/domain/user.dart';

StateProvider<List<User>> teamListProvider = StateProvider<List<User>>(
  (ref) => usersList,
);
