#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp> 
#include <glm/gtc/type_ptr.hpp>
#include "Shader.h"
#include <iostream>
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

float intensity_value;


glm::vec3 camera_pos;
glm::vec3 light_pos = glm::vec3(0,0,0);
void mouseCallback(GLFWwindow* window, double xpos, double ypos);
void framebuffer_size_callback(GLFWwindow* window, int width, int height);
void processInput(GLFWwindow* window);

// settings
const unsigned int SCR_WIDTH = 800;
const unsigned int SCR_HEIGHT = 600;
glm::vec4 mouse_pos = glm::vec4(0);
std::string fragmentShaderPath = std::string(SHADER_DIR) + "/ray_marching.glsl";
std::string VertexShaderPath   = std::string(SHADER_DIR) + "/Vertex.glsl";

float Color_value = 0;


int main()
{
    // glfw: initialize and configure
    // ------------------------------
    glfwInit();
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

#ifdef __APPLE__
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
#endif

    // glfw window creation
    // --------------------
    GLFWwindow* window = glfwCreateWindow(SCR_WIDTH, SCR_HEIGHT, "Ray Marching", NULL, NULL);
    if (window == NULL)
    {
        std::cout << "Failed to create GLFW window" << std::endl;
        glfwTerminate();
        return -1;
    }
    glfwMakeContextCurrent(window);
    glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);

    // glad: load all OpenGL function pointers
    // ---------------------------------------
    if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress))
    {
        std::cout << "Failed to initialize GLAD" << std::endl;
        return -1;
    }

    // build and compile our shader program
    // ------------------------------------
    Shader myshader(VertexShaderPath, fragmentShaderPath);


    float tri_vertices[] = {
        -1.0f, -1.0f, 0.0f,  // bottom-left corner
        3.0f, -1.0f, 0.0f,   // bottom-right corner
        -1.0f, 3.0f, 0.0f    // top-left corner
    };


 unsigned int tri_indices[] = { 0, 1, 2 }; // Indices for a single triangle


 // Seems like there is something with the textures wil be sure to fix Later ;
