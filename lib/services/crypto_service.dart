import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/crypto_key.dart';

class CryptoService {
  final Random _random = Random.secure();

  // Generează o pereche de chei pentru algoritmi PQC simulați
  Future<CryptoKey> generateKeyPair(PQCAlgorithm algorithm, String keyName) async {
    final keyId = _generateKeyId();
    
    // Simulez generarea cheilor PQC
    // În implementarea reală, ar trebui să folosești biblioteci specializate pentru PQC
    final keyPair = await _generatePQCKeyPair(algorithm);
    
    return CryptoKey(
      id: keyId,
      name: keyName,
      algorithm: algorithm.technicalName,
      publicKey: keyPair.publicKey,
      privateKey: keyPair.privateKey,
      createdAt: DateTime.now(),
    );
  }

  Future<_PQCKeyPair> _generatePQCKeyPair(PQCAlgorithm algorithm) async {
    // Simulez generarea cheilor PQC cu chei RSA pentru demonstrație
    // În implementarea reală, ar trebui să folosești biblioteci specializate
    final rsaKeyGen = RSAKeyGenerator();
    final keyGenParams = RSAKeyGeneratorParameters(
      BigInt.parse('65537'), // exponent public standard
      2048, // mărimea cheii în biți
      64, // numărul de teste de primalitate
    );
    
    final params = ParametersWithRandom(keyGenParams, SecureRandom('Fortuna'));
    rsaKeyGen.init(params);
    
    final keyPair = rsaKeyGen.generateKeyPair();
    final publicKey = keyPair.publicKey as RSAPublicKey;
    final privateKey = keyPair.privateKey as RSAPrivateKey;
    
    return _PQCKeyPair(
      publicKey: _encodePublicKey(publicKey, algorithm),
      privateKey: _encodePrivateKey(privateKey, algorithm),
    );
  }

  String _encodePublicKey(RSAPublicKey key, PQCAlgorithm algorithm) {
    final keyData = {
      'algorithm': algorithm.technicalName,
      'modulus': key.modulus.toString(),
      'exponent': key.exponent.toString(),
      'type': 'public',
    };
    return base64Encode(utf8.encode(json.encode(keyData)));
  }

  String _encodePrivateKey(RSAPrivateKey key, PQCAlgorithm algorithm) {
    final keyData = {
      'algorithm': algorithm.technicalName,
      'modulus': key.modulus.toString(),
      'exponent': key.exponent.toString(),
      'p': key.p.toString(),
      'q': key.q.toString(),
      'type': 'private',
    };
    return base64Encode(utf8.encode(json.encode(keyData)));
  }

  // Criptează datele folosind cheia publică
  Future<Uint8List> encryptData(Uint8List data, String publicKeyStr) async {
    try {
      // Decodifică cheia publică
      final keyData = json.decode(utf8.decode(base64Decode(publicKeyStr)));
      final publicKey = RSAPublicKey(
        BigInt.parse(keyData['modulus']),
        BigInt.parse(keyData['exponent']),
      );

      // Folosește AES pentru criptarea datelor și RSA pentru cheia AES
      final aesKey = _generateAESKey();
      final encryptedData = _encryptWithAES(data, aesKey);
      final encryptedAESKey = _encryptAESKeyWithRSA(aesKey, publicKey);

      // Combină cheia AES criptată cu datele criptate
      final result = BytesBuilder();
      result.add(_intToBytes(encryptedAESKey.length, 4));
      result.add(encryptedAESKey);
      result.add(encryptedData);

      return result.toBytes();
    } catch (e) {
      throw Exception('Eroare la criptarea datelor: $e');
    }
  }

  // Decriptează datele folosind cheia privată
  Future<Uint8List> decryptData(Uint8List encryptedData, String privateKeyStr) async {
    try {
      // Decodifică cheia privată
      final keyData = json.decode(utf8.decode(base64Decode(privateKeyStr)));
      final privateKey = RSAPrivateKey(
        BigInt.parse(keyData['modulus']),
        BigInt.parse(keyData['exponent']),
        BigInt.parse(keyData['p']),
        BigInt.parse(keyData['q']),
      );

      // Extrage cheia AES criptată și datele criptate
      final aesKeyLength = _bytesToInt(encryptedData.sublist(0, 4));
      final encryptedAESKey = encryptedData.sublist(4, 4 + aesKeyLength);
      final encryptedDataPart = encryptedData.sublist(4 + aesKeyLength);

      // Decriptează cheia AES cu RSA
      final aesKey = _decryptAESKeyWithRSA(encryptedAESKey, privateKey);
      
      // Decriptează datele cu AES
      return _decryptWithAES(encryptedDataPart, aesKey);
    } catch (e) {
      throw Exception('Eroare la decriptarea datelor: $e');
    }
  }

