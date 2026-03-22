enum DifficultyLevel { beginner, intermediate, advanced }
 
enum CategoryType { hybrid, strength, cardio, flexibility }

enum MuscleGroup { chest, back, shoulders, arms, legs, abdominal, lowerBack }

// Converts DifficultyLevel enum to a user-friendly string
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

// Converts CategoryType enum to a user-friendly string
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

// Converts MuscleGroup enum to a user-friendly string
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