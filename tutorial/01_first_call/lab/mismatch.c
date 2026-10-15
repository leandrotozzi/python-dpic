/* BUG: the C author thinks negate takes and returns a 32-bit int.
   With extern "C" there is no name mangling, so it links; the ABI does the rest. */
extern "C" int negate(int v) { return -v; }
