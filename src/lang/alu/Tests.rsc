module lang::alu::Tests

import IO;
import lang::alu::Main;
import List;
import FileSystem;

// Ejecuta todos los casos de prueba válidos
public void runValidTests() {
  println("=== Running Valid Tests ===");
  list[loc] validFiles = listFiles(|file:///home/saro/university/lym/proyecto2/alu/tests/valid|, "*.alu");
  int passed = 0;
  int failed = 0;
  
  for (file <- validFiles) {
    println("\nTesting: <file>");
    try {
      runFile(file);
      println("✓ PASSED");
      passed += 1;
    } catch str msg: {
      println("✗ FAILED: <msg>");
      failed += 1;
    }
  }
  
  println("\n=== Valid Tests Summary ===");
  println("Passed: <passed>");
  println("Failed: <failed>");
}

// Ejecuta todos los casos de prueba inválidos (deben fallar)
public void runInvalidTests() {
  println("\n=== Running Invalid Tests ===");
  list[loc] invalidFiles = listFiles(|file:///home/saro/university/lym/proyecto2/alu/tests/invalid|, "*.alu");
  int passed = 0; // passed = detectó el error correctamente
  int failed = 0; // failed = no detectó el error
  
  for (file <- invalidFiles) {
    println("\nTesting: <file>");
    try {
      runFile(file);
      println("✗ FAILED: Should have detected an error but didn't");
      failed += 1;
    } catch str msg: {
      println("✓ PASSED: Correctly detected error: <msg>");
      passed += 1;
    }
  }
  
  println("\n=== Invalid Tests Summary ===");
  println("Correctly rejected: <passed>");
  println("Incorrectly accepted: <failed>");
}

// Ejecuta todos los tests
public void runAllTests() {
  runValidTests();
  runInvalidTests();
}

