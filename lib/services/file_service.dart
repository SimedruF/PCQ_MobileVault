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

  // Gets directory for storing encrypted files
  Future<Directory> get _vaultDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory('${appDir.path}/pcq_vault');
    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }
    return vaultDir;
  }

  // Requests permissions for file access
  Future<bool> requestStoragePermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true; // iOS doesn't require explicit permissions for document picker
  }

  // Selects files for adding to archive
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
      throw Exception('Error selecting files: $e');
    }
  }

  // Selects a directory for adding to archive
  Future<Directory?> pickDirectory() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        return Directory(result);
      }
      return null;
    } catch (e) {
      throw Exception('Error selecting directory: $e');
    }
  }

  // Creates an encrypted archive from selected files
  Future<EncryptedArchive> createEncryptedArchive({
    required List<File> files,
    required String archiveName,
    required String description,
    required CryptoKey cryptoKey,
  }) async {
    try {
      // Create ZIP archive
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

      // Compress archive
      final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive)!);

      // Encrypt archive
      final encryptedBytes = await _cryptoService.encryptData(
        zipBytes,
        cryptoKey.publicKey,
      );

      // Save encrypted file
      final vaultDir = await _vaultDirectory;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$archiveName.pcqv';
      final encryptedFile = File('${vaultDir.path}/$fileName');
      await encryptedFile.writeAsBytes(encryptedBytes);

      // Create database record
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
      throw Exception('Error creating encrypted archive: $e');
    }
  }

  // Adds an entire directory to an encrypted archive
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

      // Compress and encrypt
      final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive)!);
      final encryptedBytes = await _cryptoService.encryptData(
        zipBytes,
        cryptoKey.publicKey,
      );

      // Save
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
      throw Exception('Error creating archive from directory: $e');
    }
  }

  // Extracts encrypted archive
  Future<Directory> extractEncryptedArchive({
    required EncryptedArchive archive,
    required CryptoKey cryptoKey,
    Directory? extractToDirectory,
  }) async {
    try {
      // Read encrypted file
      final encryptedFile = File(archive.filePath);
      if (!await encryptedFile.exists()) {
        throw Exception('Archive file does not exist');
      }

      final encryptedBytes = await encryptedFile.readAsBytes();

      // Decrypt
      final decryptedBytes = await _cryptoService.decryptData(
        encryptedBytes,
        cryptoKey.privateKey,
      );

      // Decompress archive
      final archiveData = ZipDecoder().decodeBytes(decryptedBytes);

      // Determine extraction directory
      final extractDir = extractToDirectory ?? 
          await _getDefaultExtractionDirectory(archive.name);

      if (!await extractDir.exists()) {
        await extractDir.create(recursive: true);
      }

      // Extract files
      for (final file in archiveData) {
        if (file.isFile) {
          final extractedFile = File('${extractDir.path}/${file.name}');
          
          // Create parent directories if necessary
          final parentDir = extractedFile.parent;
          if (!await parentDir.exists()) {
            await parentDir.create(recursive: true);
          }

          await extractedFile.writeAsBytes(file.content as List<int>);
        }
      }

      return extractDir;
    } catch (e) {
      throw Exception('Error extracting archive: $e');
    }
  }

  // Lists the contents of an archive without extracting it
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
      throw Exception('Error listing archive contents: $e');
    }
  }

  // Deletes an encrypted archive
  Future<void> deleteEncryptedArchive(EncryptedArchive archive) async {
    try {
      // Delete the file from disk
      final file = File(archive.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Delete the record from database
      if (archive.id != null) {
        await _databaseService.deleteArchive(archive.id!);
      }
    } catch (e) {
      throw Exception('Error deleting archive: $e');
    }
  }

  // Gets all files from a directory recursively
  Future<List<File>> _getAllFilesFromDirectory(Directory directory) async {
    final files = <File>[];
    
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        files.add(entity);
      }
    }
    
    return files;
  }

  // Gets the default directory for extraction
  Future<Directory> _getDefaultExtractionDirectory(String archiveName) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final extractionDir = Directory('${documentsDir.path}/extractions/$archiveName');
    return extractionDir;
  }

  // Calculates the size of an encrypted archive
  Future<int> getArchiveFileSize(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  // Checks if an archive is valid
  Future<bool> validateArchive(EncryptedArchive archive) async {
    try {
      final file = File(archive.filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // Exports an archive to an external location
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
      throw Exception('Error exporting archive: $e');
    }
  }

  // Imports an archive from an external location
  Future<EncryptedArchive?> importArchive() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pcqv'],
      );

      if (result != null && result.files.single.path != null) {
        final sourceFile = File(result.files.single.path!);
        
        // Copy the file to the vault directory
        final vaultDir = await _vaultDirectory;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_imported.pcqv';
        final targetFile = File('${vaultDir.path}/$fileName');
        await sourceFile.copy(targetFile.path);

        // Creează înregistrarea în baza de date
        // Note: you will need to manually select the key for decryption
        final archive = EncryptedArchive(
          name: result.files.single.name.replaceAll('.pcqv', ''),
          description: 'Imported archive',
          filePath: targetFile.path,
          size: await targetFile.length(),
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
          algorithm: 'Unknown', // will be updated when you select the key
          keyId: '', // will be updated when you select the key
        );

        final id = await _databaseService.insertArchive(archive);
        return archive.copyWith(id: id);
      }
      return null;
    } catch (e) {
      throw Exception('Error importing archive: $e');
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
