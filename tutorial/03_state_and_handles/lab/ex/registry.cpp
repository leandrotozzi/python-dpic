// T10: per-instance state WITHOUT a chandle. Each module instance passes its own hierarchical
// name (%m); C++ keeps one state object per name in a map. Cost: a string hash per call.
#include <map>
#include <string>
static std::map<std::string, int> state;
extern "C" int acc_by_name(const char* who, int x) { return state[who] += x; }   // creates on first use
extern "C" int acc_instances(void) { return (int)state.size(); }
