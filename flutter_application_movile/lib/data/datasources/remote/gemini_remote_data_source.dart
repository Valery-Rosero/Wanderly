import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:async';

class GeminiRemoteDataSource {
  final GenerativeModel _model;

  GeminiRemoteDataSource()
    : _model = GenerativeModel(
        // Usar un modelo ampliamente soportado para evitar incompatibilidades
        model: 'gemini-2.0-flash',
        apiKey: 'AIzaSyDUe84YZlDVZs-9vAtOLFEks0yZXoFs7ro', // TODO: mover a .env
      );

  Future<String> obtenerRecomendacion({
    required String message,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final prompt =
          '''
🔍 CONTEXTO DEL USUARIO:
Ubicación actual: $latitude, $longitude
Consulta: "$message"

ROL:
Eres un experto local en turismo, gastronomía y ocio urbano, con acceso a información real sobre lugares públicos, comercios y experiencias en la ciudad y sus alrededores.
Tu misión es recomendar sitios reales, actuales y verificables según la ubicación del usuario y lo que busca (comer, relajarse, explorar, divertirse, etc.).

INSTRUCCIONES:

Identifica la ciudad o territorio, y ofrece mínimo tres recomendaciones principales de lugares reales (restaurantes, parques, museos, cafeterías, etc.) ubicados en la ciudad o alrededores del usuario.

Verifica que los lugares existan realmente (por nombre, barrio o punto de referencia reconocible).

Incluye si es posible:

Nombre y tipo de lugar

Distancia aproximada desde el usuario

Rango de precios o si ofrece domicilios (y número de contacto si se conoce)

Horario o nivel de afluencia típico

Breve descripción realista de por qué lo recomiendas

Mantén un tono natural, confiable y conversacional, como si dieras consejos honestos a un amigo.

Si hay pocos lugares cerca, sugiere opciones razonables en barrios o zonas cercanas.

Si no tienes datos exactos, no inventes nombres, pero sí ofrece alternativas plausibles (“En tu zona suelen encontrarse cafeterías locales sobre la Avenida X o el Parque Y”).

FORMATO SUGERIDO DE RESPUESTA:

1. Recomendaciones principales (3 o más)

Nombre o tipo de lugar

Distancia aproximada

Rango de precios o si ofrece domicilios (con número si se conoce)

Breve descripción realista y personalizada

2. Otras opciones cercanas

2 o 3 lugares adicionales con distancia y reales dentro de la ciudad y una breve nota distintiva

3. Consejos prácticos

Cómo llegar o mejor horario

Qué llevar o tener en cuenta

4. Pregunta final
“¿Quieres que te muestre más opciones similares o de otro tipo?”

REGLAS:

✅ Solo menciona lugares reales o plausibles dentro de la ciudad o sus alrededores.

❌ No inventes lugares.

✅ Prioriza la cercanía, accesibilidad y reputación.

✅ Usa un tono cálido, útil y fluido.

❌ No uses formato especial, efectos ni emojis innecesarios.

ESTRUCTURA ADICIONAL PARA MAPA:
Al final de tu respuesta, agrega UNA línea que comience exactamente con:
JSON_PLACES: {"places":[{"name":"Nombre","lat":12.34,"lng":-56.78,"address":"Dirección","type":"cafeteria"}]}

Reglas para JSON_PLACES:
- Debe ser JSON válido en una sola línea.
- Incluye de 3 a 6 lugares relevantes cercanos.
- Si no estás seguro de coordenadas, usa valores aproximados plausibles de la zona.
''';

      final response = await _model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 20));
      return response.text ?? 'Lo siento, no pude generar una respuesta.';
    } catch (e) {
      throw Exception('Error con Gemini API: $e');
    }
  }
}
