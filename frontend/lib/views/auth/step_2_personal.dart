import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';

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
    if (parsed < 30 || parsed > 300) {
      return 'El peso debe estar entre 30 y 300 kg';
    }
    return null;
  }

  // Solo numeros, rango entre 50 y 250 cm.
  String? _validateHeight(String value) {
    if (value.isEmpty) return 'La altura es requerida';
    final parsed = double.tryParse(value);
    if (parsed == null) return 'La altura debe ser un numero';
    if (parsed < 50 || parsed > 250) {
      return 'La altura debe estar entre 50 y 250 cm';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Datos personales', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 8),
          Text(
            'Cuéntanos un poco sobre ti para ajustar tus cálculos.',
            style: AppTextStyles.sectionSubtitle,
          ),
          const SizedBox(height: 32),

          _input(
            'Nombre completo',
            name,
            nameError,
            icon: Icons.person_pin_outlined,
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _input(
                  'Edad',
                  age,
                  ageError,
                  isNumber: true,
                  icon: Icons.calendar_today_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Género', style: AppTextStyles.inputLabel),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedGender,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.wc_outlined,
                          color: AppColors.textHint,
                          size: 18,
                        ),
                        errorText: genderError,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 16,
                        ),
                      ),
                      style: AppTextStyles.inputText.copyWith(fontSize: 13),
                      items: const [
                        DropdownMenuItem(
                          value: 'male',
                          child: Text('Masculino'),
                        ),
                        DropdownMenuItem(
                          value: 'female',
                          child: Text('Femenino'),
                        ),
                        DropdownMenuItem(value: 'other', child: Text('Otro')),
                      ],
                      onChanged: (value) {
                        setState(() => selectedGender = value);
                        validate();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _input(
                  'Peso (kg)',
                  weight,
                  weightError,
                  isDecimal: true,
                  icon: Icons.monitor_weight_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _input(
                  'Altura (cm)',
                  height,
                  heightError,
                  isDecimal: true,
                  icon: Icons.height_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 48),

          SizedBox(
            width: double.infinity,
            height: 58,
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
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
              ),
              child: const Text(
                'Continuar',
                style: AppTextStyles.buttonPrimary,
              ),
            ),
          ),
          const SizedBox(height: 48),
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
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.inputLabel),
        const SizedBox(height: 8),
        TextField(
          controller: c,
          keyboardType: isDecimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : isNumber
              ? TextInputType.number
              : TextInputType.text,
          onChanged: (_) => validate(),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.textHint, size: 22),
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}
