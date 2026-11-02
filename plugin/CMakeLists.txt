cmake_minimum_required(VERSION 3.21)
project(MapWaypointBugFixes LANGUAGES CXX)

include(red4ext-plugin.cmake)

add_library(MapWaypointBugFixes SHARED src/Main.cpp)
red4ext_plugin(MapWaypointBugFixes)
