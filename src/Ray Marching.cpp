#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <glm/glm.hpp>
#include "imgui.h"
#include <backends/imgui_impl_glfw.h>
#include <backends/imgui_impl_opengl3.h>
#define GL_SILENCE_DEPRECATION
#if defined(IMGUI_IMPL_OPENGL_ES2)
#endif
#include <glm/gtc/matrix_transform.hpp> 
#include <glm/gtc/type_ptr.hpp>
#include "Shader.h"
#include <iostream>
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

float intensity_value;

#if defined(_MSC_VER) && (_MSC_VER >= 1900) && !defined(IMGUI_DISABLE_WIN32_FUNCTIONS)
#pragma comment(lib, "legacy_stdio_definitions")
#endif


glm::vec3 door_cords;
glm::vec3 camera_pos;
glm::vec3 Light_pos;
glm::vec3 sky_light_pos;
glm::vec3 global_light_pos;
float test_check;
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


int main(){
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


    // ImGui Initalize and configure 
    // -----------------------------

#if defined(__APPLE__)
    // GL 3.2 + GLSL 330
    const char* glsl_version = "#version 150";
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 2);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);  // 3.2+ only
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);            // Required on Mac

#else
// GL 3. + GLSL 130
    const char* glsl_version = "#version 400";
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);  // 3.2+ only
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);            // 3.0+ only
#endif


IMGUI_CHECKVERSION();
ImGui::CreateContext();
ImGuiIO& test = ImGui::GetIO(); (void) test;
test.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
ImGui::StyleColorsDark();





    // ImGui: load all IMGUI funtions
    // ----------------------------

       test.Fonts->AddFontDefault();

        ImGui_ImplGlfw_InitForOpenGL(window, true);

        ImGui_ImplOpenGL3_Init(glsl_version);
     




    bool show_test_window = true;
    bool show_another_window = true;
    ImVec4 test_color = ImVec4(1.0,0.0,0.0,1.0);



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
    camera_pos = glm::vec3{0.0f,0.0f,-15.0f};
    float light_pos[3] = { 0,0,-25.0};
    float skylight_pos[3] = { 0 };
    float global_light[3] = {0};
    float test_slider_values[3] = { 0 };
    // render loop
    while (!glfwWindowShouldClose(window))
    {





        //IMGUI FRAME SETUP

        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();

        //ImGui varible_setup
 
        //ImGui Window Setup
        glm::vec3 sphere_cords;
        if (show_test_window)
        {


            ImGui::Begin("Light Config");
            ImGui::Text("Light_1");
            ImGui::SliderFloat("Sphere x", &light_pos[0], -5.0f, 5.0f);
            ImGui::SliderFloat("Sphere y", &light_pos[1], -5.0f, 5.0f);
            ImGui::SliderFloat("Sphere z", &light_pos[2], -50.0f, 50.0f);
            ImGui::Text("Isac's test variable");
            ImGui::SliderFloat("Isac's test variable.x", &skylight_pos[0], -50, 50);
            ImGui::SliderFloat("Isac's test variable.y", &skylight_pos[1], -50, 50);
            ImGui::SliderFloat("Isac's test variable.z", &skylight_pos[2], -50, 50);
            ImGui::Text("Light_3");
            ImGui::SliderFloat("global_light x", &global_light[0], -5, 5);
            ImGui::SliderFloat("global_light y", &global_light[1], -5, 5);
            ImGui::SliderFloat("global_light z", &global_light[2], -5, 5);
            ImGui::Text("This is some useful text.");
            ImGui::Checkbox("Demo Window", &show_test_window);

            // Update variables after ImGui window interaction
            camera_pos = glm::vec3((float)light_pos[0], light_pos[1], light_pos[2]);
            sky_light_pos = glm::vec3(skylight_pos[0], skylight_pos[1], skylight_pos[2]);
            door_cords = glm::vec3(global_light[0], global_light[1], global_light[2]);
            test_check = global_light[2];
            ImGui::End();
        }
         
        float get_time = glfwGetTime();
        glm::vec2 screen_resolution;
        glm::vec4 background_color = glm::vec4{ 1.0f,1.0f,1.0f,1.0f };

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

   //global_light_pos = glm::vec3(0,-10,0);
   //Light_pos = glm::vec3(sin(get_time) * -9,-1.75,cos(get_time) * 9);

       // Light_pos = glm::vec3(0, 0, 0);

    //sky_light_pos = glm::vec3(2.5,-1,sin(get_time) * 2);
   // camera_pos = glm::vec3(0,0,-5);



        myshader.setFloat("time",get_time);
        myshader.setFloat("inten_value",intensity_value);
        myshader.setVec2("resolution",screen_resolution);
        myshader.setVec3("camera", camera_pos);
        myshader.setVec3("Global_light", global_light_pos);
        myshader.setVec3("sky_light_direction",sky_light_pos);
        myshader.setVec4("Back_ground_color", background_color);
        myshader.setVec3("sphere_cords", sphere_cords);
        myshader.setVec2("iMouse", mouse_pos);
        myshader.setVec3("Light_direction",Light_pos);
        myshader.setVec3("door_cords",door_cords);
        myshader.setFloat("test_variable", test_check);
        //ImGui Render
        ImGui::Render();
    
        glBindVertexArray(VAO);
        glDrawElements(GL_TRIANGLES, 3, GL_UNSIGNED_INT, 0);
        ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData()); 
        // glfw: swap buffers and poll IO events (keys pressed/released, mouse moved etc.)
        // -------------------------------------------------------------------------------
        glfwSwapBuffers(window);
        
    }


    //Delete ImGui resources
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();

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
    ImGuiIO& io = ImGui::GetIO();
    io.MousePos = ImVec2((float)xpos, ((float)ypos));
    mouse_pos.x = xpos;
    mouse_pos.y = ypos;

 //   std::cout << "Mouse Position_x: " << mouse_pos.x << std::endl;
   // std::cout << "Sky light  Position_Z: " << sky_light_pos.y << std::endl;

//    std::cout << intensity_value << std::endl;
}



// glfw: whenever the window size changed (by OS or user resize) this callback function executes
// ---------------------------------------------------------------------------------------------
void framebuffer_size_callback(GLFWwindow* window, int width, int height)
{
    // make sure the viewport matches the new window dimensions; note that width and 
    // height will be significantly larger than specified on retina displays.
    glViewport(0, 0, width, height);
}