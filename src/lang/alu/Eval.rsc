module lang::alu::Eval

import IO;
import ParseTree;
import String;
import List;
import lang::alu::Syntax;
import lang::alu::Values;

// Evalúa un programa completo, procesando cada módulo secuencialmente
public tuple[Val v, Env env] evalProgram(Program p) {
  Env env = ();
  Val last = VInt(0);
  for (m <- p.modules) {
    <last, env> = evalModule(m, env);
  }
  return <last, env>;
}

// Evalúa un módulo (por ahora solo manejamos funciones)
public tuple[Val v, Env env] evalModule(Module m, Env env) {
  switch (m) {
    case moduleFun(f): return evalFunction(f, env);
    default: return <VInt(0), env>;
  }
}

// Extrae y evalúa el cuerpo de una función
public tuple[Val v, Env env] evalFunction(Function f, Env env) {
  for (/Body b := f) {
    return evalBody(b, env);
  }
  return <VInt(0), env>;
}

// Evalúa un bloque de código (begin...end)
// Extrae los statements directos del cuerpo sin incluir los anidados
public tuple[Val v, Env env] evalBody(Body b, Env env) {
  Val last = VInt(0);
          
  // Accede a los argumentos del nodo del parse tree
  if (appl(_, args) := b) {
    // Los args contienen: begin, layout, lista_statements, layout, end
    // Buscamos el nodo que contiene Statement+
    for (arg <- args) {
      // Intentamos identificar si es una lista de statements
      if (appl(regular(\iter-star-seps(sort("Statement"), _)), stmtArgs) := arg ||
          appl(regular(\iter-seps(sort("Statement"), _)), stmtArgs) := arg) {
        // Procesamos cada statement de la lista
        for (stmtArg <- stmtArgs) {
          if (Statement s := stmtArg) {
            <last, env> = evalStmt(s, env);
          }
        }
      }
    }
  }
  
  return <last, env>;
}

// Evalúa un statement individual (asignación, loop, condicional)
public tuple[Val v, Env env] evalStmt(Statement s, Env env) {
  switch (s) {
    case sAssign(a): {
      // Asignación: set x := expr
      list[Id] ids = [id | /Id id := a];
      list[Expression] exprs = [e | /Expression e := a];
      if (size(ids) >= 1 && size(exprs) >= 1) {
        str varName = "<ids[0]>";
        Val v = evalExp(exprs[0], env);
        return <v, env + (varName : v)>;
      }
    }
    
    case sLoop(l): {
      // Bucle: for i from n to m do ... end
      list[Id] ids = [id | /Id id := l];
      list[Principal] prs = [pr | /Principal pr := l];
      list[Body] bodies = [bd | /Body bd := l];
      if (size(ids) >= 1 && size(prs) >= 2 && size(bodies) >= 1) {
        int from = toIntVal(evalPrincipal(prs[0], env));
        int to = toIntVal(evalPrincipal(prs[1], env));
        str varName = "<ids[0]>";
        Env cur = env;
        // Rango inclusivo: [from, to]
        for (i <- [from..to+1]) {
          cur = cur + (varName : VInt(i));
          <_, cur> = evalBody(bodies[0], cur);
        }
        return <VInt(0), cur>;
      }
    }
    
    case sIf(_, _, _): {
      // Condicional: if cond then ... else ... end
      list[Expression] exprs = [e | /Expression e := s];
      list[Body] bodies = [bd | /Body bd := s];
      if (size(exprs) >= 1 && size(bodies) >= 2) {
        Val cond = evalExp(exprs[0], env);
        return (cond is VBool && cond.b) ? evalBody(bodies[0], env) : evalBody(bodies[1], env);
      }
    }
  }
  return <VInt(0), env>;
}

