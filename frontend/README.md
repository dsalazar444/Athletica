# Athletica Frontend 📱✨

Aplicación móvil multiplataforma desarrollada en **Flutter** para atletas y entrenadores de Athletica. Ofrece una experiencia fluida con una arquitectura MVVM moderna.

## 🛠️ Stack Tecnológico

- **Framework**: [Flutter 3.27+](https://flutter.dev/)
- **Lenguaje**: [Dart](https://dart.dev/)
- **Arquitectura**: MVVM con **Provider** para la gestión de estados.
- **Calidad**: `flutter_lints` (análisis estático estricto).

## 🚀 Ejecución en Desarrollo

### 1. Instalación de Dependencias
Asegúrate de tener el [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado.
```bash
flutter pub get
```

### 2. Ejecutar la Aplicación
Conecta un emulador o dispositivo físico y ejecuta:
```bash
flutter run
```

Para ejecutar en la Web (modo desarrollo):
```bash
flutter run -d chrome
```

## 🔧 Configuración de la API

La aplicación se comunica con el backend a través de la red local. Puedes configurar la URL base de la API en:
`lib/core/config/api_config.dart`

> [!Tip]
> Si estás usando un emulador Android, la dirección del localhost de la máquina suele ser `10.0.2.2`.

## 🧪 Análisis de Calidad
Este proyecto tiene activo el **Linter de Flutter** para asegurar que el código cumple con los mejores estándares.
```bash
flutter analyze
```

---

## 🛡️ Calidad y Tests

Para asegurar la estabilidad del frontend, el CI ejecuta:

- **Linter**: `flutter analyze` para mantener el estándar de código.
- **Tests de Widget**: `flutter test` para validar la interfaz.

Para ejecutar localmente:
```bash
flutter analyze
flutter test
```

## Recursos Originales de Flutter

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)


