import 'package:dustify/pages/data_page.dart';
import 'package:dustify/pages/login_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentPage = 0;

  final List<Widget> _pages = [DataPage(), LoginPage()];

  @override
  Widget build(BuildContext context) {
    double? devHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Color.fromRGBO(34, 31, 31, 1),
      appBar: AppBar(
        title: Text(
          "Dustify",
          style: TextStyle(fontFamily: 'BungeeSpice', fontSize: 40),
        ),
        backgroundColor: Color.fromRGBO(29, 28, 28, 1),
        centerTitle: true,
        toolbarHeight: devHeight * 0.08,
      ),
      bottomNavigationBar: _bottomNavBar(),
      body: _pages[_currentPage],
    );
  }

  Widget _bottomNavBar() {
    return BottomNavigationBar(
      elevation: 2,
      backgroundColor: Color.fromRGBO(29, 28, 28, 1),
      currentIndex: _currentPage,
      onTap: (index) {
        setState(() {
          _currentPage = index;
        });
      },
      selectedItemColor: Colors.white,
      unselectedItemColor: Color.fromRGBO(133, 133, 133, 0.7),
      items: [
        BottomNavigationBarItem(label: "Home", icon: Icon(Icons.home_filled)),
        BottomNavigationBarItem(
          label: "Profile",
          icon: Icon(Icons.account_box),
        ),
      ],
    );
  }
}
