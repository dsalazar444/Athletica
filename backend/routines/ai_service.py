import json
import os

import requests

try:
    import google.generativeai as genai
except ModuleNotFoundError:
    genai = None


def _get_gemini_model():
    """Returns a working Gemini model or None if unavailable."""
    if genai is None:
        return None

    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key or api_key == "tu_api_key_de_gemini_aqui":
        return None

    genai.configure(api_key=api_key)

    # Try model names without the 'models/' prefix (correct for this SDK version)
    for model_name in ["gemini-1.5-flash", "gemini-1.5-pro", "gemini-pro"]:
        try:
            model = genai.GenerativeModel(model_name)
            # Quick smoke test to verify the model actually works
            model.generate_content("Responde solo: ok")
            print(f"Gemini model active: {model_name}")
            return model
        except Exception as e:  # nosec B112
            print(f"Model {model_name} unavailable: {e}")
            continue

    return None


def _search_youtube_video(exercise_name: str) -> str:
    """
    Searches YouTube Data API v3 for an embeddable tutorial video.
    Returns a valid video ID or empty string.
    """
    api_key = os.getenv("YOUTUBE_API_KEY")
    if not api_key:
        return ""

    query = f"{exercise_name} exercise technique tutorial"
    url = "https://www.googleapis.com/youtube/v3/search"
    params = {
        "part": "snippet",
        "q": query,
        "type": "video",
        "videoEmbeddable": "true",
        "safeSearch": "strict",
        "maxResults": 3,
        "relevanceLanguage": "en",
        "key": api_key,
    }

    try:
        response = requests.get(url, params=params, timeout=5)  # nosec B113
        data = response.json()
        items = data.get("items", [])
        if items:
            video_id = items[0]["id"]["videoId"]
            print(f"YouTube: '{exercise_name}' → {video_id}")
            return video_id
    except Exception as e:
        print(f"YouTube search failed for '{exercise_name}': {e}")

    return ""


def _ai_describe_exercise(model, exercise_name: str, muscle: str) -> dict:
    """
    Uses Gemini to generate a specific reason and instructions for one exercise.
    Returns dict with 'reason' and 'instructions'.
    """
    prompt = f"""
    Eres un entrenador personal experto.
    Para el ejercicio "{exercise_name}" (músculo principal: {muscle}), proporciona:

    Responde ÚNICAMENTE con este JSON (sin markdown):
    {{
        "reason": "Beneficio biomecánico principal del ejercicio (máximo 8 palabras)",
        "instructions": "Consejo técnico clave y específico para ejecutarlo bien (máximo 15 palabras)"
    }}
    """
    try:
        response = model.generate_content(prompt)
        text = response.text.strip()
        if text.startswith("```"):
            text = text.split("```")[1]
            if text.startswith("json"):
                text = text[4:]
        return json.loads(text.strip())
    except Exception:
        return {}


def generate_exercise_recommendations(user_profile, workout_history, available_exercises):
    """
    Uses Gemini to generate exercise recommendations with real AI descriptions,
    then enriches each one with a real YouTube video via the Data API.
    """
    model = _get_gemini_model()

    if model is None:
        return _get_mock_recommendations(available_exercises)

    # Prepare context
    profile_str = (
        f"Edad: {user_profile.age} años, "
        f"Altura: {user_profile.height}cm, "
        f"Peso: {user_profile.weight}kg, "
        f"Nivel: {user_profile.activity_level}"
    )
    history_str = "\n".join(
        [
            f"- {session.routine.title} ({session.date.strftime('%d/%m/%Y')})"
            for session in workout_history[:5]
        ]
    )
    exercises_list = ", ".join(
        [f"{ex.name} ({ex.muscle or 'General'})" for ex in available_exercises]
    )

    prompt = f"""
    Eres un entrenador personal de élite de Athletica AI.
    Recomienda exactamente 3 ejercicios para este usuario basándote en su perfil e historial.

    Perfil: {profile_str}
    Historial reciente: {history_str}
    Ejercicios disponibles: {exercises_list}

    Para cada ejercicio proporciona una razón y una instrucción técnica ESPECÍFICA y ÚNICA.

    Devuelve ÚNICAMENTE un arreglo JSON sin ningún texto extra ni markdown:
    [
        {{
            "exercise_name": "Nombre exacto del ejercicio de la lista disponible",
            "reason": "Beneficio biomecánico específico para ESTE usuario (8-10 palabras)",
            "sets": 3,
            "reps": "12",
            "rest": 60,
            "muscle": "Grupo muscular principal",
            "instructions": "Consejo técnico clave y específico para este ejercicio (10-15 palabras)"
        }}
    ]
    """

    try:
        response = model.generate_content(prompt)
        text = response.text.strip()
        if text.startswith("```json"):
            text = text[7:-3].strip()
        elif text.startswith("```"):
            text = text[3:-3].strip()

        recommendations = json.loads(text)

        # Enrich each with a real YouTube video
        for rec in recommendations:
            video_id = _search_youtube_video(rec["exercise_name"])
            rec["youtube_id"] = (
                video_id
                if video_id
                else _fallback_video(rec["exercise_name"], rec.get("muscle", ""))
            )

        return recommendations

    except Exception as e:
        print(f"Error calling Gemini API: {e}")
        return _get_mock_recommendations(available_exercises, model)


