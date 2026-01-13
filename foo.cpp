#include "foo.h"

void foo(int x) {
  if (x < 3) {
    // hot path
    volatile int y = x * 2;
    (void)y;
  } else {
    // cold path
    volatile int y = x * 3;
    (void)y;
  }
}