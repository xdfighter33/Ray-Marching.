#version 410 core

out vec4 FragColor;
uniform vec2 resolution;
uniform float time;

float grid(vec3 p, vec2 size) {
    vec2 grid = abs(mod(p.xz, size) - size * 0.5);
    return max(grid.x, grid.y) - 0.1;
}

float scene(vec3 p) {
    float distance = 100.0;
    float speed = 0.1;
    
    for (int i = 0; i < 5; ++i) {
        vec2 size = vec2(2.0 + float(i) * 1.5);
        float dist = grid(p, size);
        distance = min(distance, dist);
        distance += 0.1;
    }
    
    return distance;
}

void main() {
    vec2 uv = (gl_FragCoord.xy / resolution.xy) * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;

    vec3 camPos = vec3(0.0, 0.0, -3.0);
    vec3 rayDir = normalize(vec3(uv, 2.0));

    const int maxSteps = 100;
    const float maxDist = 100.0;
    const float epsilon = 0.001;

    float distance = 0.0;
    float marchTime = time * 0.1; // Adjust speed of scrolling

    for (int i = 0; i < maxSteps; ++i) {
        float dist = scene(camPos + distance * rayDir);
        float modulatedDist = mod(dist + marchTime * 2.0, 1.0) - 0.5; // Modulate distance with time

        if (modulatedDist < epsilon) {
            float color = mod(distance * 10.0, 1.0); // Add color variation
            FragColor = vec4(color, color, color, 1.0); // Example: grayscale matrix effect
            return;
        }

        distance += dist;
        if (distance > maxDist) break;
    }

    FragColor = vec4(0.0, 0.0, 0.0, 1.0); // Background color
}
