```markdown
# LLVM/Clang Instrumentation PGO Examples (Windows)

This repository contains minimal examples demonstrating instrumentation-based PGO using:
- clang++ (Unix-style frontend) via `run_pgo.cmd`
- clang-cl (MSVC-compatible frontend) via `run_pgo_cl.cmd`

Files
- `main.cpp`, `foo.cpp`, `foo.h` — example program with a hot/cold path.
- `run_pgo.cmd` — end-to-end cmd script using `clang++` and `llvm-profdata`.
- `run_pgo_cl.cmd` — end-to-end cmd script using `clang-cl` and `llvm-profdata`.

Important snippets (examples)
- Pattern used for profile files (cmd):
  ```
  set LLVM_PROFILE_FILE=myapp-%p.profraw
  ```
  (%p inserts the process id so multiple runs produce separate files.)

- Example clang++ compile of foo.cpp (cmd):
  ```
  clang++ -std=c++17 -O2 -g -fprofile-instr-generate -c foo.cpp -o foo.obj
  ```

- Example problematic clang-cl line (do NOT use space after /Fo):
  ```
  clang-cl -std:c++17 /O3 /Zi -fprofile-instr-use=merged.profdata -c main.cpp -Fo main_pgo.obj
  if errorlevel 1 goto :err
  ```
  This is incorrect because (a) `/O3` is not a recognized MSVC flag for clang-cl, and (b) `/Fo` must not be followed by a space. See corrected examples below.

What was updated and why
- Fixed the `clang-cl` compilation flags and output specification:
  - Use MSVC-style optimization `/O2` (or `/Ox`) with clang-cl instead of `/O3`.
  - Use `/Fo:filename` (no space) or `/Fo<filename>` to specify object output — using a space makes the filename be interpreted as an input file and prevents object creation.
  - Alternatively clang-cl supports `-o filename -c`, but when using MSVC-style options prefer `/Fo:`.
- `run_pgo_cl.cmd` now uses `/Fo:...` and `/O2` and keeps `/Zi` for debug info.
- `run_pgo.cmd` (clang++) is kept and uses `-o` for objects and final binaries.

Quick usage (cmd.exe)
1. Ensure `clang++`/`clang-cl` and `llvm-profdata` are on PATH.
2. For clang++ variant:
   ```
   run_pgo.cmd
   ```
3. For clang-cl variant:
   ```
   run_pgo_cl.cmd
   ```

Notes and reminders
- Keep clang/llvm versions consistent between instrument and PGO builds.
- Ensure instrumented runs complete successfully so `.profraw` files are written.
- Use `llvm-profdata show merged.profdata` to validate merged profile content before rebuilding.
- Use `%p` in `LLVM_PROFILE_FILE` to prevent file clobbering.
- If you want to use link.exe or MSVC linker directly, be aware you may need to add LLVM profile runtime libs manually; using `clang-cl` for linking is simplest.

```