def _fallback_video(exercise_name: str, muscle: str) -> str:
    """Last-resort static map when YouTube API is unavailable."""
    name_lower = exercise_name.lower()
    muscle_lower = muscle.lower()

    NAME_MAP = {
        "sentadilla": "gcNh17Ckjgg",
        "squat": "gcNh17Ckjgg",
        "press de banca": "rT7DgCr-3ps",
        "bench": "rT7DgCr-3ps",
        "peso muerto": "ytGaGIn3SjE",
        "deadlift": "ytGaGIn3SjE",
        "jalón": "L815_F4fI3w",
        "lat pulldown": "L815_F4fI3w",
        "kettlebell": "ysS-SAs_X_U",
        "flexion": "IODxDxX7oi4",
        "push up": "IODxDxX7oi4",
        "curl": "3S7T5109-YI",
        "zancada": "QOVaHwm-Q6U",
        "lunge": "QOVaHwm-Q6U",
        "plancha": "Xyd_fa5zoEU",
        "plank": "Xyd_fa5zoEU",
        "dominada": "CAwf7n6Luuc",
        "pull up": "CAwf7n6Luuc",
        "burpee": "dZfeV7UqWls",
        "triceps": "6kALZH_vSNo",
        "press militar": "2yjwxt1bcZ8",
        "remo": "L815_F4fI3w",
    }
    MUSCLE_MAP = {
        "espalda": "L815_F4fI3w",
        "pecho": "rT7DgCr-3ps",
        "pierna": "gcNh17Ckjgg",
        "hombro": "2yjwxt1bcZ8",
        "brazo": "3S7T5109-YI",
        "abdomen": "Xyd_fa5zoEU",
        "core": "Xyd_fa5zoEU",
        "isquio": "ytGaGIn3SjE",
        "glúte": "QOVaHwm-Q6U",
    }

    for key, val in NAME_MAP.items():
        if key in name_lower:
            return val
    for key, val in MUSCLE_MAP.items():
        if key in muscle_lower or key in name_lower:
            return val
    return "gcNh17Ckjgg"


def _get_mock_recommendations(available_exercises, model=None):
    """
    Fallback: selects exercises based on user profile data and uses Gemini
    (if available) to generate specific reason and instructions per exercise.
    """
    import random

    if not available_exercises:
        return [
            {
                "exercise_name": "Sentadilla",
                "reason": "Ejercicio fundamental para desarrollar fuerza en el tren inferior.",
                "sets": 3,
                "reps": "12",
                "rest": 60,
                "muscle": "Piernas",
                "instructions": "Pies a anchura de hombros, espalda recta, baja hasta paralelo.",
                "youtube_id": "gcNh17Ckjgg",
            }
        ]

    selected = random.sample(list(available_exercises), min(len(available_exercises), 3))  # nosec B311
    results = []

    for ex in selected:
        # Get YouTube video
        video_id = _search_youtube_video(ex.name)
        if not video_id:
            video_id = _fallback_video(ex.name, ex.muscle or "")

        # Use Gemini for specific descriptions if available
        ai_description = {}
        if model:
            ai_description = _ai_describe_exercise(model, ex.name, ex.muscle or "General")

        results.append(
            {
                "exercise_name": ex.name,
                "reason": ai_description.get("reason")
                or f"Trabaja {ex.muscle or 'músculos clave'} y mejora tu rendimiento general.",  # nosec B311
                "sets": 3,
                "reps": "12",
                "rest": 60,
                "muscle": ex.muscle if ex.muscle else "General",
                "instructions": ai_description.get("instructions")
                or f"Ejecuta {ex.name} con técnica precisa en cada repetición.",
                "youtube_id": video_id,
            }
        )

    return results
