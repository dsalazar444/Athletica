import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class Step2Personal extends StatefulWidget {
  final Function(
    String name,
    String age,
    String weight,
    String height,
    String gender,
  )
  onNext;

  const Step2Personal({super.key, required this.onNext});

  @override
  State<Step2Personal> createState() => _Step2PersonalState();
}

class _Step2PersonalState extends State<Step2Personal> {
  final name = TextEditingController();
  final age = TextEditingController();
  final weight = TextEditingController();
  final height = TextEditingController();

  // Genero se maneja con dropdown en lugar de texto libre.
  String? selectedGender;

  // Mensajes de error por campo — null significa que no hay error.
  String? nameError;
  String? ageError;
  String? weightError;
  String? heightError;
  String? genderError;

  bool isValid = false;

  // Valida cada campo y actualiza los mensajes de error.
  void validate() {
    setState(() {
      nameError = _validateName(name.text);
      ageError = _validateAge(age.text);
      weightError = _validateWeight(weight.text);
      heightError = _validateHeight(height.text);
      genderError = selectedGender == null ? 'Selecciona un genero' : null;

      isValid =
          nameError == null &&
          ageError == null &&
          weightError == null &&
          heightError == null &&
          genderError == null;
    });
  }

  // Solo letras y espacios, minimo 2 caracteres.
  String? _validateName(String value) {
    if (value.isEmpty) return 'El nombre es requerido';
    if (value.length < 2) return 'El nombre debe tener al menos 2 caracteres';
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+$').hasMatch(value)) {
      return 'El nombre solo puede contener letras';
    }
    return null;
  }

  // Solo numeros enteros, rango entre 10 y 100 anos.
  String? _validateAge(String value) {
    if (value.isEmpty) return 'La edad es requerida';
    final parsed = int.tryParse(value);
    if (parsed == null) return 'La edad debe ser un numero entero';
    if (parsed < 10 || parsed > 100) return 'La edad debe estar entre 10 y 100';
    return null;
  }

  // Solo numeros decimales, rango entre 30 y 300 kg.
  String? _validateWeight(String value) {
    if (value.isEmpty) return 'El peso es requerido';
    final parsed = double.tryParse(value);
    if (parsed == null) return 'El peso debe ser un numero';
    if (parsed < 30 || parsed > 300)
      return 'El peso debe estar entre 30 y 300 kg';
    return null;
  }

  // Solo numeros, rango entre 50 y 250 cm.
  String? _validateHeight(String value) {
    if (value.isEmpty) return 'La altura es requerida';
    final parsed = double.tryParse(value);
    if (parsed == null) return 'La altura debe ser un numero';
    if (parsed < 50 || parsed > 250)
      return 'La altura debe estar entre 50 y 250 cm';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Datos personales',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          const Text(
            'Cuentanos un poco sobre ti',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),

          _input('Nombre', name, nameError),
          const SizedBox(height: 15),

          _input('Edad', age, ageError, isNumber: true),
          const SizedBox(height: 15),

          _input('Peso (kg)', weight, weightError, isDecimal: true),
          const SizedBox(height: 15),

          _input('Altura (cm)', height, heightError, isDecimal: true),
          const SizedBox(height: 15),

          // Dropdown para seleccion de genero.
          DropdownButtonFormField<String>(
            value: selectedGender,
            decoration: InputDecoration(
              labelText: 'Genero',
              filled: true,
              fillColor: AppColors.surfaceVariant,
              errorText: genderError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'male', child: Text('Masculino')),
              DropdownMenuItem(value: 'female', child: Text('Femenino')),
              DropdownMenuItem(value: 'other', child: Text('Otro')),
            ],
            onChanged: (value) {
              setState(() => selectedGender = value);
              validate();
            },
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isValid
                  ? () => widget.onNext(
                      name.text,
                      age.text,
                      weight.text,
                      height.text,
                      selectedGender!,
                    )
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Continuar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(
    String label,
    TextEditingController c,
    String? errorText, {
    bool isNumber = false,
    bool isDecimal = false,
  }) {
    return TextField(
      controller: c,
      keyboardType: isDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : isNumber
          ? TextInputType.number
          : TextInputType.text,
      onChanged: (_) => validate(),
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
