module lang::alu::ToAST

import lang::alu::Syntax;
import lang::alu::AST;
import ParseTree;
import String;

// Transforma un Type del parse tree a Type del AST usando string matching
public AST::Type toTypeSimple(str typeStr) {
  typeStr = trim(typeStr);
  if (typeStr == "int") return AST::TInt();
  if (typeStr == "bool") return AST::TBool();
  if (typeStr == "char") return AST::TChar();
  if (typeStr == "string") return AST::TString();
  if (typeStr == "list") return AST::TList(AST::TInt());
  if (typeStr == "set") return AST::TSet(AST::TInt());
  if (typeStr == "map") return AST::TMap(AST::TInt(), AST::TInt());
  return AST::TInt();
}

// Inferir tipo de una expresión AST
AST::Type inferType(AST::Expr e) {
  switch (e) {
    case AST::intConst(_): return AST::TInt();
    case AST::boolConst(_): return AST::TBool();
    case AST::charConst(_): return AST::TChar();
    case AST::stringConst(_): return AST::TString();
    default: return AST::TInt();
  }
}

// Inferir tipo de lista basado en elementos
AST::Type inferListType(list[AST::Expr] elems) {
  if (size(elems) > 0) {
    return AST::TList(inferType(elems[0]));
  }
  return AST::TList(AST::TInt());
}

// Transforma TypedDecl usando visitas
public AST::Decl toDecl(Syntax::TypedDecl td) {
  str tdStr = "<td>";
  list[Syntax::Type] types = [t | /Syntax::Type t := td];
  list[Syntax::Id] ids = [i | /Syntax::Id i := td];
  list[Syntax::Expression] exprs = [e | /Syntax::Expression e := td];
  list[Syntax::ListLiteral] lists = [l | /Syntax::ListLiteral l := td];
  list[Syntax::SetLiteral] sets = [s | /Syntax::SetLiteral s := td];
  list[Syntax::MapLiteral] maps = [m | /Syntax::MapLiteral m := td];

  if (size(types) > 0 && size(ids) > 0) {
    str typeName = "<types[0]>";
    str varName = "<ids[0]>";

    // Declaración con lista
    if (size(lists) > 0) {
      list[AST::Expr] elems = toListElems(lists[0]);
      return AST::TypedListDecl(inferListType(elems), varName, elems);
    }
    // Declaración con set
    else if (size(sets) > 0) {
      set[AST::Expr] elems = toSetElems(sets[0]);
      list[AST::Expr] elemsList = [e | e <- elems];
      AST::Type t = (size(elemsList) > 0) ? AST::TSet(inferType(elemsList[0])) : AST::TSet(AST::TInt());
      return AST::TypedSetDecl(t, varName, elems);
    }
    // Declaración con map
    else if (size(maps) > 0) {
      list[tuple[AST::Expr, AST::Expr]] pairs = toMapPairs(maps[0]);
      return AST::TypedMapDecl(AST::TMap(AST::TInt(), AST::TInt()), varName, pairs);
    }
    // Declaración con expresión
    else if (size(exprs) > 0) {
      AST::Expr expr = toExpr(exprs[0]);
      AST::Type t = toTypeSimple(typeName);
      return AST::TypedDecl(t, varName, expr);
    }
    // Declaración sin inicialización
    else {
      return AST::TypedDeclNoInit(toTypeSimple(typeName), varName);
    }
  }

  throw "Unknown typed declaration: <tdStr>";
}

// Extrae elementos de ListLiteral
list[AST::Expr] toListElems(Syntax::ListLiteral l) {
  list[Syntax::Expression] exprs = [e | /Syntax::Expression e := l];
  return [toExpr(e) | e <- exprs];
}

// Extrae elementos de SetLiteral
set[AST::Expr] toSetElems(Syntax::SetLiteral s) {
  list[Syntax::Expression] exprs = [e | /Syntax::Expression e := s];
  return {toExpr(e) | e <- exprs};
}

