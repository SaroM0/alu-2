module lang::alu::Syntax

// Layout personalizado: espacios, tabs, saltos de línea y comentarios de línea
layout L = WS;
lexical WS = [\ \t\n\r] | "//" ![\n]* $;

// Palabras reservadas (deben ir antes de Id para evitar conflictos)
keyword Keywords = "cond" | "do" | "data" | "end" | "for" | "from" | "then" 
                 | "function" | "else" | "if" | "in" | "iterator" | "sequence" 
                 | "struct" | "to" | "tuple" | "type" | "with" | "yielding"
                 | "and" | "or" | "neg" | "mod" | "set" | "call" | "begin";

// Terminales léxicos básicos
lexical Id = ([a-z][A-Za-z0-9_]* !>> [A-Za-z0-9_]) \ Keywords;
lexical INT    = [0-9]+;
lexical FLOAT  = [0-9]+ "." [0-9]+;
lexical CHAR   = "\'" ![\'\n\r] "\'";
lexical STRING = "\"" ![\"\n\r]* "\"";

// Símbolo inicial del programa
start syntax Program = program: Module* modules;

// Módulos del lenguaje
syntax Module
  = moduleVars: Variables
  | moduleFun:  Function
  | moduleData: Data
  ;

// Lista de variables (declaraciones o parámetros)
syntax Variables = vars: {Id ","}+;

// Declaración de función
syntax Function 
  = funcNoParams: "function" "()" "do" Body Id
  | func: "function" "(" Variables ")" "do" Body Id
  | funcAssignNoParams: Id ":=" "function" "()" "do" Body Id
  | funcAssign: Id ":=" "function" "(" Variables ")" "do" Body Id
  ;

// Declaración de tipo de dato
syntax Data 
  = dataDecl: "data" "with" Variables DataBody "end" Id
  | dataAssign: Id ":=" "data" "with" Variables DataBody "end" Id
  ;

// Asignación de variable
syntax Assignment = "set" Id ":=" Expression;

// Cuerpo de código (secuencia de statements)
syntax Body = "begin" Statement+ "end";

// Tipos de statements
syntax Statement
  = sLoop:   Loop
  | sIf:     "if" Expression "then" Body "else" Body "end"
  | sCond:   "cond" Expression "do" PatternBody "end"
  | sAssign: Assignment
  | sInvoke: Invocation
  ;

// Rango numérico para bucles
syntax Range = "from" Principal "to" Principal;

// Asignación en iteradores
syntax IterAssign = iterAssign: Id ":=" Expression;

// Estructura de iterador
syntax Iterator =
  IterAssign "iterator" "(" Variables ")" "yielding" "(" Variables ")";

// Bucle for
syntax Loop = "for" Id Range "do" Body "end";

// Alternativas para el cuerpo de datos
syntax DataBody = dbCons: Constructor | dbFunc: Function;

// Forma de constructor
syntax Constructor = cons: Id ":=" "struct" "(" Variables ")";

// Cuerpo de pattern matching
syntax PatternBody = Expression+;

// Formas de invocación de funciones
syntax Invocation
  = inv1: Id "$" "(" Variables? ")"
  | inv2: Id "." Id "(" Variables? ")"
  ;

// Expresiones con prioridad de operadores
syntax Expression
  = Principal
  | bracket "(" Expression ")"
  > uminus: "neg" Expression
  > right pow: Expression "**" Expression
  > left mul: Expression "*" Expression
  | div: Expression "/" Expression
  | modu: Expression "mod" Expression
  > left add: Expression "+" Expression
  | sub: Expression "-" Expression
  > non-assoc eq: Expression "==" Expression
  | ne: Expression "!=" Expression
  | lt: Expression ".lt." Expression
  | gt: Expression ".gt." Expression
  | le: Expression ".le." Expression
  | ge: Expression ".ge." Expression
  > left andb: Expression "and" Expression
  > left orb: Expression "or" Expression
  > right arrow: Expression "=\>" Expression
  > right pair: Expression "::" Expression
  ;

// Valores primitivos: literales e identificadores
syntax Principal
  = "true"
  | "false"
  | CHAR
  | STRING
  | INT
  | FLOAT
  | Id
  ;
