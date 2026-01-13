@echo off
REM A simple end-to-end PGO script (cmd) using clang++ and llvm-profdata on PATH.

REM Instrumentation build (compile + link)
clang++ -std=c++17 -O2 -g -fprofile-instr-generate -c main.cpp -o main.obj
if errorlevel 1 goto :err
clang++ -std=c++17 -O2 -g -fprofile-instr-generate -c foo.cpp -o foo.obj
if errorlevel 1 goto :err
clang++ -fprofile-instr-generate main.obj foo.obj -o myapp_instr.exe
if errorlevel 1 goto :err

REM Set profile output pattern (cmd) - %p = PID
set LLVM_PROFILE_FILE=myapp-%p.profraw

REM Run representative workloads (produce .profraw files)
echo Running instrumented binary (run 1)...
myapp_instr.exe 1000000
echo Running instrumented binary (run 2)...
myapp_instr.exe 500000

REM Merge .profraw files into merged.profdata
echo Merging .profraw files...
llvm-profdata merge -o merged.profdata myapp-*.profraw
if errorlevel 1 goto :err

REM (Optional) Inspect merged profile
llvm-profdata show merged.profdata

REM PGO use phase (recompile objects using merged.profdata, then link)
echo Building PGO-enabled objects...
clang++ -std=c++17 -O3 -g -fprofile-instr-use=merged.profdata -c main.cpp -o main_pgo.obj
if errorlevel 1 goto :err
clang++ -std=c++17 -O3 -g -fprofile-instr-use=merged.profdata -c foo.cpp -o foo_pgo.obj
if errorlevel 1 goto :err
clang++ -fprofile-instr-use=merged.profdata main_pgo.obj foo_pgo.obj -o myapp_pgo.exe
if errorlevel 1 goto :err

REM Run optimized binary
echo Running PGO-optimized binary...
myapp_pgo.exe 1000000

REM Optional: delete raw profile files
del myapp-*.profraw

echo Done.
goto :eof

:err
echo ERROR encountered. Exiting.
exit /b 1