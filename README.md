# Club de Tenis Gondomar — App

App móvil oficial del Club de Tenis Gondomar. Flutter + Firebase.

## Stack

- **Flutter** (Dart 3, null-safety)
- **Riverpod** — state management
- **go_router** — routing con guards por rol
- **freezed** — modelos inmutables
- **Firebase** — Auth, Firestore, Storage, Functions, FCM, Crashlytics

## Setup local

### Pre-requisitos

- Flutter SDK >= 3.22
- Node.js 20+ (para Functions)
- Firebase CLI: `npm install -g firebase-tools`
- FlutterFire CLI: `dart pub global activate flutterfire_cli`

### 1. Clonar y configurar Flutter

```bash
git clone <repo-url>
cd ctg_app
flutter pub get
```

### 2. Configurar Firebase

```bash
firebase login
firebase use --add   # seleccionar proyecto
flutterfire configure
```

Esto genera `lib/firebase_options.dart` y `google-services.json` / `GoogleService-Info.plist`.

### 3. Generar código (freezed / riverpod)

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Ejecutar en emuladores Firebase

```bash
firebase emulators:start
```

En otra terminal:

```bash
flutter run --dart-define=USE_EMULATOR=true
```

### 5. Ejecutar la app

```bash
flutter run          # dispositivo conectado o emulador
flutter run -d ios   # iOS simulator
flutter run -d android # Android emulator
```

## Funciones Cloud

```bash
cd functions
npm install
npm run build

# Deploy
firebase deploy --only functions
```

## Tests

```bash
# Unit tests
flutter test

# Tests con coverage
flutter test --coverage

# Golden tests (actualizar baselines)
flutter test --update-goldens
```

## CI/CD

GitHub Actions ejecuta en cada PR:
1. `flutter analyze`
2. `flutter test`
3. Build iOS (sin firma)
4. Build Android APK
5. Deploy Cloud Functions (en `main`)

Ver `.github/workflows/ci.yml`.

## Variables de entorno

Crea `.env` en la raíz (no se sube al repo):

```
FIREBASE_PROJECT_ID=ctg-app
```

## Arquitectura

```
lib/
├── core/           # router, tema, errores, extensiones
├── features/
│   ├── auth/       # data · domain · application · presentation
│   ├── feed/
│   ├── events/
│   ├── rankings/
│   ├── trainings/
│   ├── payments/
│   └── notifications/
├── shared/         # widgets reutilizables
└── main.dart
```

Cada feature sigue Clean Architecture: `domain` define contratos, `data` los implementa, `application` orquesta con Riverpod, `presentation` construye la UI.

## Roles

| Rol          | Permisos                                          |
|--------------|---------------------------------------------------|
| `socio`      | Lee todo, se inscribe a eventos/entrenamientos    |
| `entrenador` | socio + gestiona entrenamientos y asistencia      |
| `admin`      | entrenador + crea posts, eventos, gestiona pagos  |

Los roles se asignan como custom claims de Firebase Auth via Cloud Function.
