import 'package:translator/translator.dart';

/// Servicio encargado de traducir textos automáticamente usando Google Translate.
class TranslationService {
  final GoogleTranslator _translator = GoogleTranslator();

  /// Traduce un texto al español (es) de forma asíncrona.
  /// Si ocurre un error, retorna el texto original para no bloquear la app.
  Future<String> translateToSpanish(String text) async {
    if (text.isEmpty) return text;
    try {
      final translation = await _translator.translate(text, from: 'en', to: 'es');
      return translation.text;
    } catch (e) {
      // Retornar original en caso de fallo (ej. sin conexión o límite de cuota).
      return text;
    }
  }
}
