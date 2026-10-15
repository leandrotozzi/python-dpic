// Sample 12.41 (C side of the book's timed memory). Only compiled to show Verilator's verdict.
#include <stdio.h>
#include "svdpi.h"
int read_file(const char* fname) {
  extern void mem_build(int);
  extern int mem_write(int, int);
  mem_build(100);
  mem_write(12, 34);
  return 0;
}
