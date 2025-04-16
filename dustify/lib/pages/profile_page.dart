import 'package:flutter/material.dart';
import 'package:dustify/services/firebase_manager.dart';
import 'package:get_it/get_it.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  double? devHeight;
  double? devWidth;
  bool? hasUser;

  FirebaseService? _firebaseService;

  @override
  void initState() {
    super.initState();
    _firebaseService = GetIt.instance.get<FirebaseService>();
    final loggedInUser = _firebaseService!.currentFirebaseUser;

    if (loggedInUser == null) {
      hasUser = false;
    } else {
      hasUser = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    devHeight = MediaQuery.of(context).size.height;
    devWidth = MediaQuery.of(context).size.width;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: devHeight! * 0.01),
        Center(
          child:
              hasUser!
                  ? Container(
                    height: devHeight! * 0.23,
                    width: devWidth! * 0.95,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _profileImage(),
                        Container(
                          margin: EdgeInsets.only(bottom: 10),
                          child: Text(
                            "${_firebaseService!.currentUser!["name"]}",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        _logoutButton(),
                      ],
                    ),
                  )
                  : Container(
                    height: devHeight! * 0.2,
                    width: devWidth! * 0.95,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [_profileImage(), _loginButton()],
                    ),
                  ),
        ),
        SizedBox(height: devHeight! * 0.02),
        _placeholder(),
      ],
    );
  }

  Widget _profileImage() {
    return Container(
      margin: EdgeInsets.only(
        top: devHeight! * 0.02,
        bottom: devHeight! * 0.015,
      ),
      height: devHeight! * 0.08,
      width: devHeight! * 0.08,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        image: DecorationImage(
          fit: BoxFit.cover,
          image: AssetImage('assets/images/blank_profile.png'),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: devHeight! * 0.2,
      width: devWidth! * 0.95,
      decoration: BoxDecoration(
        color: Colors.lightBlueAccent,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _loginButton() {
    return MaterialButton(
      padding: EdgeInsets.only(top: 5, bottom: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      onPressed: () {
        Navigator.popAndPushNamed(context, 'login');
      },
      child: Text(
        "Log In >",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _logoutButton() {
    return MaterialButton(
      color: Colors.red,
      padding: EdgeInsets.only(top: 12, bottom: 12, left: 20, right: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      onPressed: () async {
        await _firebaseService!.logout();
        Navigator.popAndPushNamed(context, 'home');
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Log Out",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          SizedBox(width: devWidth! * 0.02),
          const Icon(color: Colors.white, Icons.logout),
        ],
      ),
    );
  }
}