  Uint8List _generateAESKey() {
    final key = Uint8List(32); // 256-bit key
    for (int i = 0; i < key.length; i++) {
      key[i] = _random.nextInt(256);
    }
    return key;
  }

  Uint8List _encryptWithAES(Uint8List data, Uint8List key) {
    final cipher = PaddedBlockCipher('AES/CBC/PKCS7');
    final iv = Uint8List(16);
    for (int i = 0; i < iv.length; i++) {
      iv[i] = _random.nextInt(256);
    }
    
    final params = PaddedBlockCipherParameters(
      ParametersWithIV(KeyParameter(key), iv),
      null,
    );
    
    cipher.init(true, params);
    final encryptedData = cipher.process(data);
    
    // Combină IV cu datele criptate
    final result = BytesBuilder();
    result.add(iv);
    result.add(encryptedData);
    return result.toBytes();
  }

  Uint8List _decryptWithAES(Uint8List encryptedData, Uint8List key) {
    final iv = encryptedData.sublist(0, 16);
    final ciphertext = encryptedData.sublist(16);
    
    final cipher = PaddedBlockCipher('AES/CBC/PKCS7');
    final params = PaddedBlockCipherParameters(
      ParametersWithIV(KeyParameter(key), iv),
      null,
    );
    
    cipher.init(false, params);
    return cipher.process(ciphertext);
  }

  Uint8List _encryptAESKeyWithRSA(Uint8List aesKey, RSAPublicKey publicKey) {
    final cipher = RSAEngine();
    cipher.init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
    return cipher.process(aesKey);
  }

  Uint8List _decryptAESKeyWithRSA(Uint8List encryptedAESKey, RSAPrivateKey privateKey) {
    final cipher = RSAEngine();
    cipher.init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    return cipher.process(encryptedAESKey);
  }

  Uint8List _intToBytes(int value, int length) {
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = (value >> (8 * i)) & 0xFF;
    }
    return bytes;
  }

  int _bytesToInt(Uint8List bytes) {
    int result = 0;
    for (int i = 0; i < bytes.length; i++) {
      result |= (bytes[i] << (8 * i));
    }
    return result;
  }

  String _generateKeyId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(16, (index) => chars[_random.nextInt(chars.length)]).join();
  }

  // Calculează hash-ul unui fișier pentru verificarea integrității
  Future<String> calculateFileHash(Uint8List data) async {
    final digest = sha256.convert(data);
    return digest.toString();
  }

  // Verifică integritatea unui fișier
  Future<bool> verifyFileIntegrity(Uint8List data, String expectedHash) async {
    final actualHash = await calculateFileHash(data);
    return actualHash == expectedHash;
  }

  // Estimează puterea algoritmului PQC
  int getAlgorithmStrength(PQCAlgorithm algorithm) {
    switch (algorithm) {
      case PQCAlgorithm.kyber512:
        return 128; // echivalent AES-128
      case PQCAlgorithm.kyber768:
        return 192; // echivalent AES-192
      case PQCAlgorithm.kyber1024:
        return 256; // echivalent AES-256
      case PQCAlgorithm.dilithium2:
        return 128;
      case PQCAlgorithm.dilithium3:
        return 192;
      case PQCAlgorithm.dilithium5:
        return 256;
      case PQCAlgorithm.falcon512:
        return 128;
      case PQCAlgorithm.falcon1024:
        return 256;
    }
  }

  // Returnează descrierea algoritmului
  String getAlgorithmDescription(PQCAlgorithm algorithm) {
    switch (algorithm) {
      case PQCAlgorithm.kyber512:
      case PQCAlgorithm.kyber768:
      case PQCAlgorithm.kyber1024:
        return 'Algoritm de încapsulare a cheilor (KEM) bazat pe problema Learning With Errors';
      case PQCAlgorithm.dilithium2:
      case PQCAlgorithm.dilithium3:
      case PQCAlgorithm.dilithium5:
        return 'Algoritm de semnătură digitală bazat pe rețele (lattice-based)';
      case PQCAlgorithm.falcon512:
      case PQCAlgorithm.falcon1024:
        return 'Algoritm de semnătură digitală compact bazat pe rețele';
    }
  }
}

class _PQCKeyPair {
  final String publicKey;
  final String privateKey;

  _PQCKeyPair({required this.publicKey, required this.privateKey});
}
