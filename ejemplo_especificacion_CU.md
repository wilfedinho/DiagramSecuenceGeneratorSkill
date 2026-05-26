# Formato de especificación de Caso de Uso

## Campos esperados

```
ID y Nombre: CUN01 Nombre del Caso de Uso
Estado: Pendiente / En desarrollo / Completado
Descripción: Descripción general del caso de uso.
Actor principal: Nombre del actor principal
Actor Secundario: Nombre del actor secundario (si aplica, sino -)
Precondiciones: Condiciones previas (o - si no hay)
Puntos de extensión: (o - si no hay)
Condición: Condición de activación

Escenario principal:
1. El actor realiza X acción.
2. El sistema responde con Y.
3. ...

Flujos alternativos:
  N.M - Nombre del flujo: Descripción. Retorna al paso X.

Postcondiciones: Estado final del sistema tras la ejecución exitosa.
```

## Ejemplo completo

```
ID y Nombre: CUN01 Registrar Profesional
Estado: Pendiente
Descripción: El psicólogo se registrará en el sistema indicando sus datos
             personales y datos bancarios para efectuar el pago de la membresía.
Actor principal: Psicólogo
Actor Secundario: Banco
Precondiciones: -
Puntos de extensión: -
Condición: El psicólogo debe registrarse en el sistema

Escenario principal:
1. El psicólogo selecciona la opción "Registrarse".
2. El sistema muestra el formulario de registro.
3. El psicólogo ingresa sus datos y selecciona "Registrarse".
4. El sistema valida los datos personales.
5. El sistema envía datos bancarios al Banco.
6. El Banco aprueba el pago.
7. El sistema persiste la información.
8. El sistema recalcula el dígito verificador.
9. El sistema muestra confirmación y redirige al login.

Flujos alternativos:
  5.1 - Datos inválidos: El sistema detecta datos incorrectos.
        Muestra mensaje de error. Retorna al paso 3.
  7.1 - Pago rechazado: El banco rechaza la transacción.
        Muestra mensaje de error. Retorna al paso 3.

Postcondiciones: El psicólogo queda registrado con cuenta activa.
```

## Notas para el agente

- Si las capas del sistema no están especificadas, preguntar antes de generar
- El actor secundario externo se nombra como `"[Nombre]\n(Externo al Sistema)"`
- Siempre incluir el flujo de Error Persistencia en DAL
- Siempre incluir RegistrarEventoBitacora al final del flujo exitoso
