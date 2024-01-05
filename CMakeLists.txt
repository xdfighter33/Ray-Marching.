# CMakeList.txt : CMake project for Ray Marching, include source and define
# project specific logic here.
#
cmake_minimum_required (VERSION 3.20)

project ("Ray_Marching")
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
# Add source to this project's executable.

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

include(FetchContent)
Set(FETCHCONTENT_QUIET FALSE)

FetchContent_Declare(
        glfw
        GIT_REPOSITORY https://github.com/glfw/glfw.git
        GIT_TAG 3.3.5
)
FetchContent_MakeAvailable(glfw)
include_directories(${glfw_SOURCE_DIR}/include)

FetchContent_Declare(
        glad
        GIT_REPOSITORY https://github.com/Dav1dde/glad.git
        GIT_TAG v0.1.34
)
FetchContent_MakeAvailable(glad)
include_directories(${glad_SOURCE_DIR}/include)


add_executable (Ray_Marching "src/Ray Marching.cpp" "src/Ray Marching.h" "src/Shader.h")

file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/shader DESTINATION ${CMAKE_CURRENT_BINARY_DIR})

get_filename_component(shader_ABSOLUTE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/shader" ABSOLUTE)


target_compile_definitions(Ray_Marching PRIVATE shader_DIR="${shader_ABSOLUTE_PATH}")


target_link_libraries(Ray_Marching glfw glad)

# TODO: Add tests and install targets if needed.