// Evalúa una expresión y devuelve su valor
public Val evalExp(Expression e, Env env) {
  str eStr = "<e>";
  list[Expression] subs = [ex | /Expression ex := e, ex != e];
  list[Principal] prs = [p | /Principal p := e];
  
  // Caso base: solo un valor o identificador
  if (size(subs) == 0 && size(prs) >= 1) {
    return evalPrincipal(prs[0], env);
  }
  
  // Expresión entre paréntesis
  if (startsWith(trim(eStr), "(") && endsWith(trim(eStr), ")") && size(subs) >= 1) {
    return evalExp(subs[0], env);
  }
  
  // Operador unario negación
  if (startsWith(trim(eStr), "neg ") && size(subs) >= 1) {
    Val v = evalExp(subs[0], env);
    if (v is VInt) return VInt(-v.n);
    if (v is VFloat) return VFloat(-v.r);
    throw "Type error: unary neg";
  }
  
  // Operadores binarios
  if (size(subs) >= 2) {
    Expression l = subs[0];
    Expression r = subs[1];
    
    // Potencia: base ** exponente
    if (contains(eStr, "**")) {
      Val a = evalExp(l, env); Val b = evalExp(r, env);
      if (b is VInt && b.n >= 0) {
        real base = toRealVal(a);
        int n = b.n;
        real acc = 1.0;
        // Multiplicar n veces: 3^2 = 3*3 (2 multiplicaciones)
        for (k <- [1..n+1]) { 
          acc = acc * base; 
        }
        return VFloat(acc);
      }
      throw "Type error: ** expects non-negative integer exponent";
    }
    
    // Multiplicación
    if (contains(eStr, " * ") && !contains(eStr, "**")) {
      Val a = evalExp(l, env); Val b = evalExp(r, env);
      if (a is VInt && b is VInt) return VInt(a.n * b.n);
      return VFloat(toRealVal(a) * toRealVal(b));
    }
    
    // División (siempre devuelve float)
    if (contains(eStr, " / ")) {
      return VFloat(toRealVal(evalExp(l, env)) / toRealVal(evalExp(r, env)));
    }
    
    // Módulo (solo para enteros)
    if (contains(eStr, " mod ")) {
      Val a = evalExp(l, env); Val b = evalExp(r, env);
      if (a is VInt && b is VInt) return VInt(a.n % b.n);
      throw "Type error: mod";
    }
    
    // Suma
    if (contains(eStr, " + ")) {
      Val a = evalExp(l, env); Val b = evalExp(r, env);
      if (a is VInt && b is VInt) return VInt(a.n + b.n);
      return VFloat(toRealVal(a) + toRealVal(b));
    }
    
    // Resta
    if (contains(eStr, " - ") && !startsWith(trim(eStr), "neg")) {
      Val a = evalExp(l, env); Val b = evalExp(r, env);
      if (a is VInt && b is VInt) return VInt(a.n - b.n);
      return VFloat(toRealVal(a) - toRealVal(b));
    }
    
    // Operadores de comparación
    if (contains(eStr, " == "))
      return VBool(toRealVal(evalExp(l, env)) == toRealVal(evalExp(r, env)));
    if (contains(eStr, " != "))
      return VBool(toRealVal(evalExp(l, env)) != toRealVal(evalExp(r, env)));
    if (contains(eStr, " .lt. "))
      return VBool(toRealVal(evalExp(l, env)) < toRealVal(evalExp(r, env)));
    if (contains(eStr, " .gt. "))
      return VBool(toRealVal(evalExp(l, env)) > toRealVal(evalExp(r, env)));
    if (contains(eStr, " .le. "))
      return VBool(toRealVal(evalExp(l, env)) <= toRealVal(evalExp(r, env)));
    if (contains(eStr, " .ge. "))
      return VBool(toRealVal(evalExp(l, env)) >= toRealVal(evalExp(r, env)));
    
    // Operadores lógicos
    if (contains(eStr, " and ")) {
      Val a = evalExp(l, env); Val b = evalExp(r, env);
      if (a is VBool && b is VBool) return VBool(a.b && b.b);
      throw "Type error: and";
    }
    
    if (contains(eStr, " or ")) {
      Val a = evalExp(l, env); Val b = evalExp(r, env);
      if (a is VBool && b is VBool) return VBool(a.b || b.b);
      throw "Type error: or";
    }
  }
  
  return VInt(0);
}

// Evalúa un valor primitivo o identificador
public Val evalPrincipal(Principal p, Env env) {
  str pStr = "<p>";
  
  // Booleanos
  if (pStr == "true") return VBool(true);
  if (pStr == "false") return VBool(false);
  
  // Extrae los diferentes tipos de literales
  list[INT] ints = [n | /INT n := p];
  list[FLOAT] floats = [x | /FLOAT x := p];
  list[CHAR] chars = [c | /CHAR c := p];
  list[STRING] strings = [s | /STRING s := p];
  list[Id] ids = [name | /Id name := p];
  
  // Convierte el lexema a su valor correspondiente
  if (size(ints) >= 1) return VInt(toInt("<ints[0]>"));
  if (size(floats) >= 1) return VFloat(toReal("<floats[0]>"));
  if (size(chars) >= 1) return VChar("<chars[0]>");
  if (size(strings) >= 1) return VString("<strings[0]>");
  if (size(ids) >= 1) return env["<ids[0]>"]?VInt(0);
  
  return VInt(0);
}

// Convierte un valor a real para operaciones aritméticas
real toRealVal(Val v) {
  if (v is VInt) return v.n * 1.0;
  if (v is VFloat) return v.r;
  throw "Type error: expected numeric";
}

// Convierte un valor a entero (para límites de bucles)
int toIntVal(Val v) {
  if (v is VInt) return v.n;
  if (v is VFloat) return toInt(v.r);
  throw "Type error: expected integer";
}
