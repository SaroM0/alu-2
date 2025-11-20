module lang::alu::Eval

import IO;
import lang::alu::AST;
import lang::alu::Values;

// Alias locales para simplificar
alias Val = Values::Val;
// Env ya está definido en Values, no necesitamos redefinirlo
alias Program = AST::Program;
alias Decl = AST::Decl;
alias Stmt = AST::Stmt;
alias Expr = AST::Expr;
alias Type = AST::Type;

// Evalúa un programa completo sobre el AST
public tuple[Val v, Values::Env env] evalProgram(Program p) {
  Values::Env env = ();
  Val last = Values::VInt(0);
  
  // Primero procesar todas las declaraciones
  for (decl <- p.decls) {
    <last, env> = evalDecl(decl, env);
  }
  
  // Luego ejecutar todas las sentencias
  for (stmt <- p.stmts) {
    <last, env> = evalStmt(stmt, env);
  }
  
  return <last, env>;
}

// Evalúa una declaración
public tuple[Val v, Values::Env env] evalDecl(Decl d, Values::Env env) {
  switch (d) {
    case TypedDecl(Type t, str name, Expr init): {
      Val v = evalExpr(init, env);
      return <v, env + (name : v)>;
    }
    case TypedDeclNoInit(Type t, str name): {
      // Inicializar con valor por defecto según el tipo
      Val defaultValue = defaultValueForType(t);
      return <defaultValue, env + (name : defaultValue)>;
    }
    case TypedListDecl(Type t, str name, list[Expr] elems): {
      list[Val] vals = [evalExpr(e, env) | e <- elems];
      // Por simplicidad, almacenamos como Values::VInt(0) y mantenemos la lista en el entorno
      // En una implementación más completa, se podría extender Val para incluir listas
      return <Values::VInt(0), env + (name : Values::VInt(0))>;
    }
    case TypedSetDecl(Type t, str name, set[Expr] setElems): {
      set[Val] vals = {evalExpr(e, env) | e <- setElems};
      return <Values::VInt(0), env + (name : Values::VInt(0))>;
    }
    case TypedMapDecl(Type t, str name, list[tuple[Expr, Expr]] pairs): {
      for (<Expr k, Expr v> <- pairs) {
        evalExpr(k, env);
        evalExpr(v, env);
      }
      return <Values::VInt(0), env + (name : Values::VInt(0))>;
    }
  }
  return <Values::VInt(0), env>;
}

// Valor por defecto según el tipo
Val defaultValueForType(Type t) {
  switch (t) {
    case TInt(): return Values::VInt(0);
    case TBool(): return Values::VBool(false);
    case TChar(): return Values::VChar("");
    case TString(): return Values::VString("");
    case TList(_): return Values::VInt(0);
    case TSet(_): return Values::VInt(0);
    case TMap(_, _): return Values::VInt(0);
  }
  return Values::VInt(0);
}

// Evalúa una sentencia
public tuple[Val v, Values::Env env] evalStmt(Stmt s, Values::Env env) {
  switch (s) {
    case Assign(str name, Expr e): {
      Val v = evalExpr(e, env);
      if (name in env) {
        return <v, env + (name : v)>;
      }
      throw "Variable \"" + name + "\" not declared";
    }
    case If(Expr cond, list[Stmt] thenBranch, list[Stmt] elseBranch): {
      Val condVal = evalExpr(cond, env);
      switch (condVal) {
        case Values::VBool(bool b): {
          if (b) {
            return evalBlock(thenBranch, env);
          } else {
            return evalBlock(elseBranch, env);
          }
        }
        default: throw "Type error: if condition must be bool";
      }
    }
    case While(Expr cond, list[Stmt] body): {
      Values::Env curEnv = env;
      bool continueLoop = true;
      while (continueLoop) {
        Val condVal = evalExpr(cond, curEnv);
        switch (condVal) {
          case Values::VBool(bool b): {
            if (b) {
              <_, curEnv> = evalBlock(body, curEnv);
            } else {
              continueLoop = false;
            }
          }
          default: continueLoop = false;
        }
      }
      return <Values::VInt(0), curEnv>;
    }
    case Block(list[Stmt] stmts): {
      return evalBlock(stmts, env);
    }
  }
  return <Values::VInt(0), env>;
}

// Evalúa un bloque de sentencias
tuple[Val v, Values::Env env] evalBlock(list[Stmt] stmts, Values::Env env) {
  Val last = Values::VInt(0);
  Values::Env curEnv = env;
  for (stmt <- stmts) {
    <last, curEnv> = evalStmt(stmt, curEnv);
  }
  return <last, curEnv>;
}

