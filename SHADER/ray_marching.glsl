#version 410 core

out vec4 FragColor;

uniform vec2 resolution;
uniform float time;
uniform vec4 Back_ground_color;
float sdf_sphere_1(vec3 p){
    return length(p - vec3(0.5, 0.0, 0.0)) - 0.5; // Sphere 1 with radius 0.5 at (0.5, 0.0, 0.0)
}


float sdBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, max(d.y, d.z)), 0.0);
}

vec3 boxGradient(vec3 p, vec3 rad) {
    vec3 d = abs(p) - rad;
    vec3 s = sign(p);
    float g = max(max(d.x, d.y), d.z); // Max component of d

    // Determine the gradient based on whether g is greater than 0
    return s * ((g > 0.0) ? normalize(max(d, 0.0)) : 
                           step(d.yzx, d.xyz) * step(d.zxy, d.xyz));
}

vec3 computeNormal(vec3 p, vec3 boxDimensions) {
    const float eps = 0.001;
    vec3 normal = vec3(
        sdBox(p + vec3(eps, 0.0, 0.0), boxDimensions) - sdBox(p - vec3(eps, 0.0, 0.0), boxDimensions),
        sdBox(p + vec3(0.0, eps, 0.0), boxDimensions) - sdBox(p - vec3(0.0, eps, 0.0), boxDimensions),
        sdBox(p + vec3(0.0, 0.0, eps), boxDimensions) - sdBox(p - vec3(0.0, 0.0, eps), boxDimensions)
    );
    return normalize(normal);
}

vec3 computeBoxPosition(float time) {
    // Modify the position of the box based on time
    float amplitude = 1.0; // Adjust the amplitude of the movement
    float speed = 0.5; // Adjust the speed of the movement
    float yOffset = sin(time * speed) * amplitude; // Calculate the y offset
    float xOffset = sin(time * speed) * amplitude; // Calculate the x offset
    return vec3(0.0, 0.0, -5.0); // The new position of the box
}

vec3 rotate(vec3 p, vec3 angles) {
    float cX = cos(angles.x);
    float sX = sin(angles.x);
    float cY = cos(angles.y);
    float sY = sin(angles.y);
    float cZ = cos(angles.z);
    float sZ = sin(angles.z);

    // Rotation matrix
    mat3 rotX = mat3(1, 0, 0, 0, cX, -sX, 0, sX, cX);
    mat3 rotY = mat3(cY, 0, sY, 0, 1, 0, -sY, 0, cY);
    mat3 rotZ = mat3(cZ, -sZ, 0, sZ, cZ, 0, 0, 0, 1);

    // Apply rotations
    return rotX * rotY * rotZ * p;
}

float opRepetition(vec3 p, vec3 s, vec3 repetitions ){
vec3 q = p - s*clamp(round(p/s),-1,1);
return sdBox(q,s);
}

float repeaterd(vec3 p, vec3 r,float s ){
p.x = p.x - round(p.x);

vec3 v = p - s * round(p / s);


return sdBox(v, r);

//return sdBox(p,r);
}
void main(){    
    vec3 repetitions = vec3(1.0);
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
      vec3 objectPos = vec3(0.0, 0.0, 0.0);
    uv.x *= resolution.x / resolution.y;
    float current_time = time;
    //vec3 camPos = vec3(0.0, 0.0, -3.0); // Camera position
    vec3 camPos = computeBoxPosition(current_time); // Camera position
   
    vec3 rayDir = normalize(vec3(uv, -2.0)); // Ray direction

    const int maxSteps = 100;
    const float maxDist = 100.0;
    const float epsilon = 0.001;

    float distance = 0.0;
    for (int i = 0; i < maxSteps; ++i) {

        float dist_box = sdBox(camPos + distance * rayDir, vec3(0.5, 0.3, 0.3)); // Box dimensions (adjust as needed)

        float dist_sphere = sdf_sphere_1(camPos + distance * rayDir);
        //float inf_box = opRepetition(camPos + distance * rayDir,dist_sphere,repetitions);

        float inf_box1 = repeaterd(camPos + distance * rayDir,vec3(0.5, 0.3, 0.3),15);
        float closestDist = inf_box1;
       
        

        if (closestDist < epsilon) {
            vec3 hitPoint = camPos + distance * rayDir;
            vec3 normal = computeNormal(hitPoint, vec3(0.5, 0.3, 0.3)); // Calculate normal




            // Simple diffuse lighting
            float diffuse = max(dot(normal, normalize(vec3(0.7, 0.7, -0.7))), 0.0); // Light direction: (-0.7, 0.7, 0.7)
            vec3 color = vec3(1.0, 0.5, 0.2); // Base color
            vec3 finalColor = color * diffuse; // Apply diffuse lighting



            FragColor = vec4(finalColor, 1.0);
            return;
        }
        
        distance += closestDist;
        if (distance > maxDist) break;
    }

    FragColor = Back_ground_color; // Background color
}
