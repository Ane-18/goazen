# Goazen (web)

Cuaderno de gimnasio instalable en el móvil (PWA). Sustituye a la app Flutter de `goazenane/`.

- **Bloques fijos**: los ejercicios no cambian dentro de un bloque, así puedes comparar semanas.
- **Registro por serie**: peso, reps y RIR, con tu último registro a la vista.
- **Peso sugerido** por doble progresión + RIR, respetando los incrementos reales de tu gimnasio.
- **Avisos**: ejercicios estancados 3 sesiones y músculos con menos de 10 series semanales.
- **Actividad**: pasos y minutos de cardio de cada día de la semana. Peso y cintura, opcionales.
- **Bloques nuevos**: *Plan → Importar bloque desde Excel* lee un Excel con el mismo formato (hojas "Dia 1", "Dia 2"…, columna "Series x Reps").
- **Datos locales**: todo se guarda en el móvil. Exporta a Excel o a una copia JSON desde *Más*.

La base científica (con referencias) está en la pantalla *Más → La ciencia detrás*.

## Instalar en el móvil

1. Abre la web publicada en Chrome (Android) o Safari (iPhone).
2. Android: menú ⋮ → *Añadir a pantalla de inicio* / *Instalar app*. iPhone: Compartir → *Añadir a pantalla de inicio*.
3. Funciona sin conexión una vez abierta.

## Desarrollo

Sin dependencias ni compilación: HTML, CSS y JavaScript (módulos ES).

```bash
cd web
npm start      # servidor local en http://localhost:8080
npm test       # pruebas de la lógica de progresión (node --test)
```

- `js/progression.js`: lógica pura (sugerencias, estancamiento, volumen, tendencia de peso). Probada en `tests/`.
- `js/data/blocks.js`: el Bloque 3 y los cambios de los bloques 1–2.
- `js/data/history.js`: semanas 1–8 importadas del Excel con `node tools/import-excel-history.cjs <excel>`.
- `sw.js`: caché sin conexión. **Sube `VERSION`** cada vez que publiques cambios.

Se publica sola en GitHub Pages al hacer push a `main` (`.github/workflows/pages.yml`).
