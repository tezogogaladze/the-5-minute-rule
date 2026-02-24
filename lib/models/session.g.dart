// GENERATED CODE - DO NOT MODIFY BY HAND
// Manually authored TypeAdapter (equivalent to build_runner output)

part of 'session.dart';

class SessionAdapter extends TypeAdapter<Session> {
  @override
  final int typeId = 0;

  @override
  Session read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Session(
      id: fields[0] as String,
      startedAt: DateTime.fromMillisecondsSinceEpoch(fields[1] as int),
      endedAt: DateTime.fromMillisecondsSinceEpoch(fields[2] as int),
      durationSeconds: fields[3] as int,
      taskName: fields[4] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[5] as int),
    );
  }

  @override
  void write(BinaryWriter writer, Session obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.startedAt.millisecondsSinceEpoch)
      ..writeByte(2)
      ..write(obj.endedAt.millisecondsSinceEpoch)
      ..writeByte(3)
      ..write(obj.durationSeconds)
      ..writeByte(4)
      ..write(obj.taskName)
      ..writeByte(5)
      ..write(obj.createdAt.millisecondsSinceEpoch);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
