module lang::alu::Editor

import lang::alu::Syntax;
import lang::alu::Parser;
import IO;

// Configuración del editor para syntax highlighting
public void initEditor() {
  // Este módulo configura el syntax highlighting para ALU
  // Las palabras clave, tipos y literales se reconocen automáticamente
  // a través de la gramática definida en Syntax.rsc
}

// Palabras clave del lenguaje para resaltado
public set[str] keywords = {
  "if", "else", "then", "end", "begin", "while", "for", "from", "to", "do",
  "function", "set", "and", "or", "neg", "mod", "cond", "data", "with",
  "struct", "iterator", "yielding", "in", "sequence", "tuple", "type", "call"
};

// Tipos del lenguaje para resaltado
public set[str] typeKeywords = {
  "int", "bool", "char", "string", "list", "set", "map"
};

// Operadores para resaltado
public set[str] operators = {
  "+", "-", "*", "/", "mod", "**", "==", "!=", 
  ".lt.", ".gt.", ".le.", ".ge.", "<", ">", "<=", ">=",
  "&&", "||", "and", "or", "neg", "::", "=>"
};

// Configuración de colores (conceptual, Rascal maneja esto internamente)
// Las siguientes categorías se reconocen automáticamente:
// - Keywords: palabras reservadas definidas en Syntax.rsc
// - Types: tipos base y genéricos (int, bool, char, string, list, set, map)
// - Literals: números, strings, chars, booleanos
// - Identifiers: variables y funciones
// - Operators: operadores aritméticos, lógicos y relacionales
// - Comments: comentarios de línea (//)

