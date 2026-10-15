/* C side of pure_rules.sv: trivial bodies, the point is what the SV compiler accepts. */
extern "C" {
void pr_void(int a) { (void)a; }
int  pr_task(int a) { (void)a; return 0; }   /* import task: int = disable flag */
int  pr_out(int a, int* b) { *b = a + 1; return a; }
}
