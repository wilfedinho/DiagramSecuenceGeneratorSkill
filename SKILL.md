---
name: dss-generator
description: >
  Usar esta skill cuando el usuario quiera generar Diagramas de Secuencia del Sistema (DSS)
  a partir de especificaciones de casos de uso, en formato PlantUML, para importar en
  Enterprise Architect 15.2. Triggers: 'generar DSS', 'diagrama de secuencia desde CU',
  'especificacion de caso de uso a PlantUML', 'importar DSS en EA', 'CUN a PlantUML'.
  La skill maneja el flujo completo: captura de arquitectura -> generacion de PlantUML
  -> apertura en plantuml.com via Chrome -> aprobacion del usuario -> guardado de
  archivos .txt -> importacion en EA con el script VBScript incluido.
---

# DSS Generator — Especificaciones CU → PlantUML → Enterprise Architect 15.2

## Resumen del flujo

```
[INICIO DE SESION]
        ↓
  Claude pregunta la arquitectura del sistema
  (capas, seguridad, actores externos)
        ↓
  Usuario confirma la arquitectura
        ↓
  Usuario adjunta especificaciones de CU
  (texto, PDF, Word — uno o varios a la vez)
        ↓
  Por cada CU:
    Claude genera PlantUML
    (estilo generico por capas, usando la arquitectura confirmada)
        ↓
    Abre en plantuml.com via Chrome
    (pestana nueva por cada CU)
        ↓
    Usuario revisa y aprueba ✓
        ↓
    Se guarda DSS_CUNxx_plantuml.txt
        ↓
  Al finalizar todos: presenta los .txt para descarga
        ↓
  Usuario ejecuta Create-Sequence-Diagram.vbs en EA 15.2
```

---

## Dependencias requeridas

| Dependencia | Descripcion | Como obtenerla |
|---|---|---|
| **Claude in Chrome** | Extension del navegador para automatizacion | Instalar desde Chrome Web Store o claude.ai/chrome |
| **Enterprise Architect 15.2** | Herramienta de modelado UML | sparxsystems.com |
| **Create-Sequence-Diagram.vbs** | Script VBScript para importar en EA | Incluido en esta skill |
| **Google Chrome** | Navegador con la extension instalada | chrome.com |

---

## PASO 0 — Capturar arquitectura (OBLIGATORIO, siempre primero)

**Antes de procesar cualquier especificacion**, Claude DEBE capturar y confirmar
la arquitectura del sistema. Se hace UNA SOLA VEZ por sesion y aplica a todos los CUs.

### Si el usuario NO proporcionó las capas, preguntar:

```
Antes de generar los diagramas necesito conocer la arquitectura del sistema.

Por favor indicame:

1. Las capas en orden (de presentacion hacia datos)
   Ejemplo: GUI, BLL, BE, SERVICIOS, DAL

2. Capa de seguridad entre cliente y servidor (si aplica)
   Ejemplo: HTTPS/TLS, ninguna

3. Actores externos al sistema (si aplica)
   Ejemplo: Banco, API de pagos, Servicio de email, ninguno

4. Nombre especifico de la GUI (o dejalo como "GUI")
```

### Si el usuario YA mencionó las capas, confirmar antes de proceder:

```
Detecté la siguiente arquitectura:
  Capas: [lista detectada]
  Seguridad: [protocolo detectado]
  Actores externos: [lista o ninguno]

¿Es correcto? ¿Modificamos algo antes de empezar?
```

**NO generar ningun PlantUML hasta recibir confirmacion de la arquitectura.**

### Guardar en memoria para toda la sesion:

```
ARQUITECTURA CONFIRMADA:
  actor_principal:    [nombre y alias]
  capa_gui:           [nombre]
  capas_intermedias:  [lista en orden: BLL, BE, SERVICIOS, etc.]
  capa_datos:         [nombre: DAL, Repositorio, etc.]
  seguridad:          [HTTPS/TLS u otro o ninguno]
  actores_externos:   [lista con nombres y si son externos al sistema]
```

---

## PASO 1 — Recibir especificaciones de CU

Aceptar en cualquier formato:
- Texto directo en el chat
- Archivo Word (.docx)
- Archivo PDF
- Multiples CUs a la vez

Identificar cada CU por su ID (CUN01, CUN02, etc.) o asignar uno si no tiene.

---

## PASO 2 — Generar PlantUML

Usar la arquitectura confirmada en PASO 0.

