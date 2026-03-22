import 'package:flutter/material.dart';

class Step2Personal extends StatefulWidget {
  final Function(
    String name,
    String age,
    String weight,
    String height,
    String gender,
  ) onNext;

  const Step2Personal({super.key, required this.onNext});

  @override
  State<Step2Personal> createState() => _Step2PersonalState();
}

class _Step2PersonalState extends State<Step2Personal> {

  final name = TextEditingController();
  final age = TextEditingController();
  final weight = TextEditingController();
  final height = TextEditingController();

  final gender = TextEditingController();

  bool isValid = false;

  void validate() {
    setState(() {
      isValid =
          name.text.isNotEmpty &&
          age.text.isNotEmpty &&
          weight.text.isNotEmpty &&
          height.text.isNotEmpty &&
          gender.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _input("Nombre", name),
        _input("Edad", age),
        _input("Peso", weight),
        _input("Altura", height),

        _input("Genero", gender),

        const Spacer(),

        ElevatedButton(
          onPressed: isValid
              ? () => widget.onNext(
                    name.text,
                    age.text,
                    weight.text,
                    height.text,
                    gender.text,
                  )
              : null,
          child: const Text("Continuar"),
        )
      ],
    );
  }

  Widget _input(String label, TextEditingController c) {
    return TextField(
      controller: c,
      onChanged: (_) => validate(),
      decoration: InputDecoration(labelText: label),
    );
  }
}