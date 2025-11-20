module lang::alu::TypeChecker

import lang::alu::AST;
import lang::alu::Syntax;

extend analysis::typepal::TypePal;

import IO;
import Set;
import Map;
import ParseTree;

// Define the type of ALU types within TypePal
data AType
    = tint()
    | tbool()
    | tchar()
    | tstring()
    | tlist(AType elem)
    | tset(AType elem)
    | tmap(AType k, AType v)
    ;

// Convert AST Type to TypePal AType
AType fromASTType(Type t) {
    switch (t) {
        case TInt(): return tint();
        case TBool(): return tbool();
        case TChar(): return tchar();
        case TString(): return tstring();
        case TList(Type elem): return tlist(fromASTType(elem));
        case TSet(Type elem): return tset(fromASTType(elem));
        case TMap(Type k, Type v): return tmap(fromASTType(k), fromASTType(v));
    }
}

// Convert TypePal AType to AST Type
Type toASTType(AType t) {
    switch (t) {
        case tint(): return TInt();
        case tbool(): return TBool();
        case tchar(): return TChar();
        case tstring(): return TString();
        case tlist(AType elem): return TList(toASTType(elem));
        case tset(AType elem): return TSet(toASTType(elem));
        case tmap(AType k, AType v): return TMap(toASTType(k), toASTType(v));
    }
}

// String representation for error messages
str prettyAType(tint()) = "int";
str prettyAType(tbool()) = "bool";
str prettyAType(tchar()) = "char";
str prettyAType(tstring()) = "string";
str prettyAType(tlist(AType elem)) = "list\<<prettyAType(elem)>\>";
str prettyAType(tset(AType elem)) = "set\<<prettyAType(elem)>\>";
str prettyAType(tmap(AType k, AType v)) = "map\<<prettyAType(k)>,<prettyAType(v)>\>";

// Collect facts and constraints for TypePal
void collect(Program program, Collector c) {
    // Collect all declarations
    for (decl <- program.decls) {
        collect(decl, c);
    }

    // Collect all statements
    for (stmt <- program.stmts) {
        collect(stmt, c);
    }
}

// Collect facts for declarations
void collect(Decl decl, Collector c) {
    switch (decl) {
        case TypedDecl(Type t, str name, Expr init): {
            AType atype = fromASTType(t);
            // Define the variable with its type
            c.define(name, variableId(), decl, defType(atype));
            // Require that the initializer has the same type
            c.requireEqual(atype, init, error(init, "Initializer type mismatch: expected %t, got %t", atype, init));
            // Collect the initializer expression
            collect(init, c);
        }
        case TypedDeclNoInit(Type t, str name): {
            AType atype = fromASTType(t);
            // Define the variable with its type
            c.define(name, variableId(), decl, defType(atype));
        }
        case TypedListDecl(Type t, str name, list[Expr] elems): {
            if (!(t is TList)) {
                c.report(error(decl, "List declaration must have list type"));
                return;
            }
            AType atype = fromASTType(t);
            AType elemType = fromASTType(t.elem);
            // Define the list variable
            c.define(name, variableId(), decl, defType(atype));
            // Check each element has the correct type
            for (elem <- elems) {
                c.requireEqual(elemType, elem, error(elem, "List element type mismatch: expected %t, got %t", elemType, elem));
                collect(elem, c);
            }
        }
        case TypedSetDecl(Type t, str name, set[Expr] setElems): {
            if (!(t is TSet)) {
                c.report(error(decl, "Set declaration must have set type"));
                return;
            }
            AType atype = fromASTType(t);
            AType elemType = fromASTType(t.elem);
            // Define the set variable
            c.define(name, variableId(), decl, defType(atype));
            // Check each element has the correct type
            for (elem <- setElems) {
                c.requireEqual(elemType, elem, error(elem, "Set element type mismatch: expected %t, got %t", elemType, elem));
                collect(elem, c);
            }
        }
        case TypedMapDecl(Type t, str name, list[tuple[Expr, Expr]] pairs): {
            if (!(t is TMap)) {
                c.report(error(decl, "Map declaration must have map type"));
                return;
            }
            AType atype = fromASTType(t);
            AType keyType = fromASTType(t.k);
            AType valType = fromASTType(t.v);
            // Define the map variable
            c.define(name, variableId(), decl, defType(atype));
            // Check each pair has the correct types
            for (<Expr k, Expr v> <- pairs) {
                c.requireEqual(keyType, k, error(k, "Map key type mismatch: expected %t, got %t", keyType, k));
                c.requireEqual(valType, v, error(v, "Map value type mismatch: expected %t, got %t", valType, v));
                collect(k, c);
                collect(v, c);
            }
        }
    }
}

