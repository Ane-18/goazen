# Goazenane

App de fitness femenino con base científica — recomposición corporal real.

[![Build APK](https://github.com/TU_USUARIO/goazenane/actions/workflows/build.yml/badge.svg)](https://github.com/TU_USUARIO/goazenane/actions/workflows/build.yml)

---

## ¿Qué es?

Goazenane es una app móvil multiplataforma (iOS + Android) diseñada específicamente para mujeres que buscan recomposición corporal real. Combina entrenamiento de fuerza progresivo, nutrición basada en evidencia y ajuste automático al ciclo menstrual.

**Base científica:** Schoenfeld (2010, 2016) · Israetel et al. · Helms (2014) · Stacy Sims (2022)

---

## Características principales

### Entrenamiento
- Generador de rutinas automático (Full Body, Torso/Pierna, PPL)
- Periodización adaptativa de 12 semanas (acumulación → intensificación → pico)
- Deload inteligente por RPE, rendimiento o FC en reposo
- Calentamiento guiado con temporizador
- Temporizador de descanso configurable
- Sobrecarga progresiva automática
- Catálogo de 100+ ejercicios con descripción técnica y errores comunes

### Nutrición
- Calculadora Katch-McArdle (la más precisa con % grasa)
- Macros calculados sobre masa magra (no peso total)
- Ajuste automático por fase del ciclo y día de entrenamiento
- Base de datos de 80+ alimentos limpios
- Seguimiento de hidratación con recordatorios

### Ciclo menstrual
- Ajuste de volumen e intensidad por fase
- Cardio recomendado según fase (LISS / HIIT)
- Preguntas semanales no intrusivas
- Solo aplica si no usas anticonceptivos hormonales

### Integración Mi Band 3
- FC en reposo → detección de sobreentreno
- Horas de sueño → ajuste de volumen del día
- Pasos diarios → recálculo del TDEE
- FC durante cardio → confirmación de zona
- **Todos los datos: 100% local, nunca suben a ningún servidor**

### Progreso
- Peso: media de 7 días (elimina ruido hormonal)
- Foto-diario local con comparativa
- Gráficas de fuerza, sueño y rendimiento
- Rachas de entrenamiento, macros e hidratación
- Logros desbloqueables

---

## Stack técnico

| Tecnología | Uso |
|-----------|-----|
| Flutter 3.x + Dart | Framework multiplataforma |
| Riverpod 2.x | Estado reactivo |
| Drift (SQLite tipado) | Base de datos local |
| GoRouter | Navegación |
| fl_chart | Gráficas |
| flutter_blue_plus | BLE / Mi Band 3 |
| image_picker | Fotos de progreso |
| flutter_local_notifications | Notificaciones (sin Firebase) |
| GitHub Actions | CI/CD → APK automático |

---

## Instalación

### Opción A — APK directo (Android)

1. Ve a [Releases](../../releases) y descarga el último `app-release.apk`
2. En tu Android: **Ajustes → Seguridad → Instalar apps desconocidas → Activar**
3. Abre el APK descargado e instala

### Opción B — Compilar desde fuente

**Prerrequisitos:**
- [Flutter 3.27+](https://flutter.dev/docs/get-started/install)
- Android Studio / Xcode
- JDK 17

```bash
# Clonar el repositorio
git clone https://github.com/TU_USUARIO/goazenane.git
cd goazenane

# Instalar dependencias
flutter pub get

# Generar código (Drift + Riverpod)
dart run build_runner build --delete-conflicting-outputs

# Ejecutar en modo debug
flutter run

# Compilar APK de release
flutter build apk --release
```

---

## Privacidad

- **Sin Firebase.** Notificaciones push con `flutter_local_notifications`.
- **Sin servidores externos.** Todos los datos se quedan en tu dispositivo.
- **Sin analíticas.** No hay rastreo de uso.
- Fotos de progreso: almacenadas localmente, excluidas del `.gitignore`.

---

## Descargo de responsabilidad

Esta app es una herramienta educativa basada en evidencia científica publicada. No sustituye a un médico, nutricionista o entrenador personal certificado. Consulta con un profesional de salud antes de iniciar cualquier programa de ejercicio, especialmente si tienes condiciones de salud preexistentes.

---

## Licencia

MIT
