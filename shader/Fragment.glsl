#version 410 core


//in vec3 ourPosition;
//uniform float Color_value;


out vec4 FragColor;

in vec3 Ourcolor;
in vec2 texCoord;
uniform sampler2D MyTexture;


void main()
{
    //Ourcolor = vec3(1.0,1.0,0.0);
    FragColor = texture(MyTexture, texCoord);   // note how the position value is linearly interpolated to get all the different colors
}