### Reglas obligatorias:
- Un solo diagrama integrado con todos los `alt` usando `else` (no diagramas separados por flujo)
- Solo las capas como participantes — sin nombres de clases internas
- Nota de seguridad como `note over` entre actor principal y GUI (si hay capa de seguridad)
- Sin acentos ni caracteres especiales en nombres de metodos ni parametros
- Sin `\n` en parametros — usar coma + espacio normal
- Incluir SIEMPRE `alt [Error Persistencia en Base de Datos]` antes del retorno exitoso del DAL
- Incluir SIEMPRE `RegistrarEventoBitacora` desde BLL hacia SERVICIOS antes del mensaje final

### Template PlantUML

```plantuml
@startuml DSS_[ID]
title sd DSS [ID] - [Nombre del CU]

actor "[Actor Principal]" as [AP]
boundary "[GUI]" as GUI
control "[Capa1]" as C1
entity "[Capa2]" as C2
participant "[Capa3]" as C3
database "[CapaDatos]" as DAT
actor "[Actor Externo]\n(Externo al Sistema)" as [AE]

note over [AP], GUI
  Toda comunicacion entre [Actor] y GUI viaja sobre [Protocolo]
end note

[AP] -> GUI : SeleccionarOpcion()
activate GUI
GUI --> [AP] : MostrarFormulario()

[AP] -> GUI : SubmitDatos(param1, param2, param3)
GUI -> C1 : MetodoPrincipal(param1, param2, param3)
activate C1

C1 -> C2 : ValidarDatos(param1, param2)
activate C2

alt [Condicion alternativa 1]
  C2 --> C1 : RetornarError(TipoError1)
  C1 --> GUI : RetornarError(TipoError1)
  GUI --> [AP] : MostrarMensajeError()

else [Condicion alternativa 2]
  C2 --> C1 : RetornarError(TipoError2)
  C1 --> GUI : RetornarError(TipoError2)
  GUI --> [AP] : MostrarMensajeError()
end

C2 --> C1 : RetornarValidacionExitosa()
deactivate C2

C1 -> C3 : ProcesarOperacion(param1, param2)
activate C3
C3 -> [AE] : EnviarSolicitud(param1, param2)
activate [AE]

alt [Condicion rechazo externo]
  [AE] --> C3 : RetornarRechazo()
  C3 --> C1 : RetornarError(OperacionRechazada)
  C1 --> GUI : RetornarError(OperacionRechazada)
  GUI --> [AP] : MostrarMensajeError(OperacionRechazada)

else [Timeout externo]
  [AE] --> C3 : RetornarTimeout()
  C3 --> C1 : RetornarError(Timeout)
  C1 --> GUI : RetornarError(Timeout)
  GUI --> [AP] : MostrarMensajeError(Timeout)
end

[AE] --> C3 : RetornarAprobacion()
deactivate [AE]
C3 --> C1 : RetornarAprobacion()
deactivate C3

C1 -> C2 : CrearEntidad(param1, param2, param3)
activate C2
C2 --> C1 : RetornarEntidad()
deactivate C2

C1 -> DAT : PersistirEntidad(entidad, extra)
activate DAT
DAT -> DAT : CalcularDigitoVerificador()
DAT --> DAT : RetornarDigitoVerificador()

alt [Error Persistencia en Base de Datos]
  DAT --> C1 : RetornarErrorPersistenciaDeDatos()
  C1 --> GUI : RetornarError(ErrorPersistencia)
  GUI --> [AP] : MostrarMensajeError(Persistencia)
end

DAT --> C1 : RetornarPersistenciaExitosa()
deactivate DAT

C1 -> C3 : RegistrarEventoBitacora(usuario, modulo, autenticacion, descripcion, criticidad, fecha)
activate C3
C3 --> C1 : RegistroOk()
deactivate C3

C1 --> GUI : ResultadoFinal()
deactivate C1
GUI --> [AP] : AccionFinal()
deactivate GUI

@enduml
```

---

## PASO 3 — Abrir en plantuml.com via Chrome

Para cada CU, codificar el PlantUML y abrir en una pestana nueva:

```python
import zlib

def encode_plantuml(code: str) -> str:
    def encode6bit(b):
        if b < 10: return chr(48 + b)
        b -= 10
        if b < 26: return chr(65 + b)
        b -= 26
        if b < 26: return chr(97 + b)
        b -= 26
        if b == 0: return '-'
        if b == 1: return '_'
        return '?'

    def append3bytes(b1, b2, b3):
        c1 = b1 >> 2
        c2 = ((b1 & 0x3) << 4) | (b2 >> 4)
        c3 = ((b2 & 0xF) << 2) | (b3 >> 6)
        c4 = b3 & 0x3F
        return encode6bit(c1)+encode6bit(c2)+encode6bit(c3)+encode6bit(c4)

    data = zlib.compress(code.encode('utf-8'), 9)[2:-4]
    result = ''
    i = 0
    while i < len(data):
        b1 = data[i] if i < len(data) else 0
        b2 = data[i+1] if i+1 < len(data) else 0
        b3 = data[i+2] if i+2 < len(data) else 0
        result += append3bytes(b1, b2, b3)
        i += 3
    return result

url = f"https://www.plantuml.com/plantuml/uml/{encode_plantuml(plantuml_code)}"
```

