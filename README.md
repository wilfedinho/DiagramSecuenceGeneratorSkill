# DSS Generator Skill — Guía de instalación y uso

## ¿Qué hace esta skill?

Automatiza la generación de Diagramas de Secuencia del Sistema (DSS) desde
especificaciones de casos de uso hasta Enterprise Architect 15.2, con revisión
humana en cada paso.

## Archivos incluidos

```
dss-generator-skill/
├── SKILL.md                        ← Instrucciones para Claude (cargar esto)
├── README.md                       ← Esta guía
├── Create-Sequence-Diagram.vbs     ← Script para Enterprise Architect 15.2
└── ejemplo_especificacion_CU.md    ← Formato de especificación de CU
```

## Instalación

### 1. Instalar la extensión Claude in Chrome

1. Abrir Google Chrome
2. Ir a chrome.com/webstore o directamente a claude.ai/chrome
3. Instalar "Claude for Chrome"
4. Iniciar sesión con tu cuenta de Claude

### 2. Instalar el script en Enterprise Architect

1. Abrir Enterprise Architect 15.2
2. Menú **Specialize** → **Scripting**
3. Click derecho en **VB Scripts** → **Add Group** → nombre: `PlantUML`
4. Click derecho en el grupo `PlantUML` → **Add Script** → nombre: `Create-Sequence-Diagram`
5. Pegar el contenido de `Create-Sequence-Diagram.vbs`
6. Guardar (Ctrl+S)

### 3. Cargar la skill en Claude

En un chat nuevo con Claude, escribir:
```
Cargá la skill desde [ruta donde guardaste SKILL.md]
```
O simplemente pegar el contenido de `SKILL.md` al inicio del chat.

---

## Uso paso a paso

### Opción A — Una especificación a la vez

```
Usuario: [pega o adjunta la especificación del CU]

Claude: Genera el PlantUML y abre plantuml.com en Chrome.
        Se detiene y espera respuesta.

Usuario: "aprobado"

Claude: Guarda DSS_CUN01_plantuml.txt y lo presenta para descarga.
```

### Opción B — Múltiples especificaciones

```
Usuario: [adjunta archivo con todos los CUs]

Claude: Procesa CUN01 → abre en Chrome → espera aprobación
        → procesa CUN02 → abre en Chrome → espera aprobación
        → ...
        → al final presenta todos los .txt aprobados
```

### Opciones de respuesta del usuario

| Respuesta | Acción de Claude |
|---|---|
| `aprobado` | Guarda el .txt y continúa con el siguiente CU |
| `rechazado` | Pide descripción de los cambios |
| `modificar: [descripción]` | Aplica el cambio, regenera y abre nueva pestaña |

---

## Importar en Enterprise Architect

Una vez que tenés los archivos `.txt`:

1. Abrir EA 15.2
2. En el **Project Browser**, seleccionar el paquete destino
3. Ir a **Specialize** → **Scripting** → grupo `PlantUML`
4. Doble click en `Create-Sequence-Diagram`
5. En el InputBox, ingresar la ruta del archivo `.txt`:
   ```
   C:\Users\TuUsuario\Downloads\DSS_CUN01_plantuml.txt
   ```
6. Click **OK** → el diagrama se genera automáticamente

### Post-importación

- Las lifelines y mensajes quedan correctamente posicionados ✅
- Los bloques `alt` aparecen a la **izquierda** del diagrama
- Arrastrarlos manualmente sobre los mensajes correspondientes
- Los `alt` se pueden mover libremente sin afectar el layout ✅

---

## Convenciones del sistema

### Capas por defecto (sistema Cambur)
```
actor "Psicologo" as PSI
boundary "GUI" as GUI
control "BLL" as BLL
entity "BE" as BE
participant "SERVICIOS" as SVC
database "DAL" as DAL
actor "Banco (Externo al Sistema)" as BANCO
```

### Adaptar a otro sistema
Al inicio del chat indicar las capas:
```
Las capas del sistema son: GUI, Controlador, Servicio, Repositorio, BD
```

---

## Solución de problemas

| Problema | Solución |
|---|---|
| Chrome no se conecta | Verificar que la extensión esté activa y con sesión iniciada |
| Script da error en EA | Verificar que sea EA 15.2 y que el script esté en VB Scripts (no JavaScript) |
| Los `alt` mueven lifelines | Son `InteractionFragment` en paquete separado — arrastrarlos desde el borde |
| Caracteres extraños en EA | El script limpia automáticamente acentos y caracteres especiales |
| `\n` visible en parámetros | El script elimina automáticamente los `\n` de PlantUML |
| `Failed to get EA::IDualApp interface` al ejecutar el script | El registro COM de EA se perdió. Ver sección siguiente. |

---

### Error: `Failed to get EA::IDualApp interface`

**Causa frecuente — formateo del disco principal de Windows**

El registro COM de Windows reside en el disco del sistema (`C:\`). Si EA estaba
instalado en un disco secundario (por ejemplo `F:\`) y el disco principal fue
formateado, EA sigue físicamente intacto pero Windows ya no lo reconoce como
componente COM. El scripting engine de EA (`SScript.dll`) no puede establecer
la interfaz y falla antes de ejecutar cualquier línea del script.

**Solución — re-registrar EA como Administrador**

1. Cerrar EA completamente.
2. Abrir **CMD como Administrador**.
3. Ejecutar:
   ```cmd
   "F:\Sparx System Entreprise 15.2\EA.exe" /regserver
   ```
   *(ajustar la ruta si la instalación está en otra ubicación)*
4. Abrir EA normalmente y volver a ejecutar el script.

**Si el error persiste**, registrar también las DLLs de scripting:

```cmd
regsvr32 "F:\Sparx System Entreprise 15.2\SScript.dll"
regsvr32 "F:\Sparx System Entreprise 15.2\SSImport.dll"
```

**Última opción** — reinstalar EA 15.2 apuntando a la misma carpeta
(`F:\Sparx System Entreprise 15.2`). Los proyectos `.eap` / `.qea` no se
modifican y quedan intactos.