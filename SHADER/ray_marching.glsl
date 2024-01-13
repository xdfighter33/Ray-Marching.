#version 410 core
#define PI2 6.28318531


out vec4 FragColor;


uniform vec2 iMouse;
uniform vec2 resolution;
uniform float time;
uniform vec4 Back_ground_color;

float noise(vec3 p) {
    return fract(sin(dot(p, vec3(12.9898, 78.233, 98.422))) * 43758.5453);
}





float marble(vec3 p) {
    float freq = 5.0;
    float amp = 0.5;
    float turbulence = 0.0;

    for (int i = 0; i < 4; i++) {
        turbulence += abs(noise(p * freq)) * amp;
        freq *= 2.0;
        amp *= 0.5;
        p *= 2.0; // Adjust the scale of noise
    }

    return turbulence;
}



float sdf_sphere_1(vec3 p, float r){
    return length(p) - r; // 
}


float sdBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, max(d.y, d.z)), 0.0);
}
float sdVerticalCapsule( vec3 p, float h, float r )
{
  p.y -= clamp( p.y, 0.0, h );
  return length( p ) - r;
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
    float amplitude = 0.5; // Adjust the amplitude of the movement
    float speed = 1.0; // Adjust the speed of the movement
    float yOffset = sin(time * speed) * amplitude; // Calculate the y offset
    float xOffset = sin(time * speed) * amplitude; // Calculate the x offset
    return vec3(0, 0, time * -4); // The new position of the box
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



float opU( float d1, float d2 )
{
    return min( d1, d2 );
}




float smin(float a, float b, float k) {
  float res = exp2( -k*a ) + exp2( -k*b );
    return -log2( res )/k;
}


float opUnion( float d1, float d2 )
{
    return max(-d1,d2);
}

float opSmoothUnion( float d1, float d2, float k )
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}



float map(vec3 p,float time){


vec3 spherePos = vec3( sin(time) * 2,0,0);
vec3 boxPos = vec3(0,-2,2.5);

vec3 linePos = vec3( 0,0,5);

vec3 zx = p;

zx = fract(p) - .45;



float sphere = sdf_sphere_1(p - spherePos,0.5);
float line = sdVerticalCapsule(zx,0.25,0.252);

float box = sdBox(p,vec3(0.5));
float ground1 = -p.y + .75;
float ground2 = p.y + .75;

float combined =  opSmoothUnion(ground1,sphere,1.0);

return ground1;
}
void main() {
    vec3 repetitions = vec3(1.0);
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    vec3 objectPos = vec3(0.0, 0.0, 0.0);
    uv.x *= resolution.x / resolution.y;
    float current_time = time;
    vec3 camPos = computeBoxPosition(current_time);
    vec3 rayDir = normalize(vec3(uv, -3.0));

    const int maxSteps = 100;
    const float maxDist = 100.0;
    const float epsilon = 0.001;

    float distance = 0.0;
    for (int i = 0; i < maxSteps; ++i) {
        float maps = map(camPos + distance * rayDir, current_time);
        float closestDist = maps;

        if (closestDist < epsilon) {
            vec3 hitPoint = camPos + distance * rayDir;
            vec3 normal = computeNormal(hitPoint, vec3(0.5, 0.3, 0.3));

            float depthIntensity = 1.0 + smoothstep(0.0, 0., distance / maxDist);

            // Check if the point lies on a grid line
            bool isGridLineX = mod(hitPoint.x, 1.0) < 0.02;
            bool isGridLineZ = mod(hitPoint.z, 1.0) < 0.02;

            // Color the ground based on grid lines
            vec3 groundColor = isGridLineX || isGridLineZ ? vec3(0.0, 1.0, 0.0) : vec3(0.0); // Green lines, black ground
            vec3 finalColor = groundColor;

            // Simple diffuse lighting
            float diffuse = max(dot(normal, normalize(vec3(0.0, -1.0, -5.0))), 0.0);

            // Modify the color based on lighting and effects
            finalColor += vec3(0.5) * diffuse;

            // Add some noise to the color
            float noiseValue = noise(hitPoint * 5.0); // Adjust the noise frequency
            finalColor += noiseValue * 0.1; // Adjust noise influence

            FragColor = vec4(finalColor, 1.0);
            return;
        }

        distance -= closestDist;
        if (distance > maxDist) break;
    }

    FragColor = Back_ground_color; // Background color
}