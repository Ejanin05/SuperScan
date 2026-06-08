# SuperScan 🛒

**Control tu gasto en el supermercado en tiempo real.**

SuperScan usa la cámara del celular y Google ML Kit OCR para detectar el nombre y precio de los productos escaneando las etiquetas de las góndolas, agregándolos automáticamente a una lista con total acumulado.

---

## 📐 Arquitectura

```
lib/
├── core/
│   ├── theme.dart               # Material 3 dark theme (Outfit font, verde esmeralda)
│   └── currency_formatter.dart  # Formateo ARS: $3.500 / $2.499,99
│
├── data/
│   ├── datasources/
│   │   ├── local_datasource.dart   # SQLite (sqflite) con Stream broadcast
│   │   └── ocr_datasource.dart     # Google ML Kit + parser inteligente de precios
│   ├── models/
│   │   └── purchase_item_model.dart  # DTO: fromMap / toMap para SQLite
│   └── repositories/
│       ├── purchase_repository_impl.dart
│       └── ocr_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   ├── purchase_item.dart   # Entidad pura (Equatable)
│   │   └── scan_result.dart     # Resultado OCR: name?, price?, rawText
│   ├── repositories/
│   │   ├── purchase_repository.dart  # Contrato abstracto
│   │   └── ocr_repository.dart       # Contrato abstracto
│   └── usecases/
│       └── purchase_usecases.dart    # WatchItems, Add, Update, Delete, Clear, ProcessImage
│
├── presentation/
│   ├── pages/
│   │   ├── home_page.dart         # Lista + total acumulado
│   │   ├── scan_page.dart         # Cámara + frame de escaneo
│   │   ├── confirm_scan_page.dart # Revisión/edición OCR antes de guardar
│   │   └── edit_item_page.dart    # Editar/eliminar producto existente
│   └── providers/
│       └── purchase_provider.dart  # Riverpod: PurchaseNotifier + StateNotifierProvider
│
└── main.dart
```

### Patrón de capas

```
Presentation → Domain (Use Cases) → Repository (abstract) ← Impl (Data)
```

- **Domain** no sabe nada de Flutter ni de SQLite.
- **Data** implementa los repositorios con sqflite y ML Kit.
- **Presentation** solo habla con Use Cases a través de Riverpod.

---

## 🔬 Parser OCR inteligente

El `OcrDatasource` aplica un parser en 3 pasos:

### Detección de precio (en orden de prioridad)

| Patrón | Ejemplo | Resultado |
|--------|---------|-----------|
| `$` + número con separadores europeos | `$2.499,99` | `2499.99` |
| `$` + número simple | `$3500` | `3500.0` |
| `N x $PRECIO` | `2 x $6000` | `6000.0` |
| Número bare ≥ 100 (último recurso) | `3500` | `3500.0` |

### Normalización de números

| Entrada | Lógica | Salida |
|---------|--------|--------|
| `3.500,99` | Separador final `,` → europeo | `3500.99` |
| `3,500.99` | Separador final `.` → americano | `3500.99` |
| `3500` | Sin decimales | `3500.0` |

### Detección de nombre

- Toma la primera línea que:
  - No sea solo números/símbolos
  - No empiece con palabras clave como `PROMOCIÓN`, `OFERTA`, `TOTAL`
  - Tenga al menos 3 caracteres
- Elimina la porción de precio de la línea
- Convierte a Title Case

---

## 🚀 Compilar y ejecutar

### Prerequisitos

```bash
# Flutter SDK 3.x estable
flutter --version

# Android SDK con NDK configurado
# Java 17 (recomendado con Flutter 3.x)
java --version
```

### 1. Clonar / descomprimir el proyecto

```bash
cd superscan/
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Ejecutar en modo debug

```bash
# Listar dispositivos disponibles
flutter devices

# Correr en el dispositivo conectado (o emulador)
flutter run
```

### 4. Compilar APK de release

```bash
# APK universal (funciona en cualquier arquitectura)
flutter build apk --release

# APK separadas por arquitectura (más livianas)
flutter build apk --split-per-abi --release
```

El APK queda en:
```
build/app/outputs/flutter-apk/app-release.apk
```

### 5. Instalar en el dispositivo

```bash
# Instalar directamente vía ADB
adb install build/app/outputs/flutter-apk/app-release.apk

# O desde Flutter
flutter install
```

---

## ⚙️ Configuración Android

### Permisos requeridos (ya en AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

### minSdkVersion

El proyecto usa `minSdkVersion 21` (Android 5.0 Lollipop) por requisito de Google ML Kit.

### Modelo ML Kit embebido

El modelo OCR Latin de ML Kit se descarga automáticamente en el primer uso. Para empaquetar el modelo en el APK (sin descarga), el `AndroidManifest.xml` incluye:

```xml
<meta-data
    android:name="com.google.mlkit.vision.DEPENDENCIES"
    android:value="ocr" />
```

Y en `build.gradle`:

```groovy
implementation 'com.google.mlkit:text-recognition:16.0.1'
```

---

## 🎨 UI / UX

| Elemento | Decisión |
|----------|----------|
| **Tema** | Dark mode permanente, fondo `#0F1923` (azul-marino profundo) |
| **Color primario** | `#00C896` (verde esmeralda) — evoca dinero/ahorro |
| **Tipografía** | Google Fonts **Outfit** — moderna, redondeada, muy legible |
| **Total** | 48px bold, animado con crossfade al cambiar |
| **Cards** | Dismissible (swipe izquierda para eliminar) |
| **Scan frame** | Custom painter con esquinas verdes tipo scanner |
| **Animaciones** | flutter_animate: fade+slide staggered en lista, pulso en botón captura |

---

## 🔮 Extensibilidad (preparado para futuras features)

| Feature | Cómo extenderla |
|---------|----------------|
| **Código de barras** | Agregar `BarcodeScanner` de ML Kit en `OcrDatasource`, nuevo `BarcodeScanResult` entity |
| **Historial de compras** | Agregar tabla `purchases` en SQLite, `PurchaseSession` entity, nueva pantalla |
| **Presupuestos** | Nuevo `BudgetRepository` + `BudgetNotifier`, pantalla de configuración |
| **Exportar a Excel** | Usar `xlsx` package en un nuevo `ExportUseCase` |
| **Sincronización cloud** | Implementar nueva variante de `PurchaseRepository` con Supabase/Firebase |
| **Comparación de precios** | Guardar historial de precios por producto, `PriceHistoryRepository` |

---

## 📦 Dependencias principales

| Package | Versión | Uso |
|---------|---------|-----|
| `flutter_riverpod` | ^2.5.1 | Estado reactivo |
| `google_mlkit_text_recognition` | ^0.13.1 | OCR (Latin script) |
| `camera` | ^0.11.0 | Preview y captura |
| `sqflite` | ^2.3.3 | SQLite local |
| `flutter_animate` | ^4.5.0 | Animaciones declarativas |
| `google_fonts` | ^6.2.1 | Outfit font |
| `intl` | ^0.19.0 | Formato de fechas/moneda |
| `uuid` | ^4.4.2 | IDs únicos |
| `equatable` | ^2.0.5 | Comparación de entidades |
| `gap` | ^3.0.1 | Espaciado semántico |
