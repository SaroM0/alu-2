# Proyecto ALU - Lenguaje de Programación en Rascal

## Descripción

se incluye:
- Variables y asignaciones
- Operadores aritméticos, lógicos y de comparación
- Estructuras de control (if-then-else, for loops)
- Funciones
- Sistema de tipos (Int, Float, Bool, Char, String)

---

## Requisitos

### Software Necesario

1. **Java JDK 11+**

2. **Maven** (para gestionar dependencias)

3. **Rascal MPL 0.40.17**

### Instalar Dependencias

```bash
mvn dependency:resolve
```

---


##  Ejemplos y Salidas Esperadas

### 1. `simple.alu` - Asignación Básica
```alu
function () do
begin
set x := 1
end
test
```
**Salida**: `Result: VInt(1)`, `Env: ("x":VInt(1))`

---

### 2. `demo.alu` - Aritmética y Condicionales
```alu
function () do
begin
set x := 1 + 2
if x .gt. 2 then
begin
set x := x ** 2
end
else
begin
set x := x - 1
end
end
end
main
```
**Salida**: `Result: VFloat(9.0)`, `Env: ("x":VFloat(9.0))`  
**Explicación**: x = 3, como 3 > 2, entonces x = 3² = 9.0 ✅

---

### 3. `loops.alu` - Loop For
```alu
function () do
begin
set s := 0
for i from 1 to 3 do
begin
set s := s + i
end
end
end
sumUp
```
**Salida**: `Result: VInt(0)`, `Env: ("s":VInt(6),"i":VInt(3))`  
**Explicación**: s = 0 + 1 + 2 + 3 = 6 ✅

---

### 4. `test_if.alu` - Condicional
```alu
function () do
begin
if 1 .lt. 2 then
begin
set x := 1
end
else
begin
set x := 2
end
end
end
test
```
**Salida**: `Result: VInt(1)`, `Env: ("x":VInt(1))`  
**Explicación**: Como 1 < 2 es verdadero, ejecuta then y asigna x = 1 ✅

---

### 5. `test_simple2.alu` - Múltiples Variables
```alu
function () do
begin
set x := 1
set y := 2
end
test
```
**Salida**: `Result: VInt(2)`, `Env: ("x":VInt(1),"y":VInt(2))` ✅

---

## 🧪 Suite de Pruebas

### Tests de Regresión

Verificar que estos tres casos críticos funcionen:

```rascal
import lang::alu::Main;

// Test 1: demo.alu - x debe terminar en 9
runFile(|file:///home/saro/university/lym/proyecto2/alu/examples/demo.alu|);
// Verificar: Env contiene ("x":VFloat(9.0))

// Test 2: loops.alu - s debe terminar en 6
runFile(|file:///home/saro/university/lym/proyecto2/alu/examples/loops.alu|);
// Verificar: Env contiene ("s":VInt(6))

// Test 3: test_if.alu - x debe terminar en 1
runFile(|file:///home/saro/university/lym/proyecto2/alu/examples/test_if.alu|);
// Verificar: Env contiene ("x":VInt(1))
```

---

## Estructura del Proyecto

```
/home/saro/university/lym/proyecto2/alu/
│
├── src/lang/alu/
│   ├── Syntax.rsc        # Gramática del lenguaje ALU
│   ├── Parser.rsc        # Parser (string/archivo → AST)
│   ├── Eval.rsc          # Evaluador/Intérprete
│   ├── Values.rsc        # Sistema de tipos (Val, Env)
│   └── Main.rsc          # Punto de entrada (runFile)
│
├── examples/
│   ├── simple.alu        # Asignación básica
│   ├── demo.alu          # Aritmética + if + potencia
│   ├── loops.alu         # Loop for con acumulación
│   ├── test_if.alu       # Condicional if-then-else
│   └── test_simple2.alu  # Múltiples variables
│
├── META-INF/
│   └── RASCAL.MF         # Manifiesto del proyecto
│
├── pom.xml               # Configuración Maven
└── README.md             # Este archivo
```

---

## Características del Lenguaje

### Palabras Reservadas
```
and, begin, call, cond, data, do, else, end, for, from,
function, if, in, iterator, mod, neg, or, sequence, set,
struct, then, to, tuple, type, with, yielding
```

### Operadores

| Tipo | Operadores | Ejemplo |
|------|------------|---------|
| Aritméticos | `+`, `-`, `*`, `/`, `mod`, `**`, `neg` | `x + 2`, `x ** 2` |
| Comparación | `==`, `!=`, `.lt.`, `.gt.`, `.le.`, `.ge.` | `x .gt. 5` |
| Lógicos | `and`, `or` | `x .gt. 0 and x .lt. 10` |

### Sintaxis Básica

**Asignación**:
```alu
set x := 10
set y := x + 5
```

**Condicional**:
```alu
if condición then
begin
  // código
end
else
begin
  // código
end
end
```

**Loop**:
```alu
for i from 1 to 10 do
begin
  // código
end
end
```

**Función**:
```alu
function () do
begin
  // código
end
end
nombreFuncion
```

### Tipos de Datos

- `VInt(n)` - Enteros: `42`, `-10`
- `VFloat(r)` - Flotantes: `3.14`, resultado de `/` y `**`
- `VBool(b)` - Booleanos: `true`, `false`
- `VChar(c)` - Caracteres: `'a'`, `'Z'`
- `VString(s)` - Cadenas: `"hello"`

---