cmake_minimum_required (VERSION 3.20)
project ("Ray_Marching")
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add source to this project's executable.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

include(FetchContent)
Set(FETCHCONTENT_QUIET FALSE)

# Fetch GLFW
FetchContent_Declare(
        glfw
        GIT_REPOSITORY https://github.com/glfw/glfw.git
        GIT_TAG 3.3.5
)
FetchContent_MakeAvailable(glfw)
include_directories(${glfw_SOURCE_DIR}/include)

# Fetch GLAD
FetchContent_Declare(
        glad
        GIT_REPOSITORY https://github.com/Dav1dde/glad.git
        GIT_TAG v0.1.34
)
FetchContent_MakeAvailable(glad)
include_directories(${glad_SOURCE_DIR}/include)


FetchContent_Declare(
        glm
        GIT_REPOSITORY https://github.com/g-truc/glm
        GIT_TAG master
)
FetchContent_MakeAvailable(glm)



include_directories(${glm_SOURCE_DIR}/include)

# Add an executable
add_executable (Ray_Marching "src/Ray Marching.cpp" "src/Ray Marching.h" "src/Shader.h" "src/stb_image.h")

# Copy shader files to the build directory
file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/SHADER DESTINATION ${CMAKE_CURRENT_BINARY_DIR})

get_filename_component(SHADER_ABSOLUTE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/SHADER" ABSOLUTE)

target_compile_definitions(Ray_Marching PRIVATE SHADER_DIR="${SHADER_ABSOLUTE_PATH}")

# Link libraries
target_link_libraries(Ray_Marching glfw glad glm)
