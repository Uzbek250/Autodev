# AutoDev 🚀

**Personal AI Project Builder** — mobil ilova g'oyangizni AI yordamida to'liq loyihaga aylantiradi.

AutoDev Android APK versiyasini saqlagan holda Flutter Web orqali brauzerda ham ishlaydi.

## Umumiy ko'rinish

AutoDev — foydalanuvchi g'oyasini tabiiy tilda (O'zbek/Ingliz) kiritsa, bir nechta AI agentlarni boshqarib, loyihani rejalashtiradi, arxitektura tuzadi, kod yozadi, xatolarni tuzatadi va joylashtiradi.

```
Foydalanuvchi g'oyasi
    ↓
[Analyst Agent]  → DeepSeek — savollar + eskiz
    ↓
Foydalanuvchi tasdiqlashi
    ↓
[Thinking Agent] → DeepSeek — texnik spetsifikatsiya
    ↓
[Engineer Agent] → DeepSeek — fayl-fayl kod
    ↓
[Auto-Fix Loop]  → DeepSeek — 5 ta urinishgacha
    ↓
ZIP Arxiv  |  Vercel Deploy
```

## Texnologiyalar

| Layer          | Texnologiya          |
|----------------|----------------------|
| Framework      | Flutter 3.24+        |
| Til            | Dart 3.5+            |
| State          | flutter_bloc ^8.1.3  |
| Baza           | SQLite (sqflite)     |
| Web baza       | shared_preferences → browser LocalStorage |
| Xavfsiz saqlash| flutter_secure_storage|
| HTTP           | dio ^5.4.0           |
| AI Provider    | DeepSeek API          |

## O'rnatish

### 1. Talablar

- Flutter SDK 3.24+
- Android Studio / VS Code
- DeepSeek API kaliti → [platform.deepseek.com](https://platform.deepseek.com)
- (Ixtiyoriy) Vercel token → [vercel.com/account/tokens](https://vercel.com/account/tokens)

### 2. Loyihani klonlash

```bash
git clone https://github.com/Uzbek250/Autodev.git
cd Autodev
flutter pub get
```

### 3. Android / mobil ishga tushirish

```bash
flutter run
```

APK build:

```bash
flutter build apk --release
```

APK: `build/app/outputs/flutter-apk/app-release.apk`

---

## Flutter Web

Web build uchun:

```bash
flutter pub get
flutter build web --release
```

Natija: `build/web/`.

Web buildda `sqflite` to'g'ridan-to'g'ri import qilinmaydi. Platform-aware conditional import ishlatiladi:

- Android/iOS/desktop → SQLite (`sqflite`)
- Web → `shared_preferences` orqali browser LocalStorage
- `flutter_secure_storage` WebCrypto/localStorage asosidagi web implementationdan foydalanadi
- ZIP yaratish webda browser Blob/download orqali ishlaydi
- Androiddagi SQLite va native fayl saqlash yo'li o'zgartirilmagan

### Render Static Site

Render'da **Static Site** yarating va GitHub repo/branchni ulang.

Build command:

```bash
flutter pub get && flutter build web --release
```

Publish Directory:

```text
build/web
```

Agar Render build muhitida Flutter SDK oldindan mavjud bo'lmasa, Flutter SDK o'rnatilgan Docker/CI builddan hosil bo'lgan `build/web` artifactini deploy qilish kerak. AutoDev repo'sida Web build workflow ham mavjud bo'lib, u `web-build` branchiga build natijasini chiqarish uchun sozlangan.

Muhim: `flutter_secure_storage` Web'da HTTPS yoki localhost talab qiladi. Render HTTPS bergani uchun production domenida ishlashi kerak.

---

## CodeMagic bilan build

### Signing kalitini yaratish

```bash
keytool -genkey -v \
  -keystore autodev-release.jks \
  -alias autodev \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

### CodeMagic muhit o'zgaruvchilari (`android_signing` guruhi)

| Kalit                  | Qiymat                              |
|------------------------|-------------------------------------|
| `CM_KEYSTORE`          | Base64 encoded keystore faylı       |
| `CM_KEYSTORE_PASSWORD` | Keystore paroli                     |
| `CM_KEY_ALIAS`         | Key alias (masalan: `autodev`)      |
| `CM_KEY_PASSWORD`      | Key paroli                          |

---

## Loyiha tuzilmasi

```
lib/
├── core/
│   ├── constants/     # API, App konstantalari + Agent promptlari
│   ├── error/         # Xatolar va muvaffaqiyatsizliklar
│   ├── theme/         # Material 3 dark/light mavzular
│   └── utils/         # JSON ajratuvchi, kod tekshiruvchi
├── data/
│   ├── datasources/
│   │   ├── local/     # Platform-aware storage + ZIP storage
│   │   └── remote/    # DeepSeek API datasource
│   ├── models/        # SQLite to/from entity map'lar
│   └── repositories/  # Repository implementatsiyalari
├── domain/
│   ├── entities/      # ProjectEntity, FileEntity, ChatMessageEntity...
│   ├── repositories/  # Abstrakt interface'lar
│   └── usecases/      # Biznes logikasi (create, analyst, thinking, engineer, deploy)
└── presentation/
    ├── bloc/          # ProjectBloc + SettingsBloc
    ├── pages/         # 7 ta sahifa
    └── widgets/       # Umumiy widgetlar
```

---

## Xavfsizlik

- API kalitlar **hech qachon** hardcode qilinmaydi
- `flutter_secure_storage` + Android `EncryptedSharedPreferences`
- Web'da secure storage WebCrypto asosida ishlaydi va HTTPS talab qiladi
- `android:allowBackup="false"` — backup orqali saqlanmaydi
- HTTPS only (`usesCleartextTraffic="false"`)

---

*AutoDev bilan yaratildi 🤖*
