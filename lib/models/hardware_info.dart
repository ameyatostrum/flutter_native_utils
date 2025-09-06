import 'dart:convert';

/// A container for hardware identifier values retrieved from the system.
///
/// Both fields may be `null` if the underlying platform fails to provide
/// a value.
class HardwareInfo {
  /// The unique CPU identifier, if available.
  final String? systemCpuId;

  /// The unique motherboard / baseboard identifier, if available.
  final String? systemBoardId;

  /// Creates a new [HardwareInfo] instance with optional identifiers.
  HardwareInfo({
    required this.systemCpuId,
    required this.systemBoardId,
  });

  HardwareInfo copyWith({
    String? systemCpuId,
    String? systemBoardId,
  }) {
    return HardwareInfo(
      systemCpuId: systemCpuId ?? this.systemCpuId,
      systemBoardId: systemBoardId ?? this.systemBoardId,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'systemCpuId': systemCpuId,
      'systemBoardId': systemBoardId,
    };
  }

  factory HardwareInfo.fromMap(Map<dynamic, dynamic> map) {
    return HardwareInfo(
      systemCpuId:
          map['systemCpuId'] != null ? map['systemCpuId'] as String : null,
      systemBoardId:
          map['systemBoardId'] != null ? map['systemBoardId'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory HardwareInfo.fromJson(String source) =>
      HardwareInfo.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'HardwareInfo(systemCpuId: $systemCpuId, systemBoardId: $systemBoardId)';

  @override
  bool operator ==(covariant HardwareInfo other) {
    if (identical(this, other)) return true;

    return other.systemCpuId == systemCpuId &&
        other.systemBoardId == systemBoardId;
  }

  @override
  int get hashCode => systemCpuId.hashCode ^ systemBoardId.hashCode;
}
