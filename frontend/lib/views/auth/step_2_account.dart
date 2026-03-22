import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class Step2Account extends StatefulWidget {
  final Function(String, String, String, String) onNext;

  const Step2Account({super.key, required this.onNext});

  @override
  State<Step2Account> createState() => _Step2AccountState();
}

class _Step2AccountState extends State<Step2Account> {

  final username = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final password2 = TextEditingController();

  bool isValid = false;

  void validate() {
    setState(() {
      isValid =
          username.text.isNotEmpty &&
          email.text.isNotEmpty &&
          password.text.isNotEmpty &&
          password2.text == password.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _input("Username", username),
        _input("Email", email),
        _input("Password", password, isPassword: true),
        _input("Confirmar Password", password2, isPassword: true),

        const Spacer(),

        ElevatedButton(
          onPressed: isValid
              ? () => widget.onNext(
                    username.text,
                    email.text,
                    password.text,
                    password2.text,
                  )
              : null,
          child: const Text("Continuar"),
        )
      ],
    );
  }

  Widget _input(String label, TextEditingController c,
      {bool isPassword = false}) {
    return TextField(
      controller: c,
      obscureText: isPassword,
      onChanged: (_) => validate(),
      decoration: InputDecoration(labelText: label),
    );
  }
}