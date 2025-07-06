import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isObscured = true;
  bool _isObscuredConfirm = true;
  bool _isLoading = false;
  bool _isFirstTime = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  Future<void> _checkFirstTime() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final hasPassword = await authService.hasPasswordSet();
    setState(() {
      _isFirstTime = !hasPassword;
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isFirstTime && _passwordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Parolele nu se potrivesc');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.authenticate(_passwordController.text);
      
      if (!success) {
        _showErrorSnackBar('Parolă incorectă');
      }
    } catch (e) {
      _showErrorSnackBar('Eroare la autentificare: $e');
    }

    setState(() {
      _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo și titlu
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.security,
                                size: 40,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'PQC Mobile Vault',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isFirstTime 
                                  ? 'Configurează parola principală'
                                  : 'Introdu parola pentru acces',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            
                            // Câmp parolă
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _isObscured,
                              decoration: InputDecoration(
                                labelText: _isFirstTime ? 'Parolă nouă' : 'Parolă',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(_isObscured ? Icons.visibility : Icons.visibility_off),
                                  onPressed: () {
                                    setState(() {
                                      _isObscured = !_isObscured;
                                    });
                                  },
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Parola este obligatorie';
                                }
                                if (_isFirstTime && value.length < 6) {
                                  return 'Parola trebuie să aibă cel puțin 6 caractere';
                                }
                                return null;
                              },
                            ),
                            
                            // Câmp confirmare parolă (doar pentru prima configurare)
                            if (_isFirstTime) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _isObscuredConfirm,
                                decoration: InputDecoration(
                                  labelText: 'Confirmă parola',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(_isObscuredConfirm ? Icons.visibility : Icons.visibility_off),
                                    onPressed: () {
                                      setState(() {
                                        _isObscuredConfirm = !_isObscuredConfirm;
                                      });
                                    },
                                  ),
                                  border: const OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Confirmarea parolei este obligatorie';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            
                            const SizedBox(height: 32),
                            
                            // Buton autentificare
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _authenticate,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Text(
                                        _isFirstTime ? 'Configurează' : 'Autentifică-te',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                              ),
                            ),
                            
                            if (_isFirstTime) ...[
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Theme.of(context).colorScheme.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Informații despre securitate',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Parola va fi folosită pentru protejarea arhivelor tale criptate. '
                                      'Asigură-te că o ții în siguranță - nu poate fi recuperată dacă o uiți.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
