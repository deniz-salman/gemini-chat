import 'package:hive_flutter/adapters.dart';

part 'chat.g.dart';

@HiveType(typeId: 1)
class Chat {
  @HiveField(1)
  late DateTime createdAt;
}
