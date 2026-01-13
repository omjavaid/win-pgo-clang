#include <iostream>
#include <string> // for std::stoi
#include "foo.h"

int main(int argc, char **argv) {
  int runs = 1000000;
  if (argc > 1) runs = std::stoi(argv[1]);
  for (int i = 0; i < runs; ++i) foo(i % 10);
  std::cout << "done\n";
  return 0;
}