# Excel de plan con la estética del Excel de Ane

Genera el Excel del Bloque 1 de la madre usando el Excel de Ane (`Plan_Entrenamiento_Ane_Bloque3.xlsx`) como plantilla de estilos: mismas fuentes, colores, columnas y celdas combinadas. Sin Python: Node + PowerShell.

1. Descomprime el Excel de Ane en una carpeta: `unzip Plan_Entrenamiento_Ane_Bloque3.xlsx -d ane/`
2. Edita `DAYS`, `NOTE` y `GUIDE` en `gen-bloque1-madre.cjs` (ejercicios, notas y textos de la Guía).
3. `node gen-bloque1-madre.cjs ane/ salida/`
4. `powershell -ExecutionPolicy Bypass -File zip-xlsx.ps1 salida/ Plan.xlsx`
5. Comprueba que la app lo importa sin avisos y pásalo a datos de la app:
   `node ../import-block.cjs Plan.xlsx ../../js/data/plan-bloque1.js PLAN_BLOQUE1 bloque1 "Bloque 1" <inicio> <rirMin> <rirMax> "<descripción>" [<inicio semana de prueba>] <rev>`

Las fotos del Excel de Ane no se copian; la columna B lleva un enlace "Ver vídeo" (búsqueda en YouTube).
Para ver cómo queda sin abrir Excel a mano: Excel está instalado y se puede exportar cada hoja a PNG por COM (Range.CopyPicture + Chart.Export).
