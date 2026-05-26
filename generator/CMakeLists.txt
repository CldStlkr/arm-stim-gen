cmake_minimum_required(VERSION 3.16)
project(arm_stim_gen)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(stim_gen
    src/main.cpp
    src/state.cpp
    src/prologue.cpp
    src/emitters/mov_imm.cpp
    src/emitters/alu_reg_reg.cpp
    src/emitters/ldr_reg.cpp
    src/emitters/str_reg.cpp
    src/emitters/forwarding_alu.cpp
    src/emitters/load_use.cpp
    src/emitters/store_to_load.cpp
    src/emitters/branch_skip.cpp
    src/emitters/cache_line_split.cpp
)

target_include_directories(stim_gen PRIVATE src)
target_compile_options(stim_gen PRIVATE -Wall -Wextra)
