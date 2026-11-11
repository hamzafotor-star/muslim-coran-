# tools/build_apk_local.ps1
# =========================
# Script de préparation et de compilation locale de l'APK Muslim Coran sur Windows.
# Prérequis : Flutter SDK et Android SDK installés et présents dans le PATH.

$ErrorActionPreference = "Stop"

Write-Host "=== 1. Vérification de Flutter SDK ===" -ForegroundColor Cyan
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Error "Flutter n'est pas installé ou absent du PATH. Installez Flutter (https://docs.flutter.dev/get-started/install/windows/mobile) et Android Studio / Android SDK Command-Line Tools."
    exit 1
}

Write-Host "=== 2. Téléchargement des 3 polices arabes sous licence OFL ===" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path "assets\fonts" | Out-Null
$fonts = @{
    "assets\fonts\AmiriQuran-Regular.ttf"      = "https://raw.githubusercontent.com/google/fonts/main/ofl/amiriquran/AmiriQuran-Regular.ttf"
    "assets\fonts\ScheherazadeNew-Regular.ttf" = "https://raw.githubusercontent.com/google/fonts/main/ofl/scheherazadenew/ScheherazadeNew-Regular.ttf"
    "assets\fonts\Lateef-Regular.ttf"          = "https://raw.githubusercontent.com/google/fonts/main/ofl/lateef/Lateef-Regular.ttf"
}
foreach ($dest in $fonts.Keys) {
    if (-not (Test-Path $dest)) {
        Write-Host "Téléchargement de $dest ..."
        Invoke-WebRequest -Uri $fonts[$dest] -OutFile $dest
    }
}

Write-Host "=== 3. Génération et vérification de assets\db\quran.db ===" -ForegroundColor Cyan
node tools/build_quran_db.mjs

Write-Host "=== 4. Génération des fichiers Gradle Android manquants ===" -ForegroundColor Cyan
flutter create . --platforms=android --project-name muslim_coran --org com.muslimcoran
git checkout -- android/app/src/main/AndroidManifest.xml android/app/build.gradle lib/ test/ pubspec.yaml

Write-Host "=== 5. Récupération des dépendances et tests ===" -ForegroundColor Cyan
flutter pub get
flutter analyze
flutter test

Write-Host "=== 6. Compilation des APK de release découpés par ABI ===" -ForegroundColor Cyan
flutter build apk --release --split-per-abi

Write-Host "`n[SUCCÈS] Vos fichiers APK sont prêts dans : build\app\outputs\flutter-apk\" -ForegroundColor Green
Get-ChildItem "build\app\outputs\flutter-apk\*.apk" | Select-Object Name, @{Name="Taille (Mo)";Expression={[math]::Round($_.Length / 1MB, 2)}}
