import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/encrypted_archive.dart';
import '../models/crypto_key.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    // Initialize sqflite for desktop platforms
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    // Get the path for the database
    String path;
    if (Platform.isAndroid || Platform.isIOS) {
      path = join(await getDatabasesPath(), 'pcq_vault.db');
    } else {
      // For desktop platforms, use application documents directory
      final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
      path = join(appDocumentsDir.path, 'pcq_vault.db');
    }
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        // Tabelul pentru arhivele criptate
        await db.execute('''
          CREATE TABLE encrypted_archives (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            filePath TEXT NOT NULL,
            size INTEGER NOT NULL,
            createdAt INTEGER NOT NULL,
            modifiedAt INTEGER NOT NULL,
            algorithm TEXT NOT NULL,
            keyId TEXT NOT NULL,
            isLocked INTEGER DEFAULT 0
          )
        ''');

        // Tabelul pentru cheile criptografice
        await db.execute('''
          CREATE TABLE crypto_keys (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            algorithm TEXT NOT NULL,
            publicKey TEXT NOT NULL,
            privateKey TEXT NOT NULL,
            createdAt INTEGER NOT NULL,
            isDefault INTEGER DEFAULT 0
          )
        ''');

        // Indexuri pentru performanță
        await db.execute('CREATE INDEX idx_archives_name ON encrypted_archives(name)');
        await db.execute('CREATE INDEX idx_archives_created ON encrypted_archives(createdAt)');
        await db.execute('CREATE INDEX idx_keys_algorithm ON crypto_keys(algorithm)');
      },
    );
  }

  // Operații pentru arhive
  Future<int> insertArchive(EncryptedArchive archive) async {
    final db = await database;
    return await db.insert('encrypted_archives', archive.toMap());
  }

  Future<List<EncryptedArchive>> getAllArchives() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'encrypted_archives',
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return EncryptedArchive.fromMap(maps[i]);
    });
  }

  Future<EncryptedArchive?> getArchiveById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'encrypted_archives',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return EncryptedArchive.fromMap(maps.first);
    }
    return null;
  }

  Future<List<EncryptedArchive>> searchArchives(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'encrypted_archives',
      where: 'name LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return EncryptedArchive.fromMap(maps[i]);
    });
  }

  Future<int> updateArchive(EncryptedArchive archive) async {
    final db = await database;
    return await db.update(
      'encrypted_archives',
      archive.toMap(),
      where: 'id = ?',
      whereArgs: [archive.id],
    );
  }

  Future<int> deleteArchive(int id) async {
    final db = await database;
    return await db.delete(
      'encrypted_archives',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Operații pentru chei criptografice
  Future<void> insertCryptoKey(CryptoKey key) async {
    final db = await database;
    await db.insert('crypto_keys', key.toMap());
  }

  Future<List<CryptoKey>> getAllCryptoKeys() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'crypto_keys',
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return CryptoKey.fromMap(maps[i]);
    });
  }

  Future<CryptoKey?> getCryptoKeyById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'crypto_keys',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return CryptoKey.fromMap(maps.first);
    }
    return null;
  }

  Future<CryptoKey?> getDefaultCryptoKey() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'crypto_keys',
      where: 'isDefault = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return CryptoKey.fromMap(maps.first);
    }
    return null;
  }

  Future<List<CryptoKey>> getCryptoKeysByAlgorithm(String algorithm) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'crypto_keys',
      where: 'algorithm = ?',
      whereArgs: [algorithm],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return CryptoKey.fromMap(maps[i]);
    });
  }

  Future<int> deleteCryptoKey(String id) async {
    final db = await database;
    return await db.delete(
      'crypto_keys',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setDefaultCryptoKey(String keyId) async {
    final db = await database;
    
    // Resetează toate cheile ca non-default
    await db.update(
      'crypto_keys',
      {'isDefault': 0},
      where: 'isDefault = ?',
      whereArgs: [1],
    );
    
    // Setează noua cheie ca default
    await db.update(
      'crypto_keys',
      {'isDefault': 1},
      where: 'id = ?',
      whereArgs: [keyId],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
