# ALU Language - Type System Implementation

A statically-typed imperative programming language implemented in Rascal with TypePal framework for type checking. This project implements Project 3, extending the ALU language with type annotations and a comprehensive type system.

## Overview

ALU is a simple imperative language focused on arithmetic and logical expressions, control structures, and basic data structures. The language provides:

- **Arithmetic expressions**: addition (`+`), subtraction (`-`), multiplication (`*`), division (`/`), modulo (`mod`), power (`**`), and arithmetic negation (`neg`)
- **Boolean expressions**: comparisons (`==`, `!=`, `.lt.`, `.gt.`, `.le.`, `.ge.`) and logical operators (`and`/`&&`, `or`/`||`)
- **Control structures**: conditionals (`if`-`then`-`else`-`end`) and `while` loops (`while`-`do`-`end`)
- **Data structures**: lists (`[...]`), sets (`{...}`), and maps (`{k:v, ...}`)
- **Functions**: function definitions with optional parameters and code bodies

In Iteration 3, the language is extended with **type annotations** on values and data structures, allowing the type system to verify program correctness before execution.

## Project Structure

```
alu/
├── src/lang/alu/
│   ├── AST.rsc            # Abstract Syntax Tree definitions
│   ├── Syntax.rsc         # Concrete syntax grammar
│   ├── Parser.rsc         # Parser implementation
│   ├── ToAST.rsc          # Parse tree to AST transformation
│   ├── TypeChecker.rsc    # TypePal-based type checker
│   ├── Eval.rsc           # Interpreter/evaluator
│   ├── Values.rsc         # Runtime value domain
│   ├── Main.rsc           # Main entry point
│   ├── Tests.rsc          # Test runner
│   └── Editor.rsc         # Syntax highlighting configuration
├── tests/
│   ├── valid/             # Valid test programs
│   └── invalid/           # Invalid test programs (should fail)
├── pom.xml                # Maven configuration with TypePal
└── README.md              # This file
```

## Key Features

### Iteration 2 Adjustments

The project includes corrections from Iteration 2:

- **Explicit syntax highlighting**: Added `Editor.rsc` module defining keywords, type keywords, and operators for syntax highlighting in Rascal editors
- **Explicit AST**: Introduced a separate AST (`AST.rsc`) distinct from the parse tree, with transformation module (`ToAST.rsc`) for converting parse trees to AST

### Type System

The type system implemented in Iteration 3 includes:

- **Base types**: `int`, `bool`, `char`, `string`
- **Collection types**: `list`, `set`, `map` (element types inferred from context)
- **Type annotations**: All variables must be declared with explicit types
- **Type checking**: Static type checking using TypePal framework
- **Existence verification**: All identifiers used in data structures must be declared before use

## Requirements

- **Java**: JDK 11 or higher
- **Maven**: 3.6 or higher
- **Rascal**: 0.40.17 (managed by Maven)
- **TypePal**: 0.11.1 (managed by Maven)

## Building the Project

### 1. Download Dependencies

```bash
mvn dependency:resolve
```

This downloads Rascal MPL 0.40.17, TypePal 0.11.1, and all transitive dependencies.

### 2. Compile

```bash
mvn clean compile
```

## Running Programs

### Using Rascal REPL

```bash
# Start Rascal REPL
java -Xmx1G -Xss32m -jar ~/.m2/repository/org/rascalmpl/rascal/0.40.17/rascal-0.40.17.jar

# In the REPL:
rascal> import lang::alu::Main;
rascal> runFile(|file:///path/to/alu/tests/valid/simple_typed.alu|);
```

### Using Eclipse with Rascal Plugin

1. Install Rascal Eclipse Plugin
2. Import project as Maven project
3. Open Rascal console
4. Import modules and run tests

### Using VSCode with Rascal Extension

1. Install Rascal LSP extension
2. Open project folder
3. Open Rascal terminal
4. Import and run

## Example Programs

### Valid Program

**tests/valid/simple_typed.alu**:
```
function () do
begin
    int x = 5;
    bool flag = true;
    string name = "Alice";
end
test
```

**tests/valid/list_typed.alu**:
```
function () do
begin
    int a = 1;
    int b = 2;
    int c = 3;
    list nums = [a, b, c];
end
test
```

### Invalid Program

**tests/invalid/type_mismatch.alu** (should fail):
```
function () do
begin
    int x = true;  // ERROR: type mismatch
end
test
```

