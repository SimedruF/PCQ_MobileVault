class EncryptedArchive {
  final int? id;
  final String name;
  final String description;
  final String filePath;
  final int size;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String algorithm;
  final String keyId;
  final bool isLocked;

  EncryptedArchive({
    this.id,
    required this.name,
    required this.description,
    required this.filePath,
    required this.size,
    required this.createdAt,
    required this.modifiedAt,
    required this.algorithm,
    required this.keyId,
    this.isLocked = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'filePath': filePath,
      'size': size,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'modifiedAt': modifiedAt.millisecondsSinceEpoch,
      'algorithm': algorithm,
      'keyId': keyId,
      'isLocked': isLocked ? 1 : 0,
    };
  }

  factory EncryptedArchive.fromMap(Map<String, dynamic> map) {
    return EncryptedArchive(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      filePath: map['filePath'] ?? '',
      size: map['size']?.toInt() ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(map['modifiedAt']),
      algorithm: map['algorithm'] ?? '',
      keyId: map['keyId'] ?? '',
      isLocked: (map['isLocked'] ?? 0) == 1,
    );
  }

  EncryptedArchive copyWith({
    int? id,
    String? name,
    String? description,
    String? filePath,
    int? size,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? algorithm,
    String? keyId,
    bool? isLocked,
  }) {
    return EncryptedArchive(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      filePath: filePath ?? this.filePath,
      size: size ?? this.size,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      algorithm: algorithm ?? this.algorithm,
      keyId: keyId ?? this.keyId,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
