class MealRecord {
  final int? id;
  final int athlete;
  final String mealType;
  final String foodName;
  final double portionGrams;
  final double calories;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final String date;
  final String? createdAt;

  MealRecord({
    this.id,
    required this.athlete,
    required this.mealType,
    required this.foodName,
    required this.portionGrams,
    required this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    required this.date,
    this.createdAt,
  });

  factory MealRecord.fromJson(Map<String, dynamic> json) {
    return MealRecord(
      id: json['id'],
      athlete: json['athlete'],
      mealType: json['meal_type'],
      foodName: json['food_name'],
      portionGrams: (json['portion_grams'] as num).toDouble(),
      calories: (json['calories'] as num).toDouble(),
      proteinG: json['protein_g'] != null
          ? (json['protein_g'] as num).toDouble()
          : null,
      carbsG: json['carbs_g'] != null
          ? (json['carbs_g'] as num).toDouble()
          : null,
      fatG: json['fat_g'] != null ? (json['fat_g'] as num).toDouble() : null,
      date: json['date'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'athlete': athlete,
      'meal_type': mealType,
      'food_name': foodName,
      'portion_grams': portionGrams,
      'calories': calories,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatG != null) 'fat_g': fatG,
      'date': date,
    };
  }
}