// Extrae pares de MapLiteral
list[tuple[AST::Expr, AST::Expr]] toMapPairs(Syntax::MapLiteral m) {
  list[Syntax::MapPair] pairs = [p | /Syntax::MapPair p := m];
  list[tuple[AST::Expr, AST::Expr]] result = [];
  for (p <- pairs) {
    list[Syntax::Expression] exprs = [e | /Syntax::Expression e := p];
    if (size(exprs) >= 2) {
      result += [<toExpr(exprs[0]), toExpr(exprs[1])>];
    }
  }
  return result;
}

// Transforma Statement a Stmt
public AST::Stmt toStmt(Syntax::Statement s) {
  str sStr = "<s>";

  // Assignment
  if (contains(sStr, "set") && contains(sStr, ":=")) {
    list[Syntax::Id] ids = [i | /Syntax::Id i := s];
    list[Syntax::Expression] exprs = [e | /Syntax::Expression e := s];
    if (size(ids) > 0 && size(exprs) > 0) {
      return AST::Assign("<ids[0]>", toExpr(exprs[0]));
    }
  }

  // If statement
  if (startsWith(trim(sStr), "if")) {
    list[Syntax::Expression] exprs = [e | /Syntax::Expression e := s];
    list[Syntax::Body] bodies = [b | /Syntax::Body b := s];
    if (size(exprs) > 0 && size(bodies) >= 2) {
      return AST::If(toExpr(exprs[0]), toStmts(bodies[0]), toStmts(bodies[1]));
    }
  }

  // While statement
  if (startsWith(trim(sStr), "while")) {
    list[Syntax::Expression] exprs = [e | /Syntax::Expression e := s];
    list[Syntax::Body] bodies = [b | /Syntax::Body b := s];
    if (size(exprs) > 0 && size(bodies) > 0) {
      return AST::While(toExpr(exprs[0]), toStmts(bodies[0]));
    }
  }

  return AST::Block([]);
}

// Transforma Body a lista de Stmt
list[AST::Stmt] toStmts(Syntax::Body b) {
  list[Syntax::Statement] stmts = [s | /Syntax::Statement s := b, s != b];
  list[AST::Stmt] result = [];
  for (s <- stmts) {
    str sStr = "<s>";
    // Skip typed declarations
    if (!contains(sStr, " = ") || !contains(sStr, ";") || contains(sStr, "set")) {
      result += [toStmt(s)];
    }
  }
  return result;
}

