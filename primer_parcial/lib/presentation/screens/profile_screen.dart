import 'package:flutter/material.dart';
import 'package:primer_parcial/data/users_repository.dart';
import 'package:primer_parcial/domain/models/user.dart';
import 'package:primer_parcial/domain/reporitory/users_repository.dart';

class ProfileScreen extends StatefulWidget {
  final String id;

  const ProfileScreen({super.key, required this.id});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Future<User> userFuture;
  final UsersRepository _repository = LocalUsersRepository();

  @override
  void initState() {
    super.initState();
    userFuture = _repository.getUserById(int.parse(widget.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My profile')),

      body: FutureBuilder<Object>(
        future: userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final user = snapshot.data as User;
          return _UserView(user: user, repository: _repository);
        },
      ),
    );
  }
}

class _UserView extends StatefulWidget {
  final User user;
  final UsersRepository repository;

  _UserView({super.key, required this.user, required this.repository});

  @override
  State<_UserView> createState() => _UserViewState();
}

class _UserViewState extends State<_UserView> {
  TextEditingController inputuser = TextEditingController();
  TextEditingController inputpassword = TextEditingController();
  TextEditingController inputAge = TextEditingController();
  TextEditingController inputTeamFan = TextEditingController();
  TextEditingController inputProfilePicture = TextEditingController();

  @override
  Widget build(BuildContext context) {
    inputuser.text = widget.user.user;
    inputpassword.text = widget.user.password;
    inputAge.text = widget.user.age;
    inputTeamFan.text = widget.user.teamFan;
    inputProfilePicture.text = widget.user.profilePicture ?? "";
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 50),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipOval(
                  child:
                      widget.user.profilePicture != null
                          ? Image.network(
                            widget.user.profilePicture!,
                            width: 200,
                            height: 200,
                            fit: BoxFit.fitHeight,
                            loadingBuilder: (
                              BuildContext context,
                              Widget child,
                              ImageChunkEvent? loadingProgress,
                            ) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              (loadingProgress
                                                      .expectedTotalBytes ??
                                                  1)
                                          : null,
                                ),
                              );
                            },
                            errorBuilder: (
                              BuildContext context,
                              Object error,
                              StackTrace? stackTrace,
                            ) {
                              return Icon(Icons.error, size: 200);
                            },
                          )
                          : Icon(Icons.flag_circle, size: 200),
                ),
                Positioned(
                  right: 0, // Esquina inferior derecha
                  bottom: 0,
                  child: ClipOval(
                    child: Material(
                      color: Colors.black, // Color del botón
                      child: InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: Text("Change profile picture"),
                                  content: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: TextField(
                                      controller: inputProfilePicture,
                                      decoration: InputDecoration(
                                        hintText:
                                            "Enter new profile picture URL",
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(),
                                      child: Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        widget.user.profilePicture =
                                            inputProfilePicture.text;
                                        Navigator.of(context).pop();
                                        widget.repository.updateUser(
                                          widget.user,
                                        );
                                        setState(() {});
                                      },
                                      child: Text("Yes"),
                                    ),
                                  ],
                                ),
                          );
                        },
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(Icons.edit, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),
          Row(
            children: [
              Expanded(
                child: Text(
                  "Username: ${widget.user.user}",
                  style: TextStyle(fontSize: 18),
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text("Edit username"),
                          content: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: inputuser,
                              decoration: InputDecoration(
                                hintText: "Enter new username",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () {
                                widget.user.user = inputuser.text;
                                Navigator.of(context).pop();
                                widget.repository.updateUser(widget.user);
                                setState(() {});
                              },
                              child: Text("Yes"),
                            ),
                          ],
                        ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  "Password: ${widget.user.password}",
                  style: TextStyle(fontSize: 18),
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text("Change password"),
                          content: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: inputpassword,
                              decoration: InputDecoration(
                                hintText: "Enter new password",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () {
                                widget.user.password = inputpassword.text;
                                Navigator.of(context).pop();
                                widget.repository.updateUser(widget.user);
                                setState(() {});
                              },
                              child: Text("Yes"),
                            ),
                          ],
                        ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Text(
                  "Age: ${widget.user.age}",
                  style: TextStyle(fontSize: 18),
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text("Change Age"),
                          content: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: inputAge,
                              decoration: InputDecoration(
                                hintText: "Enter new Age",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () {
                                widget.user.age = inputAge.text;
                                Navigator.of(context).pop();
                                widget.repository.updateUser(widget.user);
                                setState(() {});
                              },
                              child: Text("Yes"),
                            ),
                          ],
                        ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Text(
                  "User's team: ${widget.user.teamFan}",
                  style: TextStyle(fontSize: 18),
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text("Change User's team"),
                          content: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: inputTeamFan,
                              decoration: InputDecoration(
                                hintText: "Enter User's team",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () {
                                widget.user.teamFan = inputTeamFan.text;
                                Navigator.of(context).pop();
                                widget.repository.updateUser(widget.user);
                                setState(() {});
                              },
                              child: Text("Yes"),
                            ),
                          ],
                        ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
