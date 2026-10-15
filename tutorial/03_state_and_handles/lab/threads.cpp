// Which OS threads call a DPI import under `verilator --threads 2`? Each call records the calling
// thread id. Pure and non-pure imports are counted separately.
#include <mutex>
#include <set>
#include <thread>

static std::mutex mtx;                       // needed: these may run concurrently
static std::set<std::thread::id> pure_ids, impure_ids;

extern "C" int tag_pure(int x)   { std::lock_guard<std::mutex> g(mtx); pure_ids.insert(std::this_thread::get_id());   return x * 3 + 1; }
extern "C" int tag_impure(int x) { std::lock_guard<std::mutex> g(mtx); impure_ids.insert(std::this_thread::get_id()); return x * 3 + 1; }
extern "C" int n_pure_threads(void)   { return (int)pure_ids.size(); }
extern "C" int n_impure_threads(void) { return (int)impure_ids.size(); }
