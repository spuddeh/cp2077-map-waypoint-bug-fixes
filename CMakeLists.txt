cmake_minimum_required(VERSION 3.21)
project(MapWaypointBugFixes LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(MapWaypointBugFixes SHARED plugin/src/Main.cpp)

# RED4ext.SDK is header-only. It defaults to the workspace's read-only reference mirror, which is
# included and never built from; anyone else points RED4EXT_SDK_DIR at their own checkout.
set(RED4EXT_SDK_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../_source/RED4ext.SDK" CACHE PATH "RED4ext.SDK checkout")
target_include_directories(MapWaypointBugFixes PRIVATE "${RED4EXT_SDK_DIR}/include")

target_compile_definitions(MapWaypointBugFixes PRIVATE WIN32_LEAN_AND_MEAN NOMINMAX _CRT_SECURE_NO_WARNINGS)
if(MSVC)
    target_compile_options(MapWaypointBugFixes PRIVATE /utf-8)
endif()
