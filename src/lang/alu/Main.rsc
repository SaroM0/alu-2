module lang::alu::Main

import IO;
import lang::alu::Syntax;
import lang::alu::Parser;
import lang::alu::Eval;
import lang::alu::Values;

// Ejecuta un archivo ALU y muestra el resultado y el ambiente final
// Uso: runFile(|file:///ruta/al/archivo.alu|);
public void runFile(loc file) {
  Program p = parseProgramFile(file);
  <v, env> = evalProgram(p);
  println("Result: <v>");
  println("Env: <env>");
}
