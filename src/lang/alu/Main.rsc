module lang::alu::Main

import IO;
import lang::alu::AST;
import lang::alu::Syntax;
import lang::alu::Parser;
import lang::alu::ToAST;
import lang::alu::TypeChecker;
import lang::alu::Values;
import lang::alu::Eval;

import analysis::typepal::TypePal;

// Ejecuta un archivo ALU con el pipeline completo:
// parse → AST → TypePal → ejecución
// Uso: runFile(|file:///ruta/al/archivo.alu|);
public void runFile(loc file) {
  try {
    // 1. Parsear: ParseTree
    Syntax::Program pt = Parser::parseProgramFile(file);
    println("✓ Parsing successful");

    // 2. Transformar: ParseTree → AST
    AST::Program ast = ToAST::toProgram(pt);
    println("✓ AST transformation successful");

    // 3. Análisis de tipos: TypePal
    list[Message] errors = TypeChecker::checkTypes(ast);

    if (size(errors) > 0) {
      println("✗ Type checking failed with <size(errors)> error(s):");
      for (err <- errors) {
        println("  - <err>");
      }
      throw "Type checking failed";
    }

    println("✓ Type checking passed (TypePal)");

    // 4. Ejecutar (solo si no hay errores de tipo)
    <v, env> = Eval::evalProgram(ast);
    println("✓ Execution successful");
    println("Result: <v>");
    println("Env: <env>");

  } catch str msg: {
    println("✗ Error: <msg>");
  }
}

// Función auxiliar para verificar solo tipos sin ejecutar
public void typeCheckFile(loc file) {
  try {
    Syntax::Program pt = Parser::parseProgramFile(file);
    AST::Program ast = ToAST::toProgram(pt);

    list[Message] errors = TypeChecker::checkTypes(ast);

    if (size(errors) > 0) {
      println("✗ Type checking failed with <size(errors)> error(s):");
      for (err <- errors) {
        println("  - <err>");
      }
    } else {
      println("✓ Type checking passed (TypePal)");
    }
  } catch str msg: {
    println("✗ Type error: <msg>");
  }
}
