import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_controller.dart';
import '../pages/login_page.dart';
import '../pages/register_page.dart';
import '../pages/forgot_password_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.home});
  final Widget home;

  @override State<AuthGate> createState()=>_AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  int _page = 0; // 0 login 1 register 2 forgot 3 home

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthController>();
    auth.isLoggedIn().then((v) => setState(()=> _page = v ? 3 : 0));
  }

  @override
  Widget build(BuildContext ctx) {
    switch (_page) {
      case 1: return RegisterPage(onDone: ()=> setState(()=> _page = 0));
      case 2: return ForgotPasswordPage(onDone: ()=> setState(()=> _page = 0));
      case 3: return Scaffold(
        body: widget.home,
        appBar: AppBar(actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () async {
            await context.read<AuthController>().logout();
            setState(()=> _page = 0);
          })
        ]),
      );
      default: return LoginPage(
        onLoggedIn: ()=> setState(()=> _page = 3),
        onGoRegister: ()=> setState(()=> _page = 1),
        onGoForgot: ()=> setState(()=> _page = 2),
      );
    }
  }
}