// Evalúa una expresión
public Val evalExpr(Expr e, Values::Env env) {
  switch (e) {
    // Literales
    case intConst(int n): return Values::VInt(n);
    case floatConst(real r): return Values::VFloat(r);
    case boolConst(bool b): return Values::VBool(b);
    case charConst(str c): return Values::VChar(c);
    case stringConst(str s): return Values::VString(s);
    
    // Variables
    case var(str name): {
      if (name in env) {
        return env[name];
      }
      throw "Variable \"" + name + "\" not found";
    }
    
    // Operaciones aritméticas
    case add(Expr l, Expr r): {
      Val lv = evalExpr(l, env);
      Val rv = evalExpr(r, env);
      switch (<lv, rv>) {
        case <Values::VInt(int ln), Values::VInt(int rn)>: return Values::VInt(ln + rn);
        default: {
          switch (<lv, rv>) {
            case <Values::VFloat(_), _>: return Values::VFloat(toRealVal(lv) + toRealVal(rv));
            case <_, Values::VFloat(_)>: return Values::VFloat(toRealVal(lv) + toRealVal(rv));
            default: throw "Type error in addition";
          }
        }
      }
    }
    case sub(Expr l, Expr r): {
      Val lv = evalExpr(l, env);
      Val rv = evalExpr(r, env);
      switch (<lv, rv>) {
        case <Values::VInt(int ln), Values::VInt(int rn)>: return Values::VInt(ln - rn);
        default: {
          switch (<lv, rv>) {
            case <Values::VFloat(_), _>: return Values::VFloat(toRealVal(lv) - toRealVal(rv));
            case <_, Values::VFloat(_)>: return Values::VFloat(toRealVal(lv) - toRealVal(rv));
            default: throw "Type error in subtraction";
          }
        }
      }
    }
    case mul(Expr l, Expr r): {
      Val lv = evalExpr(l, env);
      Val rv = evalExpr(r, env);
      switch (<lv, rv>) {
        case <Values::VInt(int ln), Values::VInt(int rn)>: return Values::VInt(ln * rn);
        default: {
          switch (<lv, rv>) {
            case <Values::VFloat(_), _>: return Values::VFloat(toRealVal(lv) * toRealVal(rv));
            case <_, Values::VFloat(_)>: return Values::VFloat(toRealVal(lv) * toRealVal(rv));
            default: throw "Type error in multiplication";
          }
        }
      }
    }
    case div(Expr l, Expr r): {
      return Values::VFloat(toRealVal(evalExpr(l, env)) / toRealVal(evalExpr(r, env)));
    }
    case modulo(Expr l, Expr r): {
      Val lv = evalExpr(l, env);
      Val rv = evalExpr(r, env);
      switch (<lv, rv>) {
        case <Values::VInt(int ln), Values::VInt(int rn)>: return Values::VInt(ln % rn);
        default: throw "Type error in modulo";
      }
    }
    case neg(Expr e): {
      Val v = evalExpr(e, env);
      switch (v) {
        case Values::VInt(int n): return Values::VInt(-n);
        case Values::VFloat(real r): return Values::VFloat(-r);
        default: throw "Type error in negation";
      }
    }
    case pow(Expr base, Expr exp): {
      Val bv = evalExpr(base, env);
      Val ev = evalExpr(exp, env);
      switch (ev) {
        case Values::VInt(int n): {
          if (n >= 0) {
            real baseVal = toRealVal(bv);
            real acc = 1.0;
            for (_ <- [1..n+1]) {
              acc = acc * baseVal;
            }
            return Values::VFloat(acc);
          }
          throw "Type error in power: exponent must be non-negative";
        }
        default: throw "Type error in power";
      }
    }
    
    // Operaciones lógicas
    case and(Expr l, Expr r): {
      Val lv = evalExpr(l, env);
      Val rv = evalExpr(r, env);
      switch (<lv, rv>) {
        case <Values::VBool(bool lb), Values::VBool(bool rb)>: return Values::VBool(lb && rb);
        default: throw "Type error in and";
      }
    }
    case or(Expr l, Expr r): {
      Val lv = evalExpr(l, env);
      Val rv = evalExpr(r, env);
      switch (<lv, rv>) {
        case <Values::VBool(bool lb), Values::VBool(bool rb)>: return Values::VBool(lb || rb);
        default: throw "Type error in or";
      }
    }
    case not(Expr e): {
      Val v = evalExpr(e, env);
      switch (v) {
        case Values::VBool(bool b): return Values::VBool(!b);
        default: throw "Type error in not";
      }
    }
    
    // Operadores relacionales
    case lt(Expr l, Expr r): {
      return Values::VBool(toRealVal(evalExpr(l, env)) < toRealVal(evalExpr(r, env)));
    }
    case gt(Expr l, Expr r): {
      return Values::VBool(toRealVal(evalExpr(l, env)) > toRealVal(evalExpr(r, env)));
    }
    case le(Expr l, Expr r): {
      return Values::VBool(toRealVal(evalExpr(l, env)) <= toRealVal(evalExpr(r, env)));
    }
    case ge(Expr l, Expr r): {
      return Values::VBool(toRealVal(evalExpr(l, env)) >= toRealVal(evalExpr(r, env)));
    }
    case eq(Expr l, Expr r): {
      return Values::VBool(toRealVal(evalExpr(l, env)) == toRealVal(evalExpr(r, env)));
    }
    case ne(Expr l, Expr r): {
      return Values::VBool(toRealVal(evalExpr(l, env)) != toRealVal(evalExpr(r, env)));
    }
    
    // Estructuras de datos (por ahora solo evaluamos, no almacenamos)
    case listLit(list[Expr] elems): {
      // Evaluar elementos pero no almacenar la lista completa
      for (elem <- elems) {
        evalExpr(elem, env);
      }
      return Values::VInt(0);
    }
    case setLit(set[Expr] setElems): {
      for (elem <- setElems) {
        evalExpr(elem, env);
      }
      return Values::VInt(0);
    }
    case mapLit(list[tuple[Expr, Expr]] pairs): {
      for (<Expr k, Expr v> <- pairs) {
        evalExpr(k, env);
        evalExpr(v, env);
      }
      return Values::VInt(0);
    }
  }
  return Values::VInt(0);
}

// Convierte un valor a real
real toRealVal(Val v) {
  switch (v) {
    case Values::VInt(int n): return n * 1.0;
    case Values::VFloat(real r): return r;
    default: throw "Type error: expected numeric";
  }
}
