class CryptoKey {
  final String id;
  final String name;
  final String algorithm;
  final String publicKey;
  final String privateKey;
  final DateTime createdAt;
  final bool isDefault;

  CryptoKey({
    required this.id,
    required this.name,
    required this.algorithm,
    required this.publicKey,
    required this.privateKey,
    required this.createdAt,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'algorithm': algorithm,
      'publicKey': publicKey,
      'privateKey': privateKey,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isDefault': isDefault ? 1 : 0,
    };
  }

  factory CryptoKey.fromMap(Map<String, dynamic> map) {
    return CryptoKey(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      algorithm: map['algorithm'] ?? '',
      publicKey: map['publicKey'] ?? '',
      privateKey: map['privateKey'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      isDefault: (map['isDefault'] ?? 0) == 1,
    );
  }
}

enum PQCAlgorithm {
  kyber512('Kyber-512', 'Kyber512'),
  kyber768('Kyber-768', 'Kyber768'),
  kyber1024('Kyber-1024', 'Kyber1024'),
  dilithium2('Dilithium-2', 'Dilithium2'),
  dilithium3('Dilithium-3', 'Dilithium3'),
  dilithium5('Dilithium-5', 'Dilithium5'),
  falcon512('Falcon-512', 'Falcon512'),
  falcon1024('Falcon-1024', 'Falcon1024');

  const PQCAlgorithm(this.displayName, this.technicalName);

  final String displayName;
  final String technicalName;

  static PQCAlgorithm fromString(String value) {
    return PQCAlgorithm.values.firstWhere(
      (algorithm) => algorithm.technicalName == value,
      orElse: () => PQCAlgorithm.kyber512,
    );
  }
}
