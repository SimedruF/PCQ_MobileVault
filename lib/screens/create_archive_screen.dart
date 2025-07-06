import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../services/crypto_service.dart';
import '../services/database_service.dart';
import '../services/file_service.dart';
import '../models/crypto_key.dart';

class CreateArchiveScreen extends StatefulWidget {
  const CreateArchiveScreen({super.key});

  @override
  State<CreateArchiveScreen> createState() => _CreateArchiveScreenState();
}

class _CreateArchiveScreenState extends State<CreateArchiveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  List<File> _selectedFiles = [];
  Directory? _selectedDirectory;
  CryptoKey? _selectedKey;
  List<CryptoKey> _availableKeys = [];
  bool _isLoading = false;
  bool _isCreating = false;
  int _currentStep = 0;
  
  FileService? _fileService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initializeServices() {
    final cryptoService = Provider.of<CryptoService>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    _fileService = FileService(cryptoService, databaseService);
    _loadAvailableKeys();
  }

  Future<void> _loadAvailableKeys() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final keys = await databaseService.getAllCryptoKeys();
      
      setState(() {
        _availableKeys = keys;
        _selectedKey = keys.isNotEmpty ? keys.first : null;
        _isLoading = false;
      });
      
      if (keys.isEmpty) {
        _showCreateKeyDialog();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Eroare la încărcarea cheilor: $e');
    }
  }

  Future<void> _showCreateKeyDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Nu există chei disponibile'),
        content: const Text(
          'Pentru a crea o arhivă criptată, ai nevoie de cel puțin o cheie criptografică. '
          'Vrei să creezi o cheie acum?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Nu acum'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Creează cheie'),
          ),
        ],
      ),
    );

    if (result == true) {
      _navigateToKeyCreation();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _navigateToKeyCreation() {
    // TODO: Navighează la ecranul de creare chei
    Navigator.of(context).pop();
  }

  Future<void> _pickFiles() async {
    try {
      if (_fileService == null) return;
      
      final hasPermission = await _fileService!.requestStoragePermissions();
      if (!hasPermission) {
        _showErrorSnackBar('Permisiunile de acces la fișiere sunt necesare');
        return;
      }

      final files = await _fileService!.pickFiles();
      if (files != null && files.isNotEmpty) {
        setState(() {
          _selectedFiles = files;
          _selectedDirectory = null; // Reset directory selection
        });
      }
    } catch (e) {
      _showErrorSnackBar('Eroare la selectarea fișierelor: $e');
    }
  }

  Future<void> _pickDirectory() async {
    try {
      if (_fileService == null) return;
      
      final hasPermission = await _fileService!.requestStoragePermissions();
      if (!hasPermission) {
        _showErrorSnackBar('Permisiunile de acces la fișiere sunt necesare');
        return;
      }

      final directory = await _fileService!.pickDirectory();
      if (directory != null) {
        setState(() {
          _selectedDirectory = directory;
          _selectedFiles = []; // Reset file selection
        });
      }
    } catch (e) {
      _showErrorSnackBar('Eroare la selectarea directorului: $e');
    }
  }

  Future<void> _createArchive() async {
    if (!_formKey.currentState!.validate() || 
        (_selectedFiles.isEmpty && _selectedDirectory == null) ||
        _selectedKey == null ||
        _fileService == null) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      if (_selectedDirectory != null) {
        // Creează arhiva din director
        await _fileService!.createEncryptedArchiveFromDirectory(
          directory: _selectedDirectory!,
          archiveName: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          cryptoKey: _selectedKey!,
        );
      } else {
        // Creează arhiva din fișiere
        await _fileService!.createEncryptedArchive(
          files: _selectedFiles,
          archiveName: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          cryptoKey: _selectedKey!,
        );
      }

      _showSuccessSnackBar('Arhiva a fost creată cu succes');
      Navigator.of(context).pop();
    } catch (e) {
      _showErrorSnackBar('Eroare la crearea arhivei: $e');
    }

    setState(() {
      _isCreating = false;
    });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creează arhivă nouă'),
        actions: [
          if (_currentStep == 2)
            TextButton(
              onPressed: _isCreating ? null : _createArchive,
              child: _isCreating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Creează'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              currentStep: _currentStep,
              onStepTapped: (step) {
                if (step < _currentStep || _canProceedToStep(step)) {
                  setState(() {
                    _currentStep = step;
                  });
                }
              },
              controlsBuilder: (context, details) {
                return Row(
                  children: [
                    if (details.onStepContinue != null)
                      ElevatedButton(
                        onPressed: details.onStepContinue,
                        child: Text(details.stepIndex == 2 ? 'Finalizează' : 'Următorul'),
                      ),
                    const SizedBox(width: 8),
                    if (details.onStepCancel != null)
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Înapoi'),
                      ),
                  ],
                );
              },
              onStepContinue: () {
                if (_canProceedToStep(_currentStep + 1)) {
                  if (_currentStep == 2) {
                    _createArchive();
                  } else {
                    setState(() {
                      _currentStep++;
                    });
                  }
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() {
                    _currentStep--;
                  });
                }
              },
              steps: [
                // Pasul 1: Selectare fișiere/director
                Step(
                  title: const Text('Selectează conținutul'),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alege fișierele sau directorul pe care vrei să îl criptezi:',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _pickFiles,
                              icon: const Icon(Icons.insert_drive_file),
                              label: const Text('Selectează fișiere'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _pickDirectory,
                              icon: const Icon(Icons.folder),
                              label: const Text('Selectează director'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_selectedFiles.isNotEmpty) ...[
                        const Text(
                          'Fișiere selectate:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...(_selectedFiles.map((file) => ListTile(
                          leading: const Icon(Icons.insert_drive_file),
                          title: Text(file.path.split('/').last),
                          subtitle: Text(file.path),
                          dense: true,
                        ))),
                      ],
                      if (_selectedDirectory != null) ...[
                        const Text(
                          'Director selectat:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          leading: const Icon(Icons.folder),
                          title: Text(_selectedDirectory!.path.split('/').last),
                          subtitle: Text(_selectedDirectory!.path),
                          dense: true,
                        ),
                      ],
                    ],
                  ),
                  isActive: _currentStep >= 0,
                ),
                
                // Pasul 2: Detalii arhivă
                Step(
                  title: const Text('Detalii arhivă'),
                  content: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Numele arhivei',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Numele arhivei este obligatoriu';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Descriere (opțională)',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  isActive: _currentStep >= 1,
                ),
                
                // Pasul 3: Selectare cheie
                Step(
                  title: const Text('Cheia de criptare'),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selectează cheia de criptare:',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      if (_availableKeys.isNotEmpty) ...[
                        DropdownButtonFormField<CryptoKey>(
                          value: _selectedKey,
                          decoration: const InputDecoration(
                            labelText: 'Cheia de criptare',
                            border: OutlineInputBorder(),
                          ),
                          items: _availableKeys.map((key) {
                            return DropdownMenuItem(
                              value: key,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(key.name),
                                  Text(
                                    key.algorithm,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (key) {
                            setState(() {
                              _selectedKey = key;
                            });
                          },
                        ),
                      ] else ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(Icons.key_off, size: 48),
                                const SizedBox(height: 8),
                                const Text('Nu există chei disponibile'),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _navigateToKeyCreation,
                                  child: const Text('Creează o cheie'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  isActive: _currentStep >= 2,
                ),
              ],
            ),
    );
  }

  bool _canProceedToStep(int step) {
    switch (step) {
      case 0:
        return true;
      case 1:
        return _selectedFiles.isNotEmpty || _selectedDirectory != null;
      case 2:
        return (_selectedFiles.isNotEmpty || _selectedDirectory != null) &&
               _nameController.text.trim().isNotEmpty;
      case 3:
        return (_selectedFiles.isNotEmpty || _selectedDirectory != null) &&
               _nameController.text.trim().isNotEmpty &&
               _selectedKey != null;
      default:
        return false;
    }
  }
}
