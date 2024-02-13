cmake_minimum_required(VERSION 3.20)
project(Ray_Marching)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add source to this project's executable
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# Fetch GLFW
include(FetchContent)
FetchContent_Declare(
    glfw
    GIT_REPOSITORY https://github.com/glfw/glfw.git
    GIT_TAG 3.3.5
)
FetchContent_MakeAvailable(glfw)

# Fetch GLAD
FetchContent_Declare(
    glad
    GIT_REPOSITORY https://github.com/Dav1dde/glad.git
    GIT_TAG v0.1.34
)
FetchContent_MakeAvailable(glad)

# Fetch GLM
FetchContent_Declare(
    glm
    GIT_REPOSITORY https://github.com/g-truc/glm.git
    GIT_TAG bf71a834948186f4097caa076cd2663c69a10e1e
)
FetchContent_MakeAvailable(glm)

# Fetch ImGui
FetchContent_Declare(
    imgui
    GIT_REPOSITORY https://github.com/ocornut/imgui.git
    GIT_TAG master
)
FetchContent_MakeAvailable(imgui)

# Add an executable
add_executable(Ray_Marching 
    "src/Ray Marching.cpp" 
    "src/Ray Marching.h" 
    "src/Shader.h" 
    "src/stb_image.h" 
    "src/main.cpp"
)

# Include ImGui
target_include_directories(Ray_Marching PRIVATE 
    ${imgui_SOURCE_DIR} # Include directory containing imgui.h
    ${imgui_SOURCE_DIR}/backends # Include directory containing backends (if needed)
)

# Add ImGui source files to the target
target_sources(Ray_Marching PRIVATE
    ${imgui_SOURCE_DIR}/imgui.cpp
    ${imgui_SOURCE_DIR}/imgui_tables.cpp 
    ${imgui_SOURCE_DIR}/imgui_demo.cpp 
    ${imgui_SOURCE_DIR}/imgui_widgets.cpp
    ${imgui_SOURCE_DIR}/imgui_draw.cpp
    ${imgui_SOURCE_DIR}/imgui_widgets.cpp
    ${imgui_SOURCE_DIR}/backends/imgui_impl_glfw.cpp
    ${imgui_SOURCE_DIR}/backends/imgui_impl_opengl3.cpp
)

# Copy shader files to the build directory
file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/SHADER DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
get_filename_component(SHADER_ABSOLUTE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/SHADER" ABSOLUTE)
target_compile_definitions(Ray_Marching PRIVATE SHADER_DIR="${SHADER_ABSOLUTE_PATH}")

# Link libraries
target_link_libraries(Ray_Marching PRIVATE glfw glad glm)
