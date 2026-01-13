@echo off
REM End-to-end clang-cl PGO script. Requires clang-cl and llvm-profdata on PATH.

REM -------------------------
REM Instrumentation build (compile + link)
REM -------------------------
REM NOTE: clang-cl follows MSVC-style options. Use /Fo:filename (no space) or /Fofilename.
clang-cl /std:c++17 /O2 /Zi -fprofile-instr-generate -c main.cpp /Fo:main.obj
if errorlevel 1 goto :err
clang-cl /std:c++17 /O2 /Zi -fprofile-instr-generate -c foo.cpp /Fo:foo.obj
if errorlevel 1 goto :err

REM Link instrumented executable (ensure instrumentation runtime is linked)
clang-cl -fprofile-instr-generate main.obj foo.obj /Fe:myapp_instr.exe
if errorlevel 1 goto :err

REM -------------------------
REM Run instrumented executable to generate .profraw files
REM -------------------------
REM Use %p to include the process id in filenames so runs don't clobber each other
set LLVM_PROFILE_FILE=myapp-%p.profraw

echo Running instrumented binary (run 1)...
myapp_instr.exe 1000000
echo Running instrumented binary (run 2)...
myapp_instr.exe 500000

REM -------------------------
REM Merge .profraw files into merged.profdata
REM -------------------------
echo Merging .profraw files...
llvm-profdata merge -o merged.profdata myapp-*.profraw
if errorlevel 1 goto :err

REM Optional: inspect merged profile
llvm-profdata show merged.profdata

REM -------------------------
REM PGO use phase (recompile objects using merged profile and link)
REM -------------------------
echo Building PGO-enabled objects...
REM Use /Fo:filename (no space) or -o with -c; do NOT pass unrecognized MSVC flags with spaces
clang-cl /std:c++17 /O2 /Zi -fprofile-instr-use=merged.profdata -c main.cpp /Fo:main_pgo.obj
if errorlevel 1 goto :err
clang-cl /std:c++17 /O2 /Zi -fprofile-instr-use=merged.profdata -c foo.cpp /Fo:foo_pgo.obj
if errorlevel 1 goto :err

REM Link final executable (including -fprofile-instr-use is harmless)
clang-cl -fprofile-instr-use=merged.profdata main_pgo.obj foo_pgo.obj /Fe:myapp_pgo.exe
if errorlevel 1 goto :err

REM Run optimized binary
echo Running PGO-optimized binary...
myapp_pgo.exe 1000000

REM Cleanup generated raw profiles (optional)
del myapp-*.profraw

echo Done.
goto :eof

:err
echo ERROR encountered. Exiting.
exit /b 1