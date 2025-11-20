module lang::alu::AST

// Definición de tipos en el AST
data Type
  = TInt()
  | TBool()
  | TChar()
  | TString()
  | TList(Type elem)
  | TSet(Type elem)
  | TMap(Type k, Type v)
  ;

// Programa: lista de declaraciones y sentencias
data Program = program(list[Decl] decls, list[Stmt] stmts);

// Declaraciones tipadas
data Decl
  = TypedDecl(Type t, str name, Expr init)
  | TypedDeclNoInit(Type t, str name)
  | TypedListDecl(Type t, str name, list[Expr] elems)
  | TypedSetDecl(Type t, str name, set[Expr] setElems)
  | TypedMapDecl(Type t, str name, list[tuple[Expr, Expr]] pairs)
  ;

// Sentencias
data Stmt
  = Assign(str name, Expr e)
  | If(Expr cond, list[Stmt] thenBranch, list[Stmt] elseBranch)
  | While(Expr cond, list[Stmt] body)
  | Block(list[Stmt] stmts)
  ;

// Expresiones
data Expr
  = intConst(int n)
  | floatConst(real r)
  | boolConst(bool b)
  | charConst(str c)
  | stringConst(str s)
  | var(str name)
  | add(Expr left, Expr right)
  | sub(Expr left, Expr right)
  | mul(Expr left, Expr right)
  | div(Expr left, Expr right)
  | modulo(Expr left, Expr right)
  | neg(Expr e)
  | pow(Expr base, Expr exp)
  | and(Expr left, Expr right)
  | or(Expr left, Expr right)
  | not(Expr e)
  | lt(Expr left, Expr right)
  | gt(Expr left, Expr right)
  | le(Expr left, Expr right)
  | ge(Expr left, Expr right)
  | eq(Expr left, Expr right)
  | ne(Expr left, Expr right)
  | listLit(list[Expr] elems)
  | setLit(set[Expr] setElems)
  | mapLit(list[tuple[Expr, Expr]] pairs)
  ;

