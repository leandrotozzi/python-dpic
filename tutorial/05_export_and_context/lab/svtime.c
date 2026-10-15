/* svGetTime asks for simulation time (vpiSimTime, in precision units) or scaled real time
   (vpiScaledRealTime, in the scope's time unit). The real field is preset to -1 to see
   whether the simulator writes it. */
#include <stdio.h>
#include "svdpi.h"
static void report(const char* tag) {
    svScope s = svGetScope();
    svTimeVal sim, scaled, global;
    sim.type = vpiSimTime;             sim.real = -1;
    scaled.type = vpiScaledRealTime;   scaled.real = -1;
    global.type = vpiSimTime;
    int rc1 = svGetTime(s, &sim), rc2 = svGetTime(s, &scaled), rc3 = svGetTime(NULL, &global);
    int unit = 99, prec = 99, gunit = 99;
    svGetTimeUnit(s, &unit); svGetTimePrecision(s, &prec); svGetTimeUnit(NULL, &gunit);
    printf("LOG svtime tag=%s rc=%d%d%d sim=%u scaled_low=%u scaled_real=%g global=%u unit=%d prec=%d gunit=%d\n",
           tag, rc1, rc2, rc3, sim.low, scaled.low, scaled.real, global.low, unit, prec, gunit);
    fflush(stdout);
}
extern "C" void c_time(const char* tag)     { report(tag); }
extern "C" void c_time_sub(const char* tag) { report(tag); }
