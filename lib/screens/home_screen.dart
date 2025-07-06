import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/file_service.dart';
import '../services/crypto_service.dart';
import '../models/encrypted_archive.dart';
import '../models/crypto_key.dart';
import '../widgets/archive_card.dart';
import '../widgets/floating_action_menu.dart';
import 'archive_detail_screen.dart';
import 'create_archive_screen.dart';
import 'keys_management_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<EncryptedArchive> _archives = [];
  List<EncryptedArchive> _filteredArchives = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final int _selectedTabIndex = 0;
  
  late TabController _tabController;
  late AnimationController _fabAnimationController;
  FileService? _fileService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _initializeServices() {
    final cryptoService = Provider.of<CryptoService>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    _fileService = FileService(cryptoService, databaseService);
    _loadArchives();
  }

  Future<void> _loadArchives() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final archives = await databaseService.getAllArchives();
      
      if (mounted) {
        setState(() {
          _archives = archives;
          _filteredArchives = archives;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Error loading archives: $e');
      }
    }
  }

  void _filterArchives(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredArchives = _archives;
      } else {
        _filteredArchives = _archives.where((archive) {
          return archive.name.toLowerCase().contains(query.toLowerCase()) ||
                 archive.description.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteArchive(EncryptedArchive archive) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm deletion'),
        content: Text('Are you sure you want to delete the archive "${archive.name}"?'),
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

    if (confirmed == true && _fileService != null) {
      try {
        await _fileService!.deleteEncryptedArchive(archive);
        _showSuccessSnackBar('Archive was successfully deleted');
        _loadArchives();
      } catch (e) {
        _showErrorSnackBar('Error deleting archive: $e');
      }
    }
  }

  Widget _buildArchivesList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_filteredArchives.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isEmpty ? Icons.folder_open : Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty 
                  ? 'You don\'t have encrypted archives yet'
                  : 'No archives found for "$_searchQuery"',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Press + to create your first archive',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadArchives,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredArchives.length,
        itemBuilder: (context, index) {
          final archive = _filteredArchives[index];
          return ArchiveCard(
            archive: archive,
            onTap: () => _openArchiveDetail(archive),
            onDelete: () => _deleteArchive(archive),
          );
        },
      ),
    );
  }

  void _openArchiveDetail(EncryptedArchive archive) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ArchiveDetailScreen(archive: archive),
      ),
    ).then((_) => _loadArchives());
  }

  void _openCreateArchive() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateArchiveScreen(),
      ),
    ).then((_) => _loadArchives());
  }

  void _openKeysManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const KeysManagementScreen(),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PQC Mobile Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key),
            onPressed: _openKeysManagement,
            tooltip: 'Gestionare chei',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: 'Settings',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Deconectare'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Toate', icon: Icon(Icons.folder)),
            Tab(text: 'Recente', icon: Icon(Icons.schedule)),
            Tab(text: 'Favorite', icon: Icon(Icons.star)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search archives...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _filterArchives('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              onChanged: _filterArchives,
            ),
          ),
          
          // Main content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildArchivesList(),
                _buildArchivesList(), // For now, same content
                _buildArchivesList(), // For now, same content
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionMenu(
        onCreateArchive: _openCreateArchive,
        onImportArchive: () {
          // TODO: Implement import
        },
        animationController: _fabAnimationController,
      ),
    );
  }
}
