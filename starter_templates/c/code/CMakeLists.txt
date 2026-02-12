cmake_minimum_required(VERSION 3.13)

project(codecrafters-claude-code)

file(GLOB_RECURSE SOURCE_FILES src/*.c src/*.h)

set(CMAKE_C_STANDARD 23) # Enable the C23 standard

find_package(CURL REQUIRED)
find_package(cJSON REQUIRED)

add_executable(claude-code ${SOURCE_FILES})
target_link_libraries(claude-code PRIVATE CURL::libcurl cjson::cjson)
