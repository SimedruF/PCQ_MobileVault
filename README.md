# PQC Mobile Vault

A modern Flutter application for managing encrypted archives with post-quantum cryptography (PQC) algorithms, providing top-tier security against quantum computer attacks.

## 🔐 Main Features

### Advanced Security
- **Post-Quantum Cryptography**: Support for Kyber, Dilithium, and Falcon algorithms
- **Hybrid Encryption**: AES + PQC combination for optimal performance and security
- **Secure Authentication**: Master passwords with SHA-256 hashing
- **Quantum Attack Protection**: Ready for the future of quantum computing

### Archive Management
- **Archive Creation**: Encryption of files and directories into secure archives
- **Secure Extraction**: Decryption and extraction of archives with correct keys
- **Smart Compression**: ZIP compression before encryption
- **Integrity Verification**: SHA-256 hashes for data validation

### Intuitive Interface
- **Material Design 3**: Modern and intuitive design
- **Dark/Light Theme**: Support for user preferences
- **Advanced Search**: Quick filtering of archives
- **Smooth Animations**: Pleasant user experience

### Key Management
- **Secure Generation**: PQC algorithms with different security levels
- **Simplified Management**: Intuitive interface for keys
- **Secure Backup**: Safe storage in local database
- **Multiple Keys**: Support for multiple algorithms simultaneously

## 🛠️ Supported PQC Algorithms

### Kyber (Key Encapsulation)
- **Kyber-512**: AES-128 equivalent security
- **Kyber-768**: AES-192 equivalent security  
- **Kyber-1024**: AES-256 equivalent security

### Dilithium (Digital Signatures)
- **Dilithium-2**: 128-bit security level
- **Dilithium-3**: 192-bit security level
- **Dilithium-5**: 256-bit security level

### Falcon (Compact Signatures)
- **Falcon-512**: 128-bit security level
- **Falcon-1024**: 256-bit security level

## 📱 Installation and Usage

### System Requirements
- **Android**: 5.0 (API 21) or newer
- **iOS**: 11.0 or newer
- **Storage Space**: Minimum 100MB

### Installation
1. Download the APK from the Releases section
2. Enable "Unknown sources" in Android settings
3. Install the application
4. Set up master password on first launch

### Initial Setup
1. **Set master password**: Choose a strong password
2. **Generate first key**: Select a PQC algorithm
3. **Test functionality**: Create a test archive
4. **Configure settings**: Customize the application

## 🔧 Development

### Technologies Used
- **Flutter**: Cross-platform UI framework
- **Dart**: Main programming language
- **SQLite**: Local database
- **PointyCastle**: Cryptographic libraries
- **Material Design 3**: Design system

### Project Structure
```
lib/
├── models/          # Data models
├── services/        # Business services
├── screens/         # UI screens
├── widgets/         # Reusable widgets
├── crypto/          # Cryptographic implementations
└── main.dart        # Entry point
```

### Installation for Developers
```bash
# Clone the repository
git clone https://github.com/user/pcq-mobile-vault.git

# Enter directory
cd pcq-mobile-vault

# Install dependencies
flutter pub get

# Run the application
flutter run
```

## 🔒 Security and Privacy

### Security Principles
- **Zero-knowledge**: Passwords are not stored in plain text
- **Local encryption**: All data is encrypted locally
- **No cloud**: Data remains on user's device
- **Open-source audit**: Code is available for verification

### Important Considerations
- **Backups**: Backup keys regularly
- **Strong passwords**: Use passwords of at least 12 characters
- **Updates**: Keep the application up to date
- **Device security**: Use screen locking

## 🤝 Contributions

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-feature`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Create a Pull Request

### Contributor Guide
- Follow Dart code conventions
- Add tests for new features
- Document changes in comments
- Test on multiple platforms

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 📞 Support

For questions, issues, or suggestions:
- **Issues**: Use GitHub Issues
- **Discussions**: Community forum on GitHub
- **Email**: support@pcq-mobile-vault.com

## 🚀 Roadmap

### Version 1.1
- [ ] Digital signature support
- [ ] Encrypted cloud backup
- [ ] Biometric authentication
- [ ] Secure sharing

### Version 1.2
- [ ] File manager plugins
- [ ] Cloud service integration
- [ ] Complete audit log
- [ ] HSM support

### Version 2.0
- [ ] Distributed architecture
- [ ] Team support
- [ ] Integration API
- [ ] Desktop version

## 🌟 Acknowledgments

Thanks to the open-source community for:
- **Flutter Team**: Excellent framework
- **PointyCastle**: Cryptographic implementations
- **Material Design**: Modern design system
- **PQC Community**: Research in post-quantum cryptography

---

**Note**: This application is in active development. PQC functionalities are implemented for educational and demonstrative purposes. For production use, we recommend using certified and audited PQC libraries.

**Disclaimer**: The authors do not assume responsibility for data loss or security issues. Use at your own risk and make regular backups.
