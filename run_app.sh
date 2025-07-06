#!/bin/bash

# Script pentru rularea aplicației PQC Mobile Vault

echo "🔐 PQC Mobile Vault - Pornire aplicație..."
echo "=========================================="

# Verifică dacă Flutter este instalat
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter nu este instalat. Vă rugăm să instalați Flutter mai întâi."
    echo "📖 Ghid instalare: https://docs.flutter.dev/get-started/install"
    exit 1
fi

# Verifică versiunea Flutter
echo "📱 Verificare versiune Flutter..."
flutter --version

# Instalează dependințele
echo "📦 Instalare dependințe..."
flutter pub get

# Verifică dacă există dispozitive conectate
echo "🔍 Căutare dispozitive..."
flutter devices

echo ""
echo "🚀 Pornire aplicație..."
echo "Asigurați-vă că aveți un dispozitiv Android conectat sau un emulator pornit."
echo ""

# Rulează aplicația
flutter run

echo "✅ Aplicația a fost pornită cu succes!"
