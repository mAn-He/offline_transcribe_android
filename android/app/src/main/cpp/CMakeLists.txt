cmake_minimum_required(VERSION 3.22)
project(whisper_ffi)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library( # Name of the library.
             whisper_ffi
             SHARED
             whisper_c_api.cpp)

# Include whisper sources (vendored)
add_subdirectory(whisper)

# Link libraries
find_library(log-lib log)

# Include dirs
target_include_directories(whisper_ffi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/whisper)

# Link against whisper core
target_link_libraries(whisper_ffi whisper ${log-lib})
