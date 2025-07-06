import 'package:flutter/material.dart';

class FloatingActionMenu extends StatefulWidget {
  final VoidCallback onCreateArchive;
  final VoidCallback onImportArchive;
  final AnimationController animationController;

  const FloatingActionMenu({
    super.key,
    required this.onCreateArchive,
    required this.onImportArchive,
    required this.animationController,
  });

  @override
  State<FloatingActionMenu> createState() => _FloatingActionMenuState();
}

class _FloatingActionMenuState extends State<FloatingActionMenu> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Button for import
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(
            0.0,
            _isOpen ? 0.0 : 120.0,
            0.0,
          ),
          child: Opacity(
            opacity: _isOpen ? 1.0 : 0.0,
            child: FloatingActionButton(
              heroTag: "import",
              mini: true,
              onPressed: _isOpen ? widget.onImportArchive : null,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
              child: const Icon(Icons.file_upload),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Button for archive creation
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(
            0.0,
            _isOpen ? 0.0 : 60.0,
            0.0,
          ),
          child: Opacity(
            opacity: _isOpen ? 1.0 : 0.0,
            child: FloatingActionButton(
              heroTag: "create",
              mini: true,
              onPressed: _isOpen ? widget.onCreateArchive : null,
              backgroundColor: Theme.of(context).colorScheme.tertiary,
              foregroundColor: Theme.of(context).colorScheme.onTertiary,
              child: const Icon(Icons.create_new_folder),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Buton principal
        FloatingActionButton(
          heroTag: "main",
          onPressed: _toggleMenu,
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(_isOpen ? Icons.close : Icons.add),
          ),
        ),
      ],
    );
  }

  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
    });
    
    if (_isOpen) {
      widget.animationController.forward();
    } else {
      widget.animationController.reverse();
    }
  }
}
