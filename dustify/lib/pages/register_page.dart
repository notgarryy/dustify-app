import 'package:dustify/services/firebase_manager.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class RegisterPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _RegisterPageState();
  }
}

class _RegisterPageState extends State<RegisterPage> {
  double? devHeight, devWidth;

  FirebaseService? _firebaseService;

  final GlobalKey<FormState> _registerFormKey = GlobalKey<FormState>();

  String? _name, _email, _password;

  bool _obscurePassword = true;

  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _firebaseService = GetIt.instance.get<FirebaseService>();
  }

  @override
  Widget build(BuildContext context) {
    devHeight = MediaQuery.of(context).size.height;
    devWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(29, 28, 28, 1),
        centerTitle: true,
        toolbarHeight: devHeight! * 0.08,
        leading: GestureDetector(
          onTap: () {
            Navigator.popAndPushNamed(context, 'login');
          },
          child: Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      backgroundColor: Color.fromRGBO(34, 31, 31, 1),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: devWidth! * 0.05),
          height: devHeight! * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [_logo(), _registrationForm(), _registerButton()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _registrationForm() {
    return Container(
      height: devHeight! * 0.25,
      child: Form(
        key: _registerFormKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [_nameTextField(), _emailTextField(), _passwordTextField()],
        ),
      ),
    );
  }

  Widget _nameTextField() {
    return TextFormField(
      controller: _nameController,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w500,
        fontSize: 18,
      ),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        hintText: "Name",
        hintStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(Icons.clear, color: Colors.white),
          onPressed: () {
            setState(() {
              _nameController.clear();
            });
          },
        ),
      ),
      validator: (_value) => _value!.isNotEmpty ? null : "Please enter a name",
      onSaved: (_value) {
        setState(() {
          _name = _value;
        });
      },
    );
  }

  Widget _passwordTextField() {
    return TextFormField(
      obscureText: _obscurePassword,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w500,
        fontSize: 18,
      ),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        hintText: "Password",
        hintStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      onSaved: (_value) {
        setState(() {
          _password = _value;
        });
      },
      validator:
          (_value) =>
              _value!.length > 6
                  ? null
                  : "Please enter a password greater than 6 characters.",
    );
  }

  Widget _emailTextField() {
    return TextFormField(
      controller: _emailController,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w500,
        fontSize: 18,
      ),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        hintText: "Email",
        hintStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(Icons.clear, color: Colors.white),
          onPressed: () {
            setState(() {
              _emailController.clear();
            });
          },
        ),
      ),
      onSaved: (_value) {
        setState(() {
          _email = _value;
        });
      },
      validator: (_value) {
        bool _result = _value!.contains(
          RegExp(
            r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
          ),
        );
        return _result ? null : "Please enter a valid email";
      },
    );
  }

  Widget _registerButton() {
    return MaterialButton(
      onPressed: _registerUser,
      minWidth: devWidth! * 0.7,
      height: devHeight! * 0.06,
      color: Colors.orange,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(100)),
      ),
      child: const Text(
        "Register",
        style: TextStyle(
          color: Colors.white,
          fontSize: 25,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _logo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: devHeight! * 0.08,
          width: devHeight! * 0.08,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            image: DecorationImage(
              fit: BoxFit.cover,
              image: AssetImage('assets/images/dustify_logo.png'),
            ),
          ),
        ),
        SizedBox(width: devWidth! * 0.03),
        Container(
          height: devHeight! * 0.08,
          width: devHeight! * 0.2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            image: DecorationImage(
              fit: BoxFit.fitWidth,
              image: AssetImage('assets/images/dustify_branding.png'),
            ),
          ),
        ),
      ],
    );
  }

  void _registerUser() async {
    if (_registerFormKey.currentState!.validate() /*&& _image != null*/ ) {
      _registerFormKey.currentState!.save();
      bool _result = await _firebaseService!.registerUser(
        name: _name!,
        email: _email!,
        password: _password!,
      );
      if (_result) {
        Navigator.pop(context);
      }
    }
  }
}