// Transforma Expression a Expr
public AST::Expr toExpr(Syntax::Expression e) {
  str eStr = trim("<e>");

  // Literales booleanos
  if (eStr == "true") return AST::boolConst(true);
  if (eStr == "false") return AST::boolConst(false);

  // Literales numéricos
  if (/^[0-9]+$/ := eStr) return AST::intConst(toInt(eStr));
  if (/^[0-9]+\.[0-9]+$/ := eStr) return AST::floatConst(toReal(eStr));

  // Listas, sets, maps
  list[Syntax::ListLiteral] lists = [l | /Syntax::ListLiteral l := e];
  list[Syntax::SetLiteral] sets = [s | /Syntax::SetLiteral s := e];
  list[Syntax::MapLiteral] maps = [m | /Syntax::MapLiteral m := e];

  if (size(lists) > 0) return AST::listLit(toListElems(lists[0]));
  if (size(sets) > 0) return AST::setLit(toSetElems(sets[0]));
  if (size(maps) > 0) return AST::mapLit(toMapPairs(maps[0]));

  // Subexpresiones
  list[Syntax::Expression] subs = [ex | /Syntax::Expression ex := e, ex != e];

  // Operadores binarios
  if (contains(eStr, "**") && size(subs) >= 2) return AST::pow(toExpr(subs[0]), toExpr(subs[1]));
  if (contains(eStr, " * ") && !contains(eStr, "**") && size(subs) >= 2) return AST::mul(toExpr(subs[0]), toExpr(subs[1]));
  if (contains(eStr, " / ") && size(subs) >= 2) return AST::div(toExpr(subs[0]), toExpr(subs[1]));
  if (contains(eStr, " mod ") && size(subs) >= 2) return AST::modulo(toExpr(subs[0]), toExpr(subs[1]));
  if (contains(eStr, " + ") && size(subs) >= 2) return AST::add(toExpr(subs[0]), toExpr(subs[1]));
  if (contains(eStr, " - ") && !startsWith(eStr, "neg") && size(subs) >= 2) return AST::sub(toExpr(subs[0]), toExpr(subs[1]));

  // Comparaciones
  if (contains(eStr, " == ") && size(subs) >= 2) return AST::eq(toExpr(subs[0]), toExpr(subs[1]));
  if (contains(eStr, " != ") && size(subs) >= 2) return AST::ne(toExpr(subs[0]), toExpr(subs[1]));
  if (contains(eStr, ".lt.") && size(subs) >= 2) return AST::lt(toExpr(subs[0]), toExpr(subs[1]));
  if (contains(eStr, ".gt.") && size(subs) >= 2) return AST::gt(toExpr(subs[0]), toExpr(subs[1]));
  if (contains(eStr, ".le.") && size(subs) >= 2) return AST::le(toExpr(subs[0]), toExpr(subs[1]));
  if (contains(eStr, ".ge.") && size(subs) >= 2) return AST::ge(toExpr(subs[0]), toExpr(subs[1]));

  // Operadores lógicos
  if ((contains(eStr, " and ") || contains(eStr, " && ")) && size(subs) >= 2) return AST::and(toExpr(subs[0]), toExpr(subs[1]));
  if ((contains(eStr, " or ") || contains(eStr, " || ")) && size(subs) >= 2) return AST::or(toExpr(subs[0]), toExpr(subs[1]));

  // Operador unario
  if (startsWith(eStr, "neg ") && size(subs) >= 1) return AST::neg(toExpr(subs[0]));

  // Paréntesis
  if (startsWith(eStr, "(") && endsWith(eStr, ")") && size(subs) >= 1) return toExpr(subs[0]);

  // Principal (variables, literales)
  list[Syntax::Principal] prins = [p | /Syntax::Principal p := e];
  if (size(prins) > 0) return toExprFromPrincipal(prins[0]);

  // Default
  return AST::intConst(0);
}

// Transforma Principal a Expr
AST::Expr toExprFromPrincipal(Syntax::Principal p) {
  str pStr = trim("<p>");

  if (pStr == "true") return AST::boolConst(true);
  if (pStr == "false") return AST::boolConst(false);

  if (/^[0-9]+$/ := pStr) return AST::intConst(toInt(pStr));
  if (/^[0-9]+\.[0-9]+$/ := pStr) return AST::floatConst(toReal(pStr));

  if (startsWith(pStr, "\'") && endsWith(pStr, "\'")) return AST::charConst(pStr);
  if (startsWith(pStr, "\"") && endsWith(pStr, "\"")) return AST::stringConst(pStr);

  return AST::var(pStr);
}

// Transforma Program completo
public AST::Program toProgram(Syntax::Program pt) {
  list[AST::Decl] decls = [];
  list[AST::Stmt] stmts = [];

  // Extraer todos los módulos de función
  list[Syntax::Function] funcs = [f | /Syntax::Function f := pt];

  for (f <- funcs) {
    // Extraer cuerpos
    list[Syntax::Body] bodies = [b | /Syntax::Body b := f];
    for (b <- bodies) {
      // Extraer statements
      list[Syntax::Statement] statements = [s | /Syntax::Statement s := b, s != b];
      for (s <- statements) {
        // Verificar si es typed declaration
        list[Syntax::TypedDecl] tds = [td | /Syntax::TypedDecl td := s];
        if (size(tds) > 0) {
          for (td <- tds) {
            decls += [toDecl(td)];
          }
        } else {
          str sStr = "<s>";
          if (!contains(sStr, " = ") || contains(sStr, "set")) {
            stmts += [toStmt(s)];
          }
        }
      }
    }
  }

  return AST::program(decls, stmts);
}
