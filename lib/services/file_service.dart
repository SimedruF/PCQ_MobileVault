import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/encrypted_archive.dart';
import '../models/crypto_key.dart';
import 'crypto_service.dart';
import 'database_service.dart';

class FileService {
  final CryptoService _cryptoService;
  final DatabaseService _databaseService;

  FileService(this._cryptoService, this._databaseService);

  // Obține directorul pentru stocarea fișierelor criptate
  Future<Directory> get _vaultDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory('${appDir.path}/pcq_vault');
    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }
    return vaultDir;
  }

  // Solicită permisiuni pentru accesarea fișierelor
  Future<bool> requestStoragePermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true; // iOS nu necesită permisiuni explicite pentru document picker
  }

  // Selectează fișiere pentru adăugarea în arhivă
  Future<List<File>?> pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        return result.paths
            .where((path) => path != null)
            .map((path) => File(path!))
            .toList();
      }
      return null;
    } catch (e) {
      throw Exception('Eroare la selectarea fișierelor: $e');
    }
  }

  // Selectează un director pentru adăugarea în arhivă
  Future<Directory?> pickDirectory() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        return Directory(result);
      }
      return null;
    } catch (e) {
      throw Exception('Eroare la selectarea directorului: $e');
    }
  }

  // Creează o arhivă criptată din fișiere selectate
  Future<EncryptedArchive> createEncryptedArchive({
    required List<File> files,
    required String archiveName,
    required String description,
    required CryptoKey cryptoKey,
  }) async {
    try {
      // Creează arhiva ZIP
      final archive = Archive();
      int totalSize = 0;

      for (final file in files) {
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final fileName = file.path.split(Platform.pathSeparator).last;
          archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
          totalSize += bytes.length;
        }
      }

      // Comprimă arhiva
      final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive)!);

      // Criptează arhiva
      final encryptedBytes = await _cryptoService.encryptData(
        zipBytes,
        cryptoKey.publicKey,
      );

      // Salvează fișierul criptat
      final vaultDir = await _vaultDirectory;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$archiveName.pcqv';
      final encryptedFile = File('${vaultDir.path}/$fileName');
      await encryptedFile.writeAsBytes(encryptedBytes);

      // Creează înregistrarea în baza de date
      final encryptedArchive = EncryptedArchive(
        name: archiveName,
        description: description,
        filePath: encryptedFile.path,
        size: totalSize,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        algorithm: cryptoKey.algorithm,
        keyId: cryptoKey.id,
      );

      final id = await _databaseService.insertArchive(encryptedArchive);
      return encryptedArchive.copyWith(id: id);
    } catch (e) {
      throw Exception('Eroare la crearea arhivei criptate: $e');
    }
  }

  // Adaugă un director întreg într-o arhivă criptată
  Future<EncryptedArchive> createEncryptedArchiveFromDirectory({
    required Directory directory,
    required String archiveName,
    required String description,
    required CryptoKey cryptoKey,
  }) async {
    try {
      final files = await _getAllFilesFromDirectory(directory);
      
      final archive = Archive();
      int totalSize = 0;

      for (final file in files) {
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final relativePath = file.path.substring(directory.path.length + 1);
          archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
          totalSize += bytes.length;
        }
      }

      // Comprimă și criptează
      final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive)!);
      final encryptedBytes = await _cryptoService.encryptData(
        zipBytes,
        cryptoKey.publicKey,
      );

      // Salvează
      final vaultDir = await _vaultDirectory;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$archiveName.pcqv';
      final encryptedFile = File('${vaultDir.path}/$fileName');
      await encryptedFile.writeAsBytes(encryptedBytes);

      final encryptedArchive = EncryptedArchive(
        name: archiveName,
        description: description,
        filePath: encryptedFile.path,
        size: totalSize,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        algorithm: cryptoKey.algorithm,
        keyId: cryptoKey.id,
      );

      final id = await _databaseService.insertArchive(encryptedArchive);
      return encryptedArchive.copyWith(id: id);
    } catch (e) {
      throw Exception('Eroare la crearea arhivei din director: $e');
    }
  }

  // Extrage arhiva criptată
  Future<Directory> extractEncryptedArchive({
    required EncryptedArchive archive,
    required CryptoKey cryptoKey,
    Directory? extractToDirectory,
  }) async {
    try {
      // Citește fișierul criptat
      final encryptedFile = File(archive.filePath);
      if (!await encryptedFile.exists()) {
        throw Exception('Fișierul arhivei nu există');
      }

      final encryptedBytes = await encryptedFile.readAsBytes();

      // Decriptează
      final decryptedBytes = await _cryptoService.decryptData(
        encryptedBytes,
        cryptoKey.privateKey,
      );

      // Decomprimă arhiva
      final archiveData = ZipDecoder().decodeBytes(decryptedBytes);

      // Determină directorul de extragere
      final extractDir = extractToDirectory ?? 
          await _getDefaultExtractionDirectory(archive.name);

      if (!await extractDir.exists()) {
        await extractDir.create(recursive: true);
      }

      // Extrage fișierele
      for (final file in archiveData) {
        if (file.isFile) {
          final extractedFile = File('${extractDir.path}/${file.name}');
          
          // Creează directoarele părinte dacă este necesar
          final parentDir = extractedFile.parent;
          if (!await parentDir.exists()) {
            await parentDir.create(recursive: true);
          }

          await extractedFile.writeAsBytes(file.content as List<int>);
        }
      }

      return extractDir;
    } catch (e) {
      throw Exception('Eroare la extragerea arhivei: $e');
    }
  }

  // Listează conținutul unei arhive fără a o extrage
  Future<List<ArchiveFileInfo>> listArchiveContents({
    required EncryptedArchive archive,
    required CryptoKey cryptoKey,
  }) async {
    try {
      final encryptedFile = File(archive.filePath);
      final encryptedBytes = await encryptedFile.readAsBytes();
      
      final decryptedBytes = await _cryptoService.decryptData(
        encryptedBytes,
        cryptoKey.privateKey,
      );

      final archiveData = ZipDecoder().decodeBytes(decryptedBytes);
      
      return archiveData.files
          .where((file) => file.isFile)
          .map((file) => ArchiveFileInfo(
                name: file.name,
                size: file.size,
                compressedSize: file.compressedLength,
                lastModified: DateTime.fromMillisecondsSinceEpoch(
                  file.lastModTime * 1000,
                ),
              ))
          .toList();
    } catch (e) {
      throw Exception('Eroare la listarea conținutului arhivei: $e');
    }
  }

  // Șterge o arhivă criptată
  Future<void> deleteEncryptedArchive(EncryptedArchive archive) async {
    try {
      // Șterge fișierul de pe disk
      final file = File(archive.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Șterge înregistrarea din baza de date
      if (archive.id != null) {
        await _databaseService.deleteArchive(archive.id!);
      }
    } catch (e) {
      throw Exception('Eroare la ștergerea arhivei: $e');
    }
  }

  // Obține toate fișierele dintr-un director recursiv
  Future<List<File>> _getAllFilesFromDirectory(Directory directory) async {
    final files = <File>[];
    
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        files.add(entity);
      }
    }
    
    return files;
  }

  // Obține directorul implicit pentru extragere
  Future<Directory> _getDefaultExtractionDirectory(String archiveName) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final extractionDir = Directory('${documentsDir.path}/extractions/$archiveName');
    return extractionDir;
  }

  // Calculează mărimea unei arhive criptate
  Future<int> getArchiveFileSize(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  // Verifică dacă o arhivă este validă
  Future<bool> validateArchive(EncryptedArchive archive) async {
    try {
      final file = File(archive.filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // Exportă o arhivă într-o locație externă
  Future<String?> exportArchive(EncryptedArchive archive) async {
    try {
      final result = await FilePicker.platform.saveFile(
        fileName: '${archive.name}.pcqv',
        type: FileType.any,
      );

      if (result != null) {
        final sourceFile = File(archive.filePath);
        final targetFile = File(result);
        await sourceFile.copy(targetFile.path);
        return result;
      }
      return null;
    } catch (e) {
      throw Exception('Eroare la exportarea arhivei: $e');
    }
  }

  // Importă o arhivă dintr-o locație externă
  Future<EncryptedArchive?> importArchive() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pcqv'],
      );

      if (result != null && result.files.single.path != null) {
        final sourceFile = File(result.files.single.path!);
        
        // Copiază fișierul în directorul vault
        final vaultDir = await _vaultDirectory;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_imported.pcqv';
        final targetFile = File('${vaultDir.path}/$fileName');
        await sourceFile.copy(targetFile.path);

        // Creează înregistrarea în baza de date
        // Nota: va trebui să selectezi manual cheia pentru decriptare
        final archive = EncryptedArchive(
          name: result.files.single.name.replaceAll('.pcqv', ''),
          description: 'Arhivă importată',
          filePath: targetFile.path,
          size: await targetFile.length(),
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
          algorithm: 'Unknown', // va fi actualizat când selectezi cheia
          keyId: '', // va fi actualizat când selectezi cheia
        );

        final id = await _databaseService.insertArchive(archive);
        return archive.copyWith(id: id);
      }
      return null;
    } catch (e) {
      throw Exception('Eroare la importarea arhivei: $e');
    }
  }
}

extension on ArchiveFile {
  get compressedLength => null;
}

class ArchiveFileInfo {
  final String name;
  final int size;
  final int compressedSize;
  final DateTime lastModified;

  ArchiveFileInfo({
    required this.name,
    required this.size,
    required this.compressedSize,
    required this.lastModified,
  });

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  double get compressionRatio {
    if (size == 0) return 0.0;
    return (1.0 - (compressedSize / size)) * 100;
  }
}
