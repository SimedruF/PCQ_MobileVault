import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/encrypted_archive.dart';
import '../models/crypto_key.dart';
import '../services/crypto_service.dart';
import '../services/database_service.dart';
import '../services/file_service.dart';

class ArchiveDetailScreen extends StatefulWidget {
  final EncryptedArchive archive;

  const ArchiveDetailScreen({
    super.key,
    required this.archive,
  });

  @override
  State<ArchiveDetailScreen> createState() => _ArchiveDetailScreenState();
}

class _ArchiveDetailScreenState extends State<ArchiveDetailScreen> {
  CryptoKey? _cryptoKey;
  bool _isLoading = true;
  bool _isExtracting = false;
  List<ArchiveFileInfo>? _archiveContents;
  FileService? _fileService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  void _initializeServices() {
    final cryptoService = Provider.of<CryptoService>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    _fileService = FileService(cryptoService, databaseService);
    _loadCryptoKey();
  }

  Future<void> _loadCryptoKey() async {
    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final key = await databaseService.getCryptoKeyById(widget.archive.keyId);
      
      setState(() {
        _cryptoKey = key;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Eroare la încărcarea cheii: $e');
    }
  }

  Future<void> _loadArchiveContents() async {
    if (_cryptoKey == null || _fileService == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final contents = await _fileService!.listArchiveContents(
        archive: widget.archive,
        cryptoKey: _cryptoKey!,
      );
      
      setState(() {
        _archiveContents = contents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Eroare la încărcarea conținutului arhivei: $e');
    }
  }

  Future<void> _extractArchive() async {
    if (_cryptoKey == null || _fileService == null) return;

    setState(() {
      _isExtracting = true;
    });

    try {
      final extractedDir = await _fileService!.extractEncryptedArchive(
        archive: widget.archive,
        cryptoKey: _cryptoKey!,
      );
      
      _showSuccessSnackBar('Arhiva a fost extrasă în: ${extractedDir.path}');
    } catch (e) {
      _showErrorSnackBar('Eroare la extragerea arhivei: $e');
    }

    setState(() {
      _isExtracting = false;
    });
  }

  Future<void> _exportArchive() async {
    if (_fileService == null) return;

    try {
      final exportPath = await _fileService!.exportArchive(widget.archive);
      if (exportPath != null) {
        _showSuccessSnackBar('Arhiva a fost exportată în: $exportPath');
      }
    } catch (e) {
      _showErrorSnackBar('Eroare la exportarea arhivei: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.archive.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _exportArchive();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download),
                    SizedBox(width: 8),
                    Text('Exportă'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informații generale
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.archive,
                                size: 32,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.archive.name,
                                      style: Theme.of(context).textTheme.headlineSmall,
                                    ),
                                    if (widget.archive.description.isNotEmpty)
                                      Text(
                                        widget.archive.description,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          _buildInfoRow('Mărime', widget.archive.sizeFormatted),
                          _buildInfoRow('Creat la', dateFormat.format(widget.archive.createdAt)),
                          _buildInfoRow('Modificat la', dateFormat.format(widget.archive.modifiedAt)),
                          _buildInfoRow('Algoritm', widget.archive.algorithm),
                          if (_cryptoKey != null)
                            _buildInfoRow('Cheia', _cryptoKey!.name),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Acțiuni
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Acțiuni',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _cryptoKey == null || _isExtracting 
                                      ? null 
                                      : _extractArchive,
                                  icon: _isExtracting
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.folder_open),
                                  label: const Text('Extrage'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _archiveContents == null
                                      ? _loadArchiveContents
                                      : null,
                                  icon: const Icon(Icons.list),
                                  label: const Text('Vezi conținutul'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Conținutul arhivei
                  if (_archiveContents != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Conținutul arhivei (${_archiveContents!.length} fișiere)',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _archiveContents!.length,
                              separatorBuilder: (context, index) => const Divider(),
                              itemBuilder: (context, index) {
                                final fileInfo = _archiveContents![index];
                                return ListTile(
                                  leading: const Icon(Icons.insert_drive_file),
                                  title: Text(fileInfo.name),
                                  subtitle: Text(
                                    '${fileInfo.sizeFormatted} • '
                                    'Compresie: ${fileInfo.compressionRatio.toStringAsFixed(1)}%',
                                  ),
                                  trailing: Text(
                                    DateFormat('dd.MM.yyyy').format(fileInfo.lastModified),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  dense: true,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  // Informații despre securitate
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.security,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Informații despre securitate',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_cryptoKey != null) ...[
                            _buildSecurityInfo('Algoritm PQC', widget.archive.algorithm),
                            _buildSecurityInfo('Puterea algoritmului', 
                                '${Provider.of<CryptoService>(context, listen: false).getAlgorithmStrength(PQCAlgorithm.fromString(widget.archive.algorithm))} biți'),
                            _buildSecurityInfo('ID cheie', widget.archive.keyId),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.verified, color: Colors.green.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Arhiva este protejată cu criptografie post-cuantică',
                                      style: TextStyle(color: Colors.green.shade700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.orange.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Cheia de criptare nu a fost găsită',
                                      style: TextStyle(color: Colors.orange.shade700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
