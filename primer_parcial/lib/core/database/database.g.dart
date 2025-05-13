// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $AppDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  TeamsDao? _teamsDaoInstance;

  UsersDao? _usersDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Team` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `country` TEXT NOT NULL, `confederation` TEXT NOT NULL, `worldCups` INTEGER NOT NULL, `isWorldChampion` INTEGER NOT NULL, `flag` TEXT)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `User` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `user` TEXT NOT NULL, `password` TEXT NOT NULL, `age` TEXT NOT NULL, `teamFan` TEXT NOT NULL, `profilePicture` TEXT)');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  TeamsDao get teamsDao {
    return _teamsDaoInstance ??= _$TeamsDao(database, changeListener);
  }

  @override
  UsersDao get usersDao {
    return _usersDaoInstance ??= _$UsersDao(database, changeListener);
  }
}

class _$TeamsDao extends TeamsDao {
  _$TeamsDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _teamInsertionAdapter = InsertionAdapter(
            database,
            'Team',
            (Team item) => <String, Object?>{
                  'id': item.id,
                  'country': item.country,
                  'confederation': item.confederation,
                  'worldCups': item.worldCups,
                  'isWorldChampion': item.isWorldChampion,
                  'flag': item.flag
                }),
        _teamUpdateAdapter = UpdateAdapter(
            database,
            'Team',
            ['id'],
            (Team item) => <String, Object?>{
                  'id': item.id,
                  'country': item.country,
                  'confederation': item.confederation,
                  'worldCups': item.worldCups,
                  'isWorldChampion': item.isWorldChampion,
                  'flag': item.flag
                }),
        _teamDeletionAdapter = DeletionAdapter(
            database,
            'Team',
            ['id'],
            (Team item) => <String, Object?>{
                  'id': item.id,
                  'country': item.country,
                  'confederation': item.confederation,
                  'worldCups': item.worldCups,
                  'isWorldChampion': item.isWorldChampion,
                  'flag': item.flag
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Team> _teamInsertionAdapter;

  final UpdateAdapter<Team> _teamUpdateAdapter;

  final DeletionAdapter<Team> _teamDeletionAdapter;

  @override
  Future<List<Team>> findAllTeams() async {
    return _queryAdapter.queryList('SELECT * FROM Team',
        mapper: (Map<String, Object?> row) => Team(
            id: row['id'] as int?,
            country: row['country'] as String,
            confederation: row['confederation'] as String,
            worldCups: row['worldCups'] as int,
            isWorldChampion: row['isWorldChampion'] as int,
            flag: row['flag'] as String?));
  }

  @override
  Future<Team?> findTeamById(int id) async {
    return _queryAdapter.query('SELECT * FROM Team WHERE id = ?1',
        mapper: (Map<String, Object?> row) => Team(
            id: row['id'] as int?,
            country: row['country'] as String,
            confederation: row['confederation'] as String,
            worldCups: row['worldCups'] as int,
            isWorldChampion: row['isWorldChampion'] as int,
            flag: row['flag'] as String?),
        arguments: [id]);
  }

  @override
  Future<void> insertTeam(Team team) async {
    await _teamInsertionAdapter.insert(team, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateTeam(Team team) async {
    await _teamUpdateAdapter.update(team, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteTeam(Team team) async {
    await _teamDeletionAdapter.delete(team);
  }
}

class _$UsersDao extends UsersDao {
  _$UsersDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _userInsertionAdapter = InsertionAdapter(
            database,
            'User',
            (User item) => <String, Object?>{
                  'id': item.id,
                  'user': item.user,
                  'password': item.password,
                  'age': item.age,
                  'teamFan': item.teamFan,
                  'profilePicture': item.profilePicture
                }),
        _userUpdateAdapter = UpdateAdapter(
            database,
            'User',
            ['id'],
            (User item) => <String, Object?>{
                  'id': item.id,
                  'user': item.user,
                  'password': item.password,
                  'age': item.age,
                  'teamFan': item.teamFan,
                  'profilePicture': item.profilePicture
                }),
        _userDeletionAdapter = DeletionAdapter(
            database,
            'User',
            ['id'],
            (User item) => <String, Object?>{
                  'id': item.id,
                  'user': item.user,
                  'password': item.password,
                  'age': item.age,
                  'teamFan': item.teamFan,
                  'profilePicture': item.profilePicture
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<User> _userInsertionAdapter;

  final UpdateAdapter<User> _userUpdateAdapter;

  final DeletionAdapter<User> _userDeletionAdapter;

  @override
  Future<List<User>> findAllUsers() async {
    return _queryAdapter.queryList('SELECT * FROM User',
        mapper: (Map<String, Object?> row) => User(
            id: row['id'] as int?,
            user: row['user'] as String,
            password: row['password'] as String,
            age: row['age'] as String,
            teamFan: row['teamFan'] as String,
            profilePicture: row['profilePicture'] as String?));
  }

  @override
  Future<User?> findUserById(int id) async {
    return _queryAdapter.query('SELECT * FROM Team WHERE id = ?1',
        mapper: (Map<String, Object?> row) => User(
            id: row['id'] as int?,
            user: row['user'] as String,
            password: row['password'] as String,
            age: row['age'] as String,
            teamFan: row['teamFan'] as String,
            profilePicture: row['profilePicture'] as String?),
        arguments: [id]);
  }

  @override
  Future<void> insertUser(User user) async {
    await _userInsertionAdapter.insert(user, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateUser(User user) async {
    await _userUpdateAdapter.update(user, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteUser(User user) async {
    await _userDeletionAdapter.delete(user);
  }
}