**tests/invalid/undeclared_in_list.alu** (should fail):
```
function () do
begin
    int a = 1;
    list nums = [a, c];  // ERROR: 'c' is not declared
end
test
```

## Type System Rules

### Primitive Types

| Type | Description | Example |
|------|-------------|---------|
| `int` | Integer numbers | `int x = 42;` |
| `bool` | Boolean values | `bool flag = true;` |
| `char` | Single character | `char c = 'a';` |
| `string` | String literals | `string s = "hello";` |

### Collection Types

| Type | Description | Example |
|------|-------------|---------|
| `list` | Homogeneous list | `list nums = [1, 2, 3];` |
| `set` | Homogeneous set | `set names = {"Ana", "Luis"};` |
| `map` | Key-value map | `map dict = {1:"one", 2:"two"};` |

### Type Rules

1. **Arithmetic Operations** (`+`, `-`, `*`, `/`, `mod`, `neg`, `**`)
   - Operands: `int`
   - Result: `int`

2. **Logical Operations** (`and`, `or`)
   - Operands: `bool`
   - Result: `bool`

3. **Numeric Comparison Operations** (`.lt.`, `.gt.`, `.le.`, `.ge.`)
   - Operands: `int`
   - Result: `bool`

4. **Equality Operations** (`==`, `!=`)
   - Operands: same type (any type)
   - Result: `bool`

5. **Control Flow**
   - If/while conditions: must be `bool`

6. **Collections**
   - All elements must have the same type
   - Element type inferred from first element or declared type
   - Empty collections cannot infer type

7. **Assignments**
   - Expression type must match declared variable type

8. **Existence Rule**
   - All identifiers used in data structures must be declared before use

## Testing

### Running All Tests

```rascal
import lang::alu::Tests;

runAllTests();
```

### Running Valid Tests Only

```rascal
import lang::alu::Tests;

runValidTests();
```

### Running Invalid Tests Only

```rascal
import lang::alu::Tests;

runInvalidTests();
```

### Running a Single Test

```rascal
import lang::alu::Main;

// Full pipeline: parse, type check, execute
runFile(|file:///path/to/test.alu|);

// Type check only
typeCheckFile(|file:///path/to/test.alu|);
```

## TypePal Integration

TypePal is Rascal's framework for type checking and name resolution. The implementation uses TypePal to:

1. **Collect Phase**: Traverse AST and collect variable definitions, variable uses, and type constraints
2. **Solve Phase**: TypePal resolves name bindings, type constraints, and type inference
3. **Result**: Type-safe program or list of errors

### Key TypePal Functions Used

- `c.define(name, id, node, props)` - Define a variable with its type
- `c.use(name, ids)` - Use a variable (checks existence)
- `c.fact(node, type)` - Assert a known type
- `c.requireEqual(t1, t2, msg)` - Require type equality
- `c.calculate(name, node, deps, calc)` - Calculate type from dependencies

## Execution Pipeline

The complete execution pipeline for an ALU program:

1. **Parsing**: Read `.alu` file using `Parser::parseProgramFile()`, obtaining parse tree (`Syntax::Program`)
2. **AST Transformation**: Transform parse tree to AST using `ToAST::toProgram()`, generating `AST::Program`
3. **Type Checking**: Apply TypePal specification using `TypeChecker::checkTypes()`, which internally calls `aluTypePalChecker()` and returns error messages
4. **Execution Decision**:
   - If no type errors: execute program on AST using `Eval::evalProgram()`
   - If type errors detected: display error messages and do not execute

This integration ensures errors are detected in a static phase before execution, avoiding unexpected runtime behaviors.

## Troubleshooting

### Issue: "Cannot find TypePal"
**Solution**: Run `mvn dependency:resolve` to download TypePal

### Issue: "Module not found"
**Solution**: Ensure you're in the correct directory and classpath includes target/classes

### Issue: "Parse error"
**Solution**: Check that your `.alu` file follows the grammar in `Syntax.rsc`

### Issue: "Type error not detected"
**Solution**: Verify `TypeChecker.rsc` is being used correctly

## References

- [Rascal Documentation](https://www.rascal-mpl.org/)
- [TypePal Documentation](https://www.rascal-mpl.org/docs/Library/analysis/typepal/)
- [Rascal Tutor](https://tutor.rascal-mpl.org/)
