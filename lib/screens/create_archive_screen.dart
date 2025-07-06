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
      _showErrorSnackBar('Error loading keys: $e');
    }
  }

  Future<void> _showCreateKeyDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Nu există chei disponibile'),
        content: const Text(
          'To create an encrypted archive, you need at least one cryptographic key. '
          'Do you want to create a key now?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Nu acum'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Create key'),
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
    // TODO: Navigate to key creation screen
    Navigator.of(context).pop();
  }

  Future<void> _pickFiles() async {
    try {
      if (_fileService == null) return;
      
      final hasPermission = await _fileService!.requestStoragePermissions();
      if (!hasPermission) {
        _showErrorSnackBar('File access permissions are required');
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
      _showErrorSnackBar('Error selecting files: $e');
    }
  }

  Future<void> _pickDirectory() async {
    try {
      if (_fileService == null) return;
      
      final hasPermission = await _fileService!.requestStoragePermissions();
      if (!hasPermission) {
        _showErrorSnackBar('File access permissions are required');
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
      _showErrorSnackBar('Error selecting directory: $e');
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
        // Create archive from directory
        await _fileService!.createEncryptedArchiveFromDirectory(
          directory: _selectedDirectory!,
          archiveName: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          cryptoKey: _selectedKey!,
        );
      } else {
        // Create archive from files
        await _fileService!.createEncryptedArchive(
          files: _selectedFiles,
          archiveName: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          cryptoKey: _selectedKey!,
        );
      }

      _showSuccessSnackBar('Archive was created successfully');
      Navigator.of(context).pop();
    } catch (e) {
      _showErrorSnackBar('Error creating archive: $e');
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
        title: const Text('Create new archive'),
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
                // Step 1: Select files/directory
                Step(
                  title: const Text('Select content'),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choose the files or directory you want to encrypt:',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _pickFiles,
                              icon: const Icon(Icons.insert_drive_file),
                              label: const Text('Select files'),
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
                          'Selected files:',
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
                
                // Step 2: Archive details
                Step(
                  title: const Text('Archive details'),
                  content: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Archive name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Archive name is required';
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
                
                // Step 3: Key selection
                Step(
                  title: const Text('Encryption key'),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select encryption key:',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      if (_availableKeys.isNotEmpty) ...[
                        DropdownButtonFormField<CryptoKey>(
                          value: _selectedKey,
                          decoration: const InputDecoration(
                            labelText: 'Encryption key',
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
                                  child: const Text('Create a key'),
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
