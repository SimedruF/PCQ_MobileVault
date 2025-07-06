import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/crypto_key.dart';
import '../services/crypto_service.dart';
import '../services/database_service.dart';

class KeysManagementScreen extends StatefulWidget {
  const KeysManagementScreen({super.key});

  @override
  State<KeysManagementScreen> createState() => _KeysManagementScreenState();
}

class _KeysManagementScreenState extends State<KeysManagementScreen> {
  List<CryptoKey> _keys = [];
  bool _isLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final keys = await databaseService.getAllCryptoKeys();
      
      setState(() {
        _keys = keys;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading keys: $e');
    }
  }

  Future<void> _generateNewKey() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _KeyGenerationDialog(),
    );

    if (result != null) {
      setState(() {
        _isGenerating = true;
      });

      try {
        final cryptoService = Provider.of<CryptoService>(context, listen: false);
        final databaseService = Provider.of<DatabaseService>(context, listen: false);
        
        final newKey = await cryptoService.generateKeyPair(
          result['algorithm'] as PQCAlgorithm,
          result['name'] as String,
        );

        await databaseService.insertCryptoKey(newKey);
        
        _showSuccessSnackBar('Key was generated successfully');
        _loadKeys();
      } catch (e) {
        _showErrorSnackBar('Error generating key: $e');
      }

      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _deleteKey(CryptoKey key) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm deletion'),
        content: Text('Are you sure you want to delete the key "${key.name}"?\n\n'
            'WARNING: Archives encrypted with this key will no longer be decryptable!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final databaseService = Provider.of<DatabaseService>(context, listen: false);
        await databaseService.deleteCryptoKey(key.id);
        
        _showSuccessSnackBar('Key was deleted');
        _loadKeys();
      } catch (e) {
        _showErrorSnackBar('Error deleting key: $e');
      }
    }
  }

  Future<void> _setDefaultKey(CryptoKey key) async {
    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      await databaseService.setDefaultCryptoKey(key.id);
      
      _showSuccessSnackBar('Default key was set');
      _loadKeys();
    } catch (e) {
      _showErrorSnackBar('Error setting default key: $e');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionare chei'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _keys.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadKeys,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _keys.length,
                    itemBuilder: (context, index) {
                      final key = _keys[index];
                      return _buildKeyCard(key);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isGenerating ? null : _generateNewKey,
        child: _isGenerating
            ? const CircularProgressIndicator()
            : const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.vpn_key_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Nu ai încă chei criptografice',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Press + to generate your first key',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyCard(CryptoKey key) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final algorithm = PQCAlgorithm.fromString(key.algorithm);
    final cryptoService = Provider.of<CryptoService>(context, listen: false);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.vpn_key,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              key.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (key.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Implicit',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        algorithm.displayName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'set_default':
                        _setDefaultKey(key);
                        break;
                      case 'delete':
                        _deleteKey(key);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (!key.isDefault)
                      const PopupMenuItem(
                        value: 'set_default',
                        child: Row(
                          children: [
                            Icon(Icons.star),
                            SizedBox(width: 8),
                            Text('Setează ca implicit'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                  context,
                  Icons.security,
                  '${cryptoService.getAlgorithmStrength(algorithm)} biți',
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  context,
                  Icons.schedule,
                  dateFormat.format(key.createdAt),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              cryptoService.getAlgorithmDescription(algorithm),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About post-quantum cryptography'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Criptografia post-cuantică (PQC) este o nouă generație de algoritmi criptografici '
                'care sunt rezistenți la atacurile calculatoarelor cuantice.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'Algoritmi disponibili:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Kyber: Algoritm de încapsulare a cheilor'),
              Text('• Dilithium: Algoritm de semnătură digitală'),
              Text('• Falcon: Algoritm de semnătură compact'),
              SizedBox(height: 16),
              Text(
                'Each algorithm offers different levels of security and performance.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Înțeles'),
          ),
        ],
      ),
    );
  }
}

class _KeyGenerationDialog extends StatefulWidget {
  const _KeyGenerationDialog();

  @override
  State<_KeyGenerationDialog> createState() => _KeyGenerationDialogState();
}

class _KeyGenerationDialogState extends State<_KeyGenerationDialog> {
  final _nameController = TextEditingController();
  PQCAlgorithm _selectedAlgorithm = PQCAlgorithm.kyber512;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generate a new key'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Numele cheii',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Numele cheii este obligatoriu';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PQCAlgorithm>(
              value: _selectedAlgorithm,
              decoration: const InputDecoration(
                labelText: 'Algoritm PQC',
                border: OutlineInputBorder(),
              ),
              items: PQCAlgorithm.values.map((algorithm) {
                return DropdownMenuItem(
                  value: algorithm,
                  child: Text(algorithm.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedAlgorithm = value;
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Algorithm strength: ${_getAlgorithmStrength(_selectedAlgorithm)} bits',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anulează'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'name': _nameController.text.trim(),
                'algorithm': _selectedAlgorithm,
              });
            }
          },
          child: const Text('Generate'),
        ),
      ],
    );
  }

  int _getAlgorithmStrength(PQCAlgorithm algorithm) {
    switch (algorithm) {
      case PQCAlgorithm.kyber512:
      case PQCAlgorithm.dilithium2:
      case PQCAlgorithm.falcon512:
        return 128;
      case PQCAlgorithm.kyber768:
      case PQCAlgorithm.dilithium3:
        return 192;
      case PQCAlgorithm.kyber1024:
      case PQCAlgorithm.dilithium5:
      case PQCAlgorithm.falcon1024:
        return 256;
    }
  }
}
