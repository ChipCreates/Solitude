import 'package:hive/hive.dart';
import 'achievement_category.dart';

class AchievementCategoryAdapter extends TypeAdapter<AchievementCategory> {
  @override
  final int typeId = 1; // Use a different typeId than Achievement (0)

  @override
  AchievementCategory read(BinaryReader reader) {
    final index = reader.readInt();
    return AchievementCategory.values[index];
  }

  @override
  void write(BinaryWriter writer, AchievementCategory obj) {
    writer.writeInt(obj.index);
  }
}