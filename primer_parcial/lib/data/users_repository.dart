import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:primer_parcial/data/dao/users_dao.dart';
import 'package:primer_parcial/domain/models/user.dart';
import 'package:primer_parcial/domain/reporitory/users_repository.dart';
import '../main.dart';

/* final usersList = [
  User(user: "Francisco", password: "Burnes"),
  User(user: "Julian", password: "Gonzalez"),
  User(user: "Pepo", password: "Yañez"),
  User(user: "colo", password: "pereira"),
]; */

class LocalUsersRepository implements UsersRepository {
  final UsersDao _UsersDao = database.usersDao;

  @override
  Future<List<User>> getUsers() {
    return _UsersDao.findAllUsers();
  }

  @override
  Future<User> getUserById(int id) async {
    final users = await getUsers();
    final user = users.firstWhere((m) => m.id == id);
    return Future.delayed(const Duration(seconds: 0), () => user);
  }

  @override
  Future<void> insertUser(User user) async {
    await _UsersDao.insertUser(user);
  }

  @override
  Future<void> updateUser(User user) async {
    await _UsersDao.updateUser(user);
  }

  @override
  Future<void> deleteUser(User user) async {
    await _UsersDao.deleteUser(user);
  }
}

class JsonUsersRepository implements UsersRepository {
  @override
  Future<List<User>> getUsers() {
    return Future.delayed(const Duration(seconds: 0), () async {
      final jsonString = await rootBundle.loadString('assets/users.json');
      final jsonList = json.decode(jsonString) as List;
      final users = jsonList.map((json) => User.fromJson(json)).toList();

      return users;
    });
  }

  @override
  Future<User> getUserById(int id) async {
    final users = await getUsers();
    final user = users.firstWhere((m) => m.id == id);
    return Future.delayed(const Duration(seconds: 0), () => user);
  }

  @override
  Future<void> insertUser(User user) {
    return Future.delayed(const Duration(seconds: 0), () => null);
  }

  @override
  Future<void> updateUser(User user) {
    return Future.delayed(const Duration(seconds: 0), () => null);
  }

  @override
  Future<void> deleteUser(User user) {
    return Future.delayed(const Duration(seconds: 0), () => null);
  }
}
