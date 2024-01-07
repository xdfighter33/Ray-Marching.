/*#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include "Shader.h"
#include <iostream>

// Function calls 
void framebuffer_size_callback(GLFWwindow* window, int width, int height);
void processInput(GLFWwindow* window);


// Variables 
const unsigned int screen_height = 800;
const unsigned int screen_width = 800;

std::string RMarching_shader = std::string(SHADER_DIR) + "/ray_marching.glsl";

int main(){

glfwInit();
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

#ifdef __APPLE__
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
#endif


    GLFWwindow* window = glfwCreateWindow(SCR_WIDTH, SCR_HEIGHT, "Ray Marching", NULL, NULL);
    if (window == NULL)
    {
        std::cout << "Failed to create GLFW window" << std::endl;
        glfwTerminate();
        return -1;
    }
    glfwMakeContextCurrent(window);
    glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);


    if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress))
    {
        std::cout << "Failed to initialize GLAD" << std::endl;
        return -1;
    }

    unsigned int 

}
void processInput(GLFWwindow* window)
{
    if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
        glfwSetWindowShouldClose(window, true);
   // if (glfwGetKey(window, GLFW_KEY_1) == GLFW_PRESS) {
     //   Color_value = 0;
    //}
}


*/