// Collect facts for statements
void collect(Stmt stmt, Collector c) {
    switch (stmt) {
        case Assign(str name, Expr e): {
            // Use the variable - this will check it's declared
            c.use(name, {variableId()});
            // Get the variable's declared type and require the expression matches
            c.requireEqual(name, e, error(e, "Assignment type mismatch: cannot assign %t to variable of type %t", e, name));
            collect(e, c);
        }
        case If(Expr cond, list[Stmt] thenBranch, list[Stmt] elseBranch): {
            c.requireEqual(tbool(), cond, error(cond, "If condition must be bool, got %t", cond));
            collect(cond, c);
            for (s <- thenBranch) collect(s, c);
            for (s <- elseBranch) collect(s, c);
        }
        case While(Expr cond, list[Stmt] body): {
            c.requireEqual(tbool(), cond, error(cond, "While condition must be bool, got %t", cond));
            collect(cond, c);
            for (s <- body) collect(s, c);
        }
        case Block(list[Stmt] stmts): {
            for (s <- stmts) collect(s, c);
        }
    }
}

// Collect facts for expressions
void collect(Expr e, Collector c) {
    switch (e) {
        // Literals - these have known types
        case intConst(int _): {
            c.fact(e, tint());
        }
        case floatConst(real _): {
            c.fact(e, tint()); // Treat floats as ints for simplicity
        }
        case boolConst(bool _): {
            c.fact(e, tbool());
        }
        case charConst(str _): {
            c.fact(e, tchar());
        }
        case stringConst(str _): {
            c.fact(e, tstring());
        }

        // Variables - use them and calculate their type
        case var(str name): {
            c.use(name, {variableId()});
            c.fact(e, name);
        }

        // Arithmetic operations - require int operands, result is int
        case add(Expr l, Expr r): {
            c.requireEqual(tint(), l, error(l, "Addition requires int operands, got %t", l));
            c.requireEqual(tint(), r, error(r, "Addition requires int operands, got %t", r));
            c.fact(e, tint());
            collect(l, c);
            collect(r, c);
        }
        case sub(Expr l, Expr r): {
            c.requireEqual(tint(), l, error(l, "Subtraction requires int operands, got %t", l));
            c.requireEqual(tint(), r, error(r, "Subtraction requires int operands, got %t", r));
            c.fact(e, tint());
            collect(l, c);
            collect(r, c);
        }
        case mul(Expr l, Expr r): {
            c.requireEqual(tint(), l, error(l, "Multiplication requires int operands, got %t", l));
            c.requireEqual(tint(), r, error(r, "Multiplication requires int operands, got %t", r));
            c.fact(e, tint());
            collect(l, c);
            collect(r, c);
        }
        case div(Expr l, Expr r): {
            c.requireEqual(tint(), l, error(l, "Division requires int operands, got %t", l));
            c.requireEqual(tint(), r, error(r, "Division requires int operands, got %t", r));
            c.fact(e, tint());
            collect(l, c);
            collect(r, c);
        }
        case modulo(Expr l, Expr r): {
            c.requireEqual(tint(), l, error(l, "Modulo requires int operands, got %t", l));
            c.requireEqual(tint(), r, error(r, "Modulo requires int operands, got %t", r));
            c.fact(e, tint());
            collect(l, c);
            collect(r, c);
        }
        case neg(Expr expr): {
            c.requireEqual(tint(), expr, error(expr, "Negation requires int operand, got %t", expr));
            c.fact(e, tint());
            collect(expr, c);
        }
        case pow(Expr base, Expr exp): {
            c.requireEqual(tint(), base, error(base, "Power requires int operands, got %t", base));
            c.requireEqual(tint(), exp, error(exp, "Power requires int operands, got %t", exp));
            c.fact(e, tint());
            collect(base, c);
            collect(exp, c);
        }

        // Logical operations - require bool operands, result is bool
        case and(Expr l, Expr r): {
            c.requireEqual(tbool(), l, error(l, "And requires bool operands, got %t", l));
            c.requireEqual(tbool(), r, error(r, "And requires bool operands, got %t", r));
            c.fact(e, tbool());
            collect(l, c);
            collect(r, c);
        }
        case or(Expr l, Expr r): {
            c.requireEqual(tbool(), l, error(l, "Or requires bool operands, got %t", l));
            c.requireEqual(tbool(), r, error(r, "Or requires bool operands, got %t", r));
            c.fact(e, tbool());
            collect(l, c);
            collect(r, c);
        }
        case not(Expr expr): {
            c.requireEqual(tbool(), expr, error(expr, "Not requires bool operand, got %t", expr));
            c.fact(e, tbool());
            collect(expr, c);
        }

        // Comparison operations - require int operands, result is bool
        case lt(Expr l, Expr r): {
            c.requireEqual(tint(), l, error(l, "Comparison requires int operands, got %t", l));
            c.requireEqual(tint(), r, error(r, "Comparison requires int operands, got %t", r));
            c.fact(e, tbool());
            collect(l, c);
            collect(r, c);
        }
        case gt(Expr l, Expr r): {
            c.requireEqual(tint(), l, error(l, "Comparison requires int operands, got %t", l));
            c.requireEqual(tint(), r, error(r, "Comparison requires int operands, got %t", r));
            c.fact(e, tbool());
            collect(l, c);
            collect(r, c);
        }
        case le(Expr l, Expr r): {
            c.requireEqual(tint(), l, error(l, "Comparison requires int operands, got %t", l));
            c.requireEqual(tint(), r, error(r, "Comparison requires int operands, got %t", r));
            c.fact(e, tbool());
            collect(l, c);
            collect(r, c);
        }
        case ge(Expr l, Expr r): {
            c.requireEqual(tint(), l, error(l, "Comparison requires int operands, got %t", l));
            c.requireEqual(tint(), r, error(r, "Comparison requires int operands, got %t", r));
            c.fact(e, tbool());
            collect(l, c);
            collect(r, c);
        }
        case eq(Expr l, Expr r): {
            // Equality can work on any type, but both sides must match
            c.requireEqual(l, r, error(r, "Equality requires same types, got %t and %t", l, r));
            c.fact(e, tbool());
            collect(l, c);
            collect(r, c);
        }
        case ne(Expr l, Expr r): {
            // Inequality can work on any type, but both sides must match
            c.requireEqual(l, r, error(r, "Inequality requires same types, got %t and %t", l, r));
            c.fact(e, tbool());
            collect(l, c);
            collect(r, c);
        }

        // Data structures
        case listLit(list[Expr] elems): {
            if (size(elems) == 0) {
                c.report(error(e, "Cannot infer type of empty list"));
            } else {
                // All elements must have the same type
                Expr first = elems[0];
                for (elem <- elems[1..]) {
                    c.requireEqual(first, elem, error(elem, "List elements must have same type: expected %t, got %t", first, elem));
                }
                // Calculate the type based on the first element
                c.calculate("list type", e, [first],
                    AType (Solver s) { return tlist(s.getType(first)); });
                // Collect all elements
                for (elem <- elems) collect(elem, c);
            }
        }
        case setLit(set[Expr] setElems): {
            if (size(setElems) == 0) {
                c.report(error(e, "Cannot infer type of empty set"));
            } else {
                list[Expr] elemsList = [elem | elem <- setElems];
                Expr first = elemsList[0];
                for (elem <- elemsList[1..]) {
                    c.requireEqual(first, elem, error(elem, "Set elements must have same type: expected %t, got %t", first, elem));
                }
                c.calculate("set type", e, [first],
                    AType (Solver s) { return tset(s.getType(first)); });
                for (elem <- setElems) collect(elem, c);
            }
        }
        case mapLit(list[tuple[Expr, Expr]] pairs): {
            if (size(pairs) == 0) {
                c.report(error(e, "Cannot infer type of empty map"));
            } else {
                <Expr firstKey, Expr firstVal> = pairs[0];
                for (<Expr k, Expr v> <- pairs[1..]) {
                    c.requireEqual(firstKey, k, error(k, "Map keys must have same type: expected %t, got %t", firstKey, k));
                    c.requireEqual(firstVal, v, error(v, "Map values must have same type: expected %t, got %t", firstVal, v));
                }
                c.calculate("map type", e, [firstKey, firstVal],
                    AType (Solver s) { return tmap(s.getType(firstKey), s.getType(firstVal)); });
                for (<Expr k, Expr v> <- pairs) {
                    collect(k, c);
                    collect(v, c);
                }
            }
        }
    }
}

// Main type checking function
public TypePalConfig aluTypeCheckConfig() = tconfig(
    verbose = false,
    logTModel = false,
    logAttempts = false,
    logSolverSteps = false,
    logSolverIterations = false
);

// Type check a program and return the TModel
public TModel aluTypePalChecker(Program program) {
    return collectAndSolve(program, config = aluTypeCheckConfig());
}

// Type check and report errors
public list[Message] checkTypes(Program program) {
    TModel tm = aluTypePalChecker(program);
    return tm.messages;
}
