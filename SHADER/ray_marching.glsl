#version 410 core

out vec4 FragColor;

uniform vec2 resolution;
uniform float time;

float sdf(vec3 p){
    return length(p) - 1.0;
}

void main(){
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;

    uv.x *= resolution.x / resolution.y;
    uv.y *= resolution.x / resolution.y;

    vec3 camPos = vec3(-2.5, -1.5, -3.0); // Camera position
    vec3 rayDir = normalize(vec3(uv, 2.0)); // Ray direction

    const int maxSteps = 100;
    const float maxDist = 100.0;
    const float epsilon = 0.001;

    float distance = 0.0;
    for (int i = 0; i < maxSteps; ++i) {
        float dist = sdf(camPos + distance * rayDir);
        if (dist < epsilon) {
            vec3 hitPoint = camPos + distance * rayDir;
            // Calculate lighting or coloring here
            FragColor = vec4(1.0, 0.5, 0.2, 1.0); // Example color
            return;
        }
        distance += dist;
        if (distance > maxDist) break;
    }

    FragColor = vec4(0.0, 0.0, 0.0, 1.0); // Background color
}
