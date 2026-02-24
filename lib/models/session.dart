import 'package:hive/hive.dart';

part 'session.g.dart';

@HiveType(typeId: 0)
class Session extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime startedAt;

  @HiveField(2)
  final DateTime endedAt;

  @HiveField(3)
  final int durationSeconds;

  @HiveField(4)
  final String taskName;

  @HiveField(5)
  final DateTime createdAt;

  Session({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
    required this.taskName,
    required this.createdAt,
  });
}
