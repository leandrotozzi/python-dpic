/* Exercise 9. The LRM maps byte to plain char, whose signedness is implementation-defined. */
#ifdef __cplusplus
extern "C" {
#endif
int c_isneg_bad(char b) { return b < 0; }
int c_isneg(char b) { return (signed char)b < 0; }
#ifdef __cplusplus
}
#endif
