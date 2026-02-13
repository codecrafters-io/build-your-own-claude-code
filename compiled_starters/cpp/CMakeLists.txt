cmake_minimum_required(VERSION 3.13)

project(codecrafters-claude-code)

set(CMAKE_CXX_STANDARD 23) # Enable the C++23 standard

file(GLOB_RECURSE SOURCE_FILES src/*.cpp src/*.hpp)

find_package(cpr CONFIG REQUIRED)
find_package(nlohmann_json CONFIG REQUIRED)

add_executable(claude-code ${SOURCE_FILES})

target_link_libraries(claude-code PRIVATE cpr::cpr nlohmann_json::nlohmann_json)