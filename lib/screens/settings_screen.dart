import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricEnabled = false;
  bool _autoLockEnabled = true;
  int _autoLockMinutes = 5;
  bool _showHiddenFiles = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setări'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Securitate
          _buildSectionHeader('Securitate'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.fingerprint),
                  title: const Text('Autentificare biometrică'),
                  subtitle: const Text('Folosește amprenta sau recunoașterea facială'),
                  trailing: Switch(
                    value: _biometricEnabled,
                    onChanged: (value) {
                      setState(() {
                        _biometricEnabled = value;
                      });
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_clock),
                  title: const Text('Blocare automată'),
                  subtitle: Text(_autoLockEnabled 
                      ? 'Blochează după $_autoLockMinutes minute de inactivitate'
                      : 'Dezactivat'),
                  trailing: Switch(
                    value: _autoLockEnabled,
                    onChanged: (value) {
                      setState(() {
                        _autoLockEnabled = value;
                      });
                    },
                  ),
                ),
                if (_autoLockEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.timer),
                    title: const Text('Timpul de blocare'),
                    subtitle: Text('$_autoLockMinutes minute'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showAutoLockDialog(),
                  ),
                ],
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.password),
                  title: const Text('Schimbă parola'),
                  subtitle: const Text('Schimbă parola principală'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showChangePasswordDialog(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Fișiere
          _buildSectionHeader('Fișiere'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.visibility),
                  title: const Text('Afișează fișiere ascunse'),
                  subtitle: const Text('Afișează fișierele care încep cu "."'),
                  trailing: Switch(
                    value: _showHiddenFiles,
                    onChanged: (value) {
                      setState(() {
                        _showHiddenFiles = value;
                      });
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cleaning_services),
                  title: const Text('Curăță cache-ul'),
                  subtitle: const Text('Șterge fișierele temporare'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showClearCacheDialog(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Despre
          _buildSectionHeader('Despre'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('Versiune'),
                  subtitle: const Text('1.0.0+1'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showAboutDialog(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Despre PQC'),
                  subtitle: const Text('Criptografia post-cuantică'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showPQCInfoDialog(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('Licență'),
                  subtitle: const Text('Termenii și condițiile'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showLicenseDialog(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Acțiuni periculoase
          _buildSectionHeader('Acțiuni periculoase'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Resetează aplicația', style: TextStyle(color: Colors.red)),
                  subtitle: const Text('Șterge toate datele și setările'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showResetDialog(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showAutoLockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Timpul de blocare automată'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<int>(
              title: const Text('1 minut'),
              value: 1,
              groupValue: _autoLockMinutes,
              onChanged: (value) {
                setState(() {
                  _autoLockMinutes = value!;
                });
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<int>(
              title: const Text('5 minute'),
              value: 5,
              groupValue: _autoLockMinutes,
              onChanged: (value) {
                setState(() {
                  _autoLockMinutes = value!;
                });
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<int>(
              title: const Text('15 minute'),
              value: 15,
              groupValue: _autoLockMinutes,
              onChanged: (value) {
                setState(() {
                  _autoLockMinutes = value!;
                });
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<int>(
              title: const Text('30 minute'),
              value: 30,
              groupValue: _autoLockMinutes,
              onChanged: (value) {
                setState(() {
                  _autoLockMinutes = value!;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schimbă parola'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Parola actuală',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Parola actuală este obligatorie';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Parola nouă',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Parola nouă este obligatorie';
                  }
                  if (value.length < 6) {
                    return 'Parola trebuie să aibă cel puțin 6 caractere';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmă parola nouă',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirmarea parolei este obligatorie';
                  }
                  if (value != newPasswordController.text) {
                    return 'Parolele nu se potrivesc';
                  }
                  return null;
                },
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
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final success = await authService.changePassword(
                  oldPasswordController.text,
                  newPasswordController.text,
                );
                
                Navigator.of(context).pop();
                
                if (success) {
                  _showSuccessSnackBar('Parola a fost schimbată cu succes');
                } else {
                  _showErrorSnackBar('Parola actuală este incorectă');
                }
              }
            },
            child: const Text('Schimbă'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Curăță cache-ul'),
        content: const Text('Această acțiune va șterge toate fișierele temporare. Continui?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showSuccessSnackBar('Cache-ul a fost curățat');
            },
            child: const Text('Curăță'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Despre PQC Mobile Vault'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PQC Mobile Vault v1.0.0'),
            SizedBox(height: 8),
            Text('O aplicație pentru administrarea arhivelor criptate cu algoritmi '
                'post-cuantici, oferind securitate împotriva atacurilor calculatoarelor cuantice.'),
            SizedBox(height: 16),
            Text('Dezvoltat cu Flutter'),
            Text('© 2024 PQC Mobile Vault'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Închide'),
          ),
        ],
      ),
    );
  }

  void _showPQCInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Criptografia post-cuantică'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Criptografia post-cuantică (PQC) este o nouă generație de algoritmi criptografici '
                'care sunt rezistenți la atacurile calculatoarelor cuantice.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'De ce este importantă?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Calculatoarele cuantice pot sparge algoritmii criptografici actuali (RSA, ECC) '
                'mult mai rapid decât calculatoarele clasice. PQC oferă protecție împotriva '
                'acestor atacuri viitoare.',
              ),
              SizedBox(height: 16),
              Text(
                'Algoritmi utilizați:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Kyber: Încapsularea cheilor bazată pe Learning With Errors'),
              Text('• Dilithium: Semnături digitale bazate pe rețele'),
              Text('• Falcon: Semnături digitale compacte'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Închide'),
          ),
        ],
      ),
    );
  }

  void _showLicenseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Licență'),
        content: const SingleChildScrollView(
          child: Text(
            'MIT License\n\n'
            'Copyright (c) 2024 PQC Mobile Vault\n\n'
            'Permission is hereby granted, free of charge, to any person obtaining a copy '
            'of this software and associated documentation files (the "Software"), to deal '
            'in the Software without restriction, including without limitation the rights '
            'to use, copy, modify, merge, publish, distribute, sublicense, and/or sell '
            'copies of the Software, and to permit persons to whom the Software is '
            'furnished to do so, subject to the following conditions:\n\n'
            'The above copyright notice and this permission notice shall be included in all '
            'copies or substantial portions of the Software.\n\n'
            'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR '
            'IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, '
            'FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE '
            'AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER '
            'LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, '
            'OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE '
            'SOFTWARE.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Închide'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resetează aplicația'),
        content: const Text(
          'ATENȚIE: Această acțiune va șterge TOATE datele din aplicație, '
          'inclusiv arhivele criptate și cheile. Această acțiune nu poate fi anulată.\n\n'
          'Ești sigur că vrei să continui?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              final databaseService = Provider.of<DatabaseService>(context, listen: false);
              
              await authService.reset();
              await databaseService.close();
              
              Navigator.of(context).pop();
              _showSuccessSnackBar('Aplicația a fost resetată');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Resetează'),
          ),
        ],
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
