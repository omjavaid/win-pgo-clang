# LLVM/Clang Instrumentation PGO Examples (Windows)

A small, focused collection of examples that demonstrate instrumentation-based Profile-Guided Optimization (PGO) on Windows using LLVM/Clang.

This repository includes two end-to-end command scripts:
- `run_pgo.cmd` — example using the Unix-style `clang++` frontend.
- `run_pgo_cl.cmd` — example using the MSVC-compatible `clang-cl` frontend.

Table of contents
- Purpose
- What’s included
- Requirements
- Quickstart
  - clang++ (clang++) example
  - clang-cl (MSVC-like) example
- Important snippets & gotchas
- Validating profiles
- Troubleshooting
- Notes & recommendations

Purpose
-------
Show the minimal steps and command patterns for:
1. Instrumenting a build to generate raw profile data (`.profraw`).
2. Running the instrumented binary to produce profile samples.
3. Merging raw profiles into `.profdata`.
4. Using the `.profdata` to produce an optimized rebuild.

What’s included
---------------
- `main.cpp`, `foo.cpp`, `foo.h` — example program that contains hot and cold code paths.
- `run_pgo.cmd` — end-to-end script that uses `clang++` and `llvm-profdata`.
- `run_pgo_cl.cmd` — end-to-end script that uses `clang-cl` and `llvm-profdata`.

Requirements
------------
- Windows (cmd.exe examples)
- clang/clang++ or clang-cl on PATH
- llvm-profdata on PATH
- Consistent clang/LLVM versions between instrumented and PGO builds

Quickstart
----------
Prerequisites:
1. Ensure `clang++`/`clang-cl` and `llvm-profdata` are available on PATH.
2. Open a Developer Command Prompt if you rely on MSVC environment variables when using `clang-cl`.

clang++ (clang++) example
1. Instrumented compile:
   ```
   clang++ -std=c++17 -O2 -g -fprofile-instr-generate -c foo.cpp -o foo.obj
   ```
2. Link instrumented binary (example):
   ```
   clang++ -std=c++17 -O2 -g -fprofile-instr-generate foo.obj main.obj -o myapp.exe
   ```
3. Run instrumented binary to produce `.profraw` files (the script uses `%p` to include PID):
   ```
   set LLVM_PROFILE_FILE=myapp-%p.profraw
   myapp.exe
   ```
4. Merge raw profiles:
   ```
   llvm-profdata merge -output=merged.profdata *.profraw
   ```
5. Rebuild using profile data:
   ```
   clang++ -std=c++17 -O2 -g -fprofile-instr-use=merged.profdata ... -o myapp_pgo.exe
   ```

clang-cl (MSVC-compatible) example
1. Instrumented compile with clang-cl:
   ```
   clang-cl /std:c++17 /O2 /Zi /fprofile-instr-generate -c main.cpp /Fo:main.obj
   ```
   Note: use MSVC-style flags such as `/O2` or `/Ox` with clang-cl.
2. Link (prefer using `clang-cl` to simplify linking):
   ```
   clang-cl /std:c++17 /O2 /Zi /fprofile-instr-generate main.obj foo.obj /Fe:myapp.exe
   ```
3. Run instrumented binary, merge profiles, and rebuild using:
   ```
   set LLVM_PROFILE_FILE=myapp-%p.profraw
   myapp.exe
   llvm-profdata merge -output=merged.profdata *.profraw
   clang-cl /std:c++17 /O2 /Zi /fprofile-instr-use=merged.profdata main.cpp foo.cpp /Fe:myapp_pgo.exe
   ```

Important snippets & gotchas
---------------------------
- Pattern used for profile files (cmd):
  ```
  set LLVM_PROFILE_FILE=myapp-%p.profraw
  ```
  `%p` inserts the process id so multiple runs produce separate files and avoid clobbering.

- Example clang++ compile (cmd):
  ```
  clang++ -std=c++17 -O2 -g -fprofile-instr-generate -c foo.cpp -o foo.obj
  ```

- Example problematic clang-cl line (do NOT use a space after `/Fo`):
  ```
  clang-cl -std:c++17 /O3 /Zi -fprofile-instr-use=merged.profdata -c main.cpp -Fo main_pgo.obj
  if errorlevel 1 goto :err
  ```
  Why this is problematic:
  - `/O3` is not a recognized MSVC-style optimization flag for `clang-cl` (use `/O2` or `/Ox`).
  - `/Fo` must not be followed by a space; using a space makes the filename be interpreted as an input file and prevents object creation.

- Correct `clang-cl` usage (no space after `/Fo:`):
  ```
  clang-cl /std:c++17 /O2 /Zi /fprofile-instr-use=merged.profdata -c main.cpp /Fo:main_pgo.obj
  ```
  Alternatively, you can use `-o filename -c` with clang-cl, but when mixing MSVC-style flags prefer `/Fo:`.

Validating profiles
-------------------
Before rebuilding with the profile data, inspect the merged profile:
```
llvm-profdata show merged.profdata
```
This helps confirm that the profile contains expected functions and data.

Troubleshooting
---------------
- No `.profraw` files produced:
  - Ensure the instrumented binary ran to completion and was able to write files.
  - Check `LLVM_PROFILE_FILE` is set and writable in the working directory.
- Link failures when using link.exe:
  - If you must use Microsoft `link.exe` directly, you may need to add LLVM profile runtime libs manually. Using `clang-cl` for linking is simpler as it ensures the right runtime is included.
- Inconsistent optimizations:
  - Use the same compiler/LLVM version for instrumenting and for the PGO rebuild. Differences can make profiles incompatible.

Notes & recommendations
-----------------------
- Keep clang/LLVM versions consistent between the instrument and PGO builds.
- Use `%p` in `LLVM_PROFILE_FILE` to prevent raw profile file clobbering when running multiple processes.
- Use `llvm-profdata show` to validate the content of the merged profile before rebuilding.
- Prefer `clang-cl` for linking when building Windows PGO workflows to avoid manually managing LLVM runtime libraries.

If you want additional examples (PowerShell versions, MSBuild integration, or CI examples), open an issue or submit a PR with the scenario you need.
