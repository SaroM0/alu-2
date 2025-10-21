module lang::alu::Parser

import IO;
import ParseTree;
import lang::alu::Syntax;

// Parsea código ALU desde un string
public Program parseProgram(str code) = parse(#Program, code);

// Parsea código ALU desde un archivo
public Program parseProgramFile(loc file) = parse(#Program, file);
