class Settings {
  final String key;
  final String value;
  final String? updateAt;

  Settings({
    required this.key,
    required this.value,
    this.updateAt,
  });

  factory Settings.fromMap(Map<String, dynamic> map) {
    return Settings(
      key: map['key'],
      value: map['value'],
      updateAt: map['update_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'value': value,
      'update_at': updateAt,
    };
  }
}
