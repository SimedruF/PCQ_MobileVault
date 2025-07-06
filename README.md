# PQC Mobile Vault

O aplicație Flutter modernă pentru administrarea arhivelor criptate cu algoritmi post-cuantici (PQC), oferind securitate de vârf împotriva atacurilor calculatoarelor cuantice.

## 🔐 Caracteristici principale

### Securitate avansată
- **Criptografie post-cuantică**: Suport pentru algoritmi Kyber, Dilithium și Falcon
- **Criptare hibridă**: Combinație AES + PQC pentru performanță și securitate optimă
- **Autentificare securizată**: Parole principale cu hashing SHA-256
- **Protecție împotriva atacurilor cuantice**: Pregătit pentru viitorul computing-ului cuantic

### Gestionarea arhivelor
- **Creare arhive**: Criptarea fișierelor și directoarelor în arhive securizate
- **Extragere securizată**: Decriptarea și extragerea arhivelor cu chei corecte
- **Compresie inteligentă**: Compresie ZIP înainte de criptare
- **Verificare integritate**: Hash-uri SHA-256 pentru validarea datelor

### Interfață intuitivă
- **Material Design 3**: Design modern și intuitiv
- **Tema întunecată/luminoasă**: Suport pentru preferințele utilizatorului
- **Căutare avansată**: Filtrare rapidă a arhivelor
- **Animații fluide**: Experiență utilizator plăcută

### Gestionarea cheilor
- **Generare sigură**: Algoritmi PQC cu diferite nivele de securitate
- **Gestionare simplificată**: Interfață intuitivă pentru chei
- **Backup sigur**: Stocare securizată în baza de date locală
- **Chei multiple**: Suport pentru mai multe algoritmi simultan

## 🛠️ Algoritmi PQC suportați

### Kyber (Încapsularea cheilor)
- **Kyber-512**: Securitate echivalentă AES-128
- **Kyber-768**: Securitate echivalentă AES-192  
- **Kyber-1024**: Securitate echivalentă AES-256

### Dilithium (Semnături digitale)
- **Dilithium-2**: Securitate de nivel 128-bit
- **Dilithium-3**: Securitate de nivel 192-bit
- **Dilithium-5**: Securitate de nivel 256-bit

### Falcon (Semnături compacte)
- **Falcon-512**: Securitate de nivel 128-bit
- **Falcon-1024**: Securitate de nivel 256-bit

## 📱 Instalare și utilizare

### Cerințe de sistem
- **Android**: 5.0 (API 21) sau mai recent
- **iOS**: 11.0 sau mai recent
- **Spațiu stocare**: Minimum 100MB

### Instalare
1. Descărcați APK-ul din secțiunea Releases
2. Activați "Surse necunoscute" în setările Android
3. Instalați aplicația
4. Configurați parola principală la prima pornire

### Prima configurare
1. **Setați parola principală**: Alegeți o parolă puternică
2. **Generați prima cheie**: Selectați un algoritm PQC
3. **Testați funcționalitatea**: Creați o arhivă de test
4. **Configurați setările**: Personalizați aplicația

## 🔧 Dezvoltare

### Tehnologii utilizate
- **Flutter**: Framework UI cross-platform
- **Dart**: Limbaj de programare principal
- **SQLite**: Baza de date locală
- **PointyCastle**: Biblioteci criptografice
- **Material Design 3**: Sistem de design

### Structura proiectului
```
lib/
├── models/          # Modele de date
├── services/        # Servicii business
├── screens/         # Ecrane UI
├── widgets/         # Widget-uri reutilizabile
├── crypto/          # Implementări criptografice
└── main.dart        # Punct de intrare
```

### Instalare pentru dezvoltatori
```bash
# Clonează repository-ul
git clone https://github.com/user/pcq-mobile-vault.git

# Intră în director
cd pcq-mobile-vault

# Instalează dependințele
flutter pub get

# Rulează aplicația
flutter run
```

## 🔒 Securitate și privacy

### Principii de securitate
- **Zero-knowledge**: Parolele nu sunt stocate în formă deschisă
- **Criptare locală**: Toate datele sunt criptate local
- **Fără cloud**: Datele rămân pe dispozitivul utilizatorului
- **Audit open-source**: Codul este disponibil pentru verificare

### Considerații importante
- **Backup-uri**: Faceți backup la chei în mod regulat
- **Parole puternice**: Folosiți parole de cel puțin 12 caractere
- **Actualizări**: Mențineți aplicația la zi
- **Siguranța dispozitivului**: Folosiți blocarea ecranului

## 🤝 Contribuții

Contribuțiile sunt binevenite! Vă rugăm să:

1. Fork-uiți repository-ul
2. Creați o ramură pentru feature (`git checkout -b feature/new-feature`)
3. Commit-uiți modificările (`git commit -am 'Add new feature'`)
4. Push-uiți la ramură (`git push origin feature/new-feature`)
5. Creați un Pull Request

### Ghid pentru contribuitori
- Respectați convențiile de cod Dart
- Adăugați teste pentru funcționalități noi
- Documentați modificările în comentarii
- Testați pe multiple platforme

## 📄 Licență

Acest proiect este licențiat sub licența MIT. Vedeți fișierul [LICENSE](LICENSE) pentru detalii.

## 📞 Suport

Pentru întrebări, probleme sau sugestii:
- **Issues**: Folosiți GitHub Issues
- **Discussions**: Forum comunitate pe GitHub
- **Email**: support@pcq-mobile-vault.com

## 🚀 Roadmap

### Versiunea 1.1
- [ ] Suport pentru semnături digitale
- [ ] Backup în cloud criptat
- [ ] Autentificare biometrică
- [ ] Partajare securizată

### Versiunea 1.2
- [ ] Plugin pentru manageri de fișiere
- [ ] Integrare cu servicii cloud
- [ ] Audit log complet
- [ ] Suport pentru HSM

### Versiunea 2.0
- [ ] Arhitectură distribuită
- [ ] Suport pentru echipe
- [ ] API pentru integrări
- [ ] Versiune desktop

## 🌟 Mulțumiri

Mulțumim comunității open-source pentru:
- **Flutter Team**: Framework excelent
- **PointyCastle**: Implementări criptografice
- **Material Design**: Sistem de design modern
- **Comunitatea PQC**: Cercetare în criptografie post-cuantică

---

**Nota**: Această aplicație este în dezvoltare activă. Funcționalitățile PQC sunt implementate în scop educativ și demonstrativ. Pentru utilizare în producție, recomandăm utilizarea bibliotecilor PQC certificate și auditate.

**Disclaimer**: Autorii nu își asumă responsabilitatea pentru pierderea datelor sau problemele de securitate. Utilizați pe propria răspundere și faceți backup-uri regulate.