float vertices[] = {
    // positions        // texture coords
    -1.0f,  1.0f, 0.0f,  0.0f, 1.0f, // top left
    -1.0f, -1.0f, 0.0f,  0.0f, 0.0f, // bottom left
     1.0f, -1.0f, 0.0f,  1.0f, 0.0f, // bottom right

    -1.0f,  1.0f, 0.0f,  0.0f, 1.0f, // top left
     1.0f, -1.0f, 0.0f,  1.0f, 0.0f, // bottom right
     1.0f,  1.0f, 0.0f,  1.0f, 1.0f  // top right
};


    // set up vertex data (and buffer(s)) and configure vertex attributes
    // ------------------------------------------------------------------
    unsigned int indices[] = {
    0, 1, 3,
    1, 2, 3  
    };



    unsigned int VBO, VAO, EBO;
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);
    glGenBuffers(1, &EBO);
    // bind the Vertex Array Object first, then bind and set vertex buffer(s), and then configure vertex attributes(s).
    glBindVertexArray(VAO);

    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(tri_vertices), tri_vertices, GL_STATIC_DRAW);

    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(tri_indices), tri_indices, GL_STATIC_DRAW);

    // position attribute
    // position attribute
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);
    // texture coord attribute
   // glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)(3 * sizeof(float)));
    //glEnableVertexAttribArray(1);


    unsigned int texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture); // all upcoming GL_TEXTURE_2D operations now have effect on this texture object
    // set the texture wrapping parameters
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);	// set texture wrapping to GL_REPEAT (default wrapping method)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    // set texture filtering parameters
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    // load image, create texture and generate mipmaps
    int width, height, nrChannels;
    // The FileSystem::getPath(...) is part of the GitHub repository so we can find files on any IDE/platform; replace it with your own image path.
    stbi_set_flip_vertically_on_load(true);
    //const char* image = SHADER_DIR"/wall.jpg";
    unsigned char* data = stbi_load(SHADER_DIR"/wall.jpg", &width, &height, &nrChannels, 0);
    if (data)
    {
        std::cout << "Type shit!@!  \n ";
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, data);
        glGenerateMipmap(GL_TEXTURE_2D);
    }
    else
    {
        std::cout << "Failed to load texture" << std::endl;
    }
    stbi_image_free(data);

    // Setting up Camera
    camera_pos = glm::vec3{0.0f,0.0f,-2.0f};
    // render loop
    while (!glfwWindowShouldClose(window))
    {
        float get_time = glfwGetTime();
        glm::vec2 screen_resolution;
        glm::vec4 background_color = glm::vec4{ 0.0f,0.0f,0.0f,0.0f };

        screen_resolution.x = SCR_WIDTH;
        screen_resolution.y = SCR_HEIGHT;
        
        // input
        // -----
        processInput(window);
        glfwPollEvents();
        glfwSetCursorPosCallback(window, mouseCallback);

        // render
        // ------
        glClearColor(background_color.x,background_color.y,background_color.x,background_color.z);
        glClear(GL_COLOR_BUFFER_BIT);

        // bind textures on corresponding texture units
        
  
        // activate shader
        myshader.use();

        // render container

        myshader.setFloat("time",get_time);
        myshader.setFloat("inten_value",intensity_value);
        myshader.setVec2("resolution",screen_resolution);
        myshader.setVec3("camera", camera_pos);
        myshader.setVec4("Back_ground_color", background_color);
        myshader.setVec2("iMouse", mouse_pos);
        myshader.setVec3("Light_direction",light_pos);

    light_pos = glm::vec3(sin(get_time) * 2,0,0);
    
        glBindVertexArray(VAO);
        glDrawElements(GL_TRIANGLES, 3, GL_UNSIGNED_INT, 0);

        // glfw: swap buffers and poll IO events (keys pressed/released, mouse moved etc.)
        // -------------------------------------------------------------------------------
        glfwSwapBuffers(window);
        
    }

    // optional: de-allocate all resources once they've outlived their purpose:
    // ------------------------------------------------------------------------
    glDeleteVertexArrays(1, &VAO);
    glDeleteBuffers(1, &VBO);
    glDeleteBuffers(1, &EBO);

    // glfw: terminate, clearing all previously allocated GLFW resources.
    // ------------------------------------------------------------------

    processInput(window);
    glfwTerminate();
    return 0;
}

// process all input: query GLFW whether relevant keys are pressed/released this frame and react accordingly
// ---------------------------------------------------------------------------------------------------------
void processInput(GLFWwindow* window)
{
    if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
        glfwSetWindowShouldClose(window, true);
    if (glfwGetKey(window, GLFW_KEY_1) == GLFW_PRESS) {
        Color_value = 0;
    }
    if (glfwGetKey(window, GLFW_KEY_W) == GLFW_PRESS) {

    }
}


void mouseCallback(GLFWwindow* window, double xpos, double ypos) {
    // Do something with the mouse position
    // Example: Print mouse coordinates
    //std::cout << "Mouse position: " << xpos << ", " << ypos << std::endl;

    mouse_pos.x = xpos;
    mouse_pos.y = ypos;

    std::cout << "Mouse Position_x: " << mouse_pos.x << std::endl;
    std::cout << "Mouse Position_y: " << light_pos.x << std::endl;


    std::cout << intensity_value << std::endl;
}



// glfw: whenever the window size changed (by OS or user resize) this callback function executes
// ---------------------------------------------------------------------------------------------
void framebuffer_size_callback(GLFWwindow* window, int width, int height)
{
    // make sure the viewport matches the new window dimensions; note that width and 
    // height will be significantly larger than specified on retina displays.
    glViewport(0, 0, width, height);
}