module lang::alu::Values

// Dominio de valores del lenguaje ALU
data Val
  = VInt(int n)      // Enteros
  | VFloat(real r)   // Flotantes
  | VBool(bool b)    // Booleanos
  | VChar(str c)     // Caracteres
  | VString(str s)   // Cadenas de texto
  ;

// Ambiente: mapeo de nombres de variables a valores
alias Env = map[str, Val];
