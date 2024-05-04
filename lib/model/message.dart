
import 'package:hive_flutter/adapters.dart';

part 'message.g.dart';

@HiveType(typeId: 2)
class Message {
  @HiveField(0)
  late String prompt;
  @HiveField(1)
  String? promptImageId;
  @HiveField(2)
  String? response;
  @HiveField(3)
  late int chatId;
  @HiveField(4)
  late DateTime createdAt;
}
