// T9: a reference FIFO model in C++ (std::deque) behind a chandle. Bounded depth; push on a
// full FIFO and pop on an empty one are rejected and reported through the return value.
#include <deque>
#include <stdint.h>
struct Fifo { std::deque<uint32_t> q; int depth; };
static Fifo* F(void* p) { return static_cast<Fifo*>(p); }
extern "C" {
void* fifo_new(int depth)              { return new Fifo{{}, depth}; }
void  fifo_delete(void* f)             { delete F(f); }
int   fifo_push(void* f, uint32_t v)   { if ((int)F(f)->q.size() >= F(f)->depth) return 0; F(f)->q.push_back(v); return 1; }
int   fifo_pop(void* f, uint32_t* v)   { if (F(f)->q.empty()) return 0; *v = F(f)->q.front(); F(f)->q.pop_front(); return 1; }
int   fifo_size(void* f)               { return (int)F(f)->q.size(); }
}