Usar `Claude in Chrome` para abrir la URL en una pestana nueva del navegador conectado.

---

## PASO 4 — Esperar aprobacion del usuario

Despues de abrir cada pestana, el agente SE DETIENE y muestra:

```
✅ DSS [CU_ID] - [Nombre] abierto en plantuml.com

Revisa el diagrama en el navegador.

Responde:
  • "aprobado"              → guardo el .txt y continuo con el siguiente CU
  • "rechazado"             → describime que cambiar y regenero
  • "modificar: [cambio]"  → aplico el cambio y abro nueva pestana
```

### Ciclo de modificacion:
Si el usuario pide cambios, aplicarlos, generar nuevo PlantUML y volver al PASO 3.
Repetir hasta obtener "aprobado".

---

## PASO 5 — Guardar archivos .txt

Al recibir "aprobado", guardar el PlantUML en:
```
/mnt/user-data/outputs/DSS_CUN01_plantuml.txt
/mnt/user-data/outputs/DSS_CUN02_plantuml.txt
...
```

Al finalizar TODOS los CUs, presentar todos los archivos juntos con `present_files`.

---

## Manejo de multiples CUs

Mantener estado visible durante el proceso:

```
Estado del proceso:
  ✅ CUN01 - Registrar Profesional       → aprobado
  🔄 CUN02 - Iniciar Sesion              → en revision (abierto en Chrome)
  ⏳ CUN03 - Gestionar Consulta          → pendiente
  ⏳ CUN04 - ...                         → pendiente
```

---

## Convenciones de tipos en EA

| Keyword PlantUML | Tipo en EA | Visual en EA |
|---|---|---|
| `actor` (primero en el .txt) | Actor | Figura humana |
| `boundary` | Boundary | Circulo con linea |
| `actor` (siguientes) | Class | Rectangulo con estereotipo |
| `control` | Class | Rectangulo con estereotipo |
| `entity` | Class | Rectangulo con estereotipo |
| `database` | Class | Rectangulo con estereotipo |
| `participant` | Class | Rectangulo con estereotipo |

---

## Consideraciones especiales

### Sin actor externo
Si el CU no tiene actor externo, omitir esa lifeline y el bloque `alt` de rechazo externo.

### Sin capa de seguridad
Si el usuario indica que no hay HTTPS/TLS u otra capa de seguridad,
omitir el `note over` del protocolo.

### Casos simples sin flujos alternativos
Si el CU no tiene flujos alternativos, generar sin bloques `alt`
(excepto el de Error Persistencia que va siempre).

### Casos con muchos flujos alternativos
Si hay mas de 6 flujos alternativos, agrupar los relacionados
en el mismo bloque `alt/else` para mantener el diagrama legible.

### Nombres de metodos
- Sin acentos ni caracteres especiales (el script de EA los limpia pero mejor evitarlos)
- Sin `\n` en parametros
- Usar CamelCase
- Los parametros van separados por `, ` (coma + espacio)

---

## Script VBScript — instalacion en EA 15.2

### Instalacion (una sola vez)
1. Abrir EA 15.2
2. **Specialize** → **Scripting**
3. Click derecho en **VB Scripts** → **Add Group** → nombre: `PlantUML`
4. Click derecho en el grupo → **Add Script** → nombre: `Create-Sequence-Diagram`
5. Pegar el contenido de `Create-Sequence-Diagram.vbs` → **Save**

### Uso por cada CU
1. Seleccionar paquete destino en el Project Browser
2. Ejecutar el script → InputBox pide la ruta del `.txt`
3. Ingresar: `C:\Users\[Usuario]\Downloads\DSS_CUN01_plantuml.txt`
4. Click **OK** → diagrama generado automaticamente

### Resultado esperado
- Lifelines posicionadas de izquierda a derecha ✅
- Mensajes en orden correcto con `SequenceNo` ✅
- Nota de protocolo de seguridad ✅
- Bloques `alt` a la izquierda — moverlos manualmente sobre los mensajes ✅
