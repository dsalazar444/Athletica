/// Definición de los niveles de dificultad disponibles para las rutinas.
enum DifficultyLevel { beginner, intermediate, advanced }
 
/// Tipos de categorías en las que se puede clasificar un entrenamiento.
enum CategoryType { hybrid, strength, cardio, flexibility }

/// Grupos musculares principales para el filtrado de ejercicios.
enum MuscleGroup { chest, back, shoulders, arms, legs, abdominal, lowerBack }

/// Convierte el valor del enum [DifficultyLevel] en un nombre legible en español.
String difficultyLevelToString(DifficultyLevel level) {
	switch (level) {
		case DifficultyLevel.beginner:
			return 'Principiante';
		case DifficultyLevel.intermediate:
			return 'Intermedio';
		case DifficultyLevel.advanced:
			return 'Avanzado';
	}
}

/// Convierte el valor del enum [CategoryType] en un nombre legible en español para la UI.
String categoryTypeToString(CategoryType category) {
	switch (category) {
		case CategoryType.hybrid:
			return 'Híbrido';
		case CategoryType.strength:
			return 'Fuerza';
		case CategoryType.cardio:
			return 'Cardio';
		case CategoryType.flexibility:
			return 'Flexibilidad';
	}
}

/// Convierte el valor del enum [MuscleGroup] en el nombre del músculo correspondiente en español.
String muscleGroupToString(MuscleGroup group) {
	switch (group) {
		case MuscleGroup.chest:
			return 'Pecho';
		case MuscleGroup.back:
			return 'Espalda';
		case MuscleGroup.shoulders:
			return 'Hombros';
		case MuscleGroup.arms:
			return 'Brazos';
		case MuscleGroup.legs:
			return 'Piernas';
		case MuscleGroup.abdominal:
			return 'Abdominales';
		case MuscleGroup.lowerBack:
			return 'Zona lumbar';
	}
}