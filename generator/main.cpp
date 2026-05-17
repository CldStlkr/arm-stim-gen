#include <fstream>
#include <iostream>
#include <string>

void write_test(const std::string& path) {
  std::ofstream out(path);
  if (!out) {
    std::cerr << "Error: could not open " << path << "\n";
    return;
  }

  out << ".section .data\n";
  out << "result_buf: .space 40\n"; // 5 regs * 8 bytes
  out << "result_path: .asciz \"/tmp/stim_result.bin\"\n";

  out << ".section .text\n";
  out << ".global _start\n";
  out << "_start:\n";

  out << "    MOV x0, #1\n";
  out << "    MOV x1, #2\n";

  out << "    ADD x2, x0, x1\n"; // expect x2 = 3
  out << "    MUL x3, x0, x1\n"; // expect x3 = 2
  out << "    SUB x4, x1, x0\n"; // expect x4 = 1

  out << "    ADRP x20, result_buf\n";
  out << "    ADD  x20, x20, :lo12:result_buf\n";
  out << "    STR x0, [x20, #0]\n";
  out << "    STR x1, [x20, #8]\n";
  out << "    STR x2, [x20, #16]\n";
  out << "    STR x3, [x20, #24]\n";
  out << "    STR x4, [x20, #32]\n";

  // --- openat(AT_FDCWD, result_path, O_WRONLY|O_CREAT|O_TRUNC, 0644) ---
  out << "    MOV x0, #-100\n"; // AT_FDCWD
  out << "    ADRP x1, result_path\n";
  out << "    ADD  x1, x1, :lo12:result_path\n";
  out << "    MOV x2, #577\n";   // O_WRONLY|O_CREAT|O_TRUNC = 0x241
  out << "    MOV x3, #0x1A4\n"; // mode 0644
  out << "    MOV x8, #56\n";    // syscall: openat
  out << "    SVC #0\n";         // returns fd in x0

  // --- write(fd, result_buf, 40) ---
  out << "    MOV x1, x20\n"; // buf = result_buf addr (still in x20)
  out << "    MOV x2, #40\n"; // count
  out << "    MOV x8, #64\n"; // syscall: write
  out << "    SVC #0\n";

  // --- exit(0) ---
  out << "    MOV x8, #93\n";
  out << "    MOV x0, #0\n";
  out << "    SVC #0\n";

  out.close();
  std::cout << "Wrote test to " << path << "\n";
}

int main(int argc, char* argv[]) {
  std::string output_path = "tests/test_000.S";
  if (argc > 1) {
    output_path = argv[1];
  }
  write_test(output_path);
  return 0;
}
