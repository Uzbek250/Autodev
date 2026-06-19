# AutoDev 🚀

**Personal AI Project Builder** — mobil ilova g'oyangizni AI yordamida to'liq loyihaga aylantiradi.

## Umumiy ko'rinish

AutoDev — foydalanuvchi g'oyasini tabiiy tilda (O'zbek/Ingliz) kiritsa, bir nechta AI agentlarni boshqarib, loyihani rejalashtiradi, arxitektura tuzadi, kod yozadi, xatolarni tuzatadi va joylashtiradi.

```
Foydalanuvchi g'oyasi
    ↓
[Analyst Agent]  → Kimi K2.6  — savollar + eskiz
    ↓
Foydalanuvchi tasdiqlashi
    ↓
[Thinking Agent] → Kimi K2.6  — texnik spetsifikatsiya
    ↓
[Engineer Agent] → Kimi K2.7-code — fayl-fayl kod
    ↓
[Auto-Fix Loop]  → Kimi K2.7-code — 5 ta urinishgacha
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
| Xavfsiz saqlash| flutter_secure_storage|
| HTTP           | dio ^5.4.0           |
| AI Provider    | Moonshot AI (Kimi)   |

## O'rnatish

### 1. Talablar

- Flutter SDK 3.24+
- Android Studio / VS Code
- Moonshot AI API kaliti → [platform.moonshot.cn](https://platform.moonshot.cn)
- (Ixtiyoriy) Vercel token → [vercel.com/account/tokens](https://vercel.com/account/tokens)

### 2. Loyihani klonlash

```bash
git clone https://github.com/your-username/autodev.git
cd autodev
flutter pub get
```

### 3. Ishga tushirish

```bash
flutter run
```

### 4. API kalitlarini sozlash

Ilova ichida **Sozlamalar** ↗ sahifasiga o'ting:
- **Kimi API Kalit** — Moonshot platformasidan olingan kalit
- **Vercel Token** — faqat Vercel deploy uchun kerak

Kalitlar `flutter_secure_storage` orqali **shifrlangan** holda saqlanadi, hech qanday serverga yuborilmaydi.

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

### Build buyrug'i

```bash
flutter build apk --release
```

APK: `build/app/outputs/flutter-apk/app-release.apk`

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
│   │   ├── local/     # SQLite database helper
│   │   └── remote/    # Kimi API datasource
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
- `android:allowBackup="false"` — backup orqali saqlanmaydi
- HTTPS only (`usesCleartextTraffic="false"`)

---

*AutoDev bilan yaratildi 🤖*
