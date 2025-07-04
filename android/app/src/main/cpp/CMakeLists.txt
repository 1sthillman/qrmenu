cmake_minimum_required(VERSION 3.10)
project(native_compute LANGUAGES CXX)

add_library(
    native_compute SHARED
    native_compute.cpp
)

find_library(log-lib log)

target_link_libraries(
    native_compute
    ${log-lib}
) 