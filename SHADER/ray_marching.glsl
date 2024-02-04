#version 410 core
#define PI2 6.28318531


out vec4 FragColor;


uniform vec2 iMouse;
uniform vec2 resolution;
uniform float time;
uniform vec4 Back_ground_color;
uniform vec3 Light_direction;
uniform vec3 sky_light_direction;
uniform vec3 camPos;
uniform vec3 camera; 
uniform float inten_value;

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

vec3 computeSphereNormals(vec3 p){
   return normalize(p);
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




float opCheapBend(vec3 p )
{
    const float k = 0.25; // or some other amount
    float c = cos(k*p.x);
    float s = sin(k*p.x);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xy,p.z);
    return sdBox(q,vec3(1.0));
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
    float amplitude = 2.0; // Adjust the amplitude of the movement
    float speed = 2.0; // Adjust the speed of the movement

    float circularMotion = sin(time * speed) * amplitude;
    float yOffset = circularMotion * cos(time * speed);
    float xOffset = circularMotion * sin(time * speed);

    // Apply smoothstep to control the motion
    float smoothThreshold = 15.0; // Adjust the threshold for smoothstep
    float smoothMotion = smoothstep(-smoothThreshold, smoothThreshold, circularMotion);

    // Interpolate between circular motion and a linear path based on smoothstep
    vec3 linearMotion = vec3(time * 0.4, time * 0.4, -4); // Linear motion path
    vec3 finalPosition = vec3(0,0, -8);

    vec3 cpu_cam_pos = camera;

    return cpu_cam_pos; 
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

float opRepetition(vec3 p, vec3 s, float repetitions ){
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

float opRepetition(vec3 p, vec3 s,vec3 primitive )
{
    vec3 q = p - s*round(p/s);
    return length( q );
}

float sdCylinder( vec3 p, vec3 c )
{
  return length(p.xz-c.xy)-c.z;
}



float sdCutHollowSphere( vec3 p, float r, float h, float t )
{
  // sampling independent computations (only depend on shape)
  float w = sqrt(r*r-h*h);
  
  // sampling dependant computations
  vec2 q = vec2( length(p.xz), p.y );
  return ((h*q.x<w*q.y) ? length(q-vec2(w,h)) : 
                          abs(length(q)-r) ) - t;
}

float opRev(vec3 p, float o){
//Elongates????
   // o += time * 0.5;
    vec2 x = vec2(length(p.xy) - o, p.y);

    return sdBox(vec3(x.x,x.y,0.0),vec3(1.25));
}

float opElongate(vec3 p, vec3 h){

    vec3 q = p - clamp(p,-h,h);
    return sdBox(q,vec3(1.));
}

float opRound(vec3 p,float rad){

    return sdBox(p - rad,vec3(1.25));
}

float opDisplace(vec3 p )
{
    float d1 = sdf_sphere_1(p,0.5);
    float d2 = cos( time ) * p.x;
    return d1+d2;
}



float repeated(vec3 p, float s)
{
    vec3 id = round(p / s);
    vec3 o = sign(p - s * id); // neighbor offset direction
    
    float d = 1e20;
    for (int j = 0; j < 2; j++)
        for (int i = 0; i < 2; i++)
            for (int k = 0; k < 2; k++)
            {
                vec3 rid = id + vec3(i, j, k) * o;
                vec3 r = p - s * rid;


                float timeEffect = sin(time);

                float animated = sin(r.x * 5.0 + timeEffect) * cos(r.y * 5.0) * sin(r.z * 1.0);

                // Twisted and warped pattern
                float twisted = cos(r.x * time) * cos(r.y * time) * cos(r.z * time);
                float warped = sin(r.x * 1.0) * sin(r.y * 1.0) * sin(r.z * 1.0);
                
               // d = min(d, sdVerticalCapsule(r * twisted, 1.5, 0.05));

             //d = min(d,opRev(r,1.55));

             d = min(d,opRev(r,5.5));
            }
    return d;
}


float repetition_rotationals( vec3 p, int n )
{
    float sp = 6.283185/float(n);
    float an = atan(p.y, p.x);
    float id = floor(an/sp);

    float a1 = sp*(id+0.0);
    float a2 = sp*(id+1.0);


    // Adjust the arguments for the mat3 constructor based on your needs
    mat3 rotationMatrix1 = mat3(cos(a1), -sin(a1), 0.0, sin(a1), cos(a1), 0.0, 0.0, 0.0, 1.0);
    mat3 rotationMatrix2 = mat3(cos(a2), -sin(a2), 0.0, sin(a2), cos(a2), 0.0, 0.0, 0.0, 1.0);

    vec3 r1 = rotationMatrix1 * p;
    vec3 r2 = rotationMatrix2 * p;

    return min(sdf_sphere_1(r1,1 /* radius */), sdf_sphere_1(r2, 1/* radius */));
}




vec3 palette(float t,vec3 a,vec3 b,vec3 c,vec3 d ){
    return a + b*cos( 6.28318*(c*t+d));
}


vec3 computerSphereNormal(vec3 p, vec3 sphereCenter){
    return normalize(p - sphereCenter);
}





float map(vec3 p,float time){


vec3 spherePos = vec3(0,-2,sin(time) * 5 );
vec3 boxPos = vec3(0,0,0);
vec3 infBoxPos = vec3(sin(time * 2),-5,0);
vec3 linePos = vec3( 0,0,5);

vec3 physical_light_pos = Light_direction;



vec3 zx = p;

zx = fract(p) - .45;



float sphere = sdf_sphere_1(p - spherePos,1.0);

 
float physical_light = sdf_sphere_1(p -physical_light_pos, 1.75);
float cylinder = sdCylinder(p,vec3(1.0));

float bent_box = opCheapBend(p);
float line = sdVerticalCapsule(zx,0.25,0.252);

float box = sdBox(p - boxPos,vec3(1.));

float ground1 = -p.y + .75;
float ground2 = p.y + .75;



float test = repeated(p - boxPos,5.5);

float test1 = opRev(p,0.25);
float test2 = opElongate(p,vec3(1.5));

float test3 = opRound(p - infBoxPos,5.5);
float combined =  smin(ground1,sphere,1.0);

float test4 = opDisplace(p);
//return smoothstep(ground1,box,1.0);
return min(sphere,smin(ground1,box,10.5));
//return box;
}


vec3 computeNormalTime(vec3 p, float epsilon, float time) {
    // Compute the gradient using central differences
    float dx = (map(p + vec3(epsilon, 0.0, 0.0), time) - map(p - vec3(epsilon, 0.0, 0.0), time)) / (2.0 * epsilon);
    float dy = (map(p + vec3(0.0, epsilon, 0.0), time) - map(p - vec3(0.0, epsilon, 0.0), time)) / (2.0 * epsilon);
    float dz = (map(p + vec3(0.0, 0.0, epsilon), time) - map(p - vec3(0.0, 0.0, epsilon), time)) / (2.0 * epsilon);

    // Normalize the gradient to get the normal
    return normalize(vec3(dx, dy, dz));


}

vec3 toonShader(float intensity, vec3 BaseColor, float numLevels) {
return BaseColor * ceil(intensity * numLevels) / numLevels;
}



float shadow(vec3 ro,  vec3 rd, float mint, float maxt )
{
    float t = mint;
    for( int i=0; i<256 && t<maxt; i++ )
    {
        float h = map(ro + rd * t,time);
        if( h<0.001 )
            return 0.0;
        t += h;
    }
    return 1.0;
}


void main() {
    vec3 repetitions = vec3(1.0);
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    vec3 objectPos = vec3(0.0, 0.0, 0.0);
    uv.x *= resolution.x / resolution.y;
    float current_time = time;
    vec3 camPos = computeBoxPosition(current_time);
    vec3 rayDir = normalize(vec3(uv, -2));

    const int maxSteps = 100;
    const float maxDist = 100.0;
    const float epsilon = 0.001;


// float shadowIntensity = shadow(camPos, normalize(vec3(0.0, -1.0, -4.0)), 0.001, maxDist);
float light_shadowIntensity = shadow(camPos, normalize(Light_direction), 0.001, maxDist);
float sky_shadowIntensity = shadow(camPos, normalize(sky_light_direction), 0.001, maxDist);



    float distance = 0.0;
    for (int i = 0; i < maxSteps; ++i) {
        float maps = map(camPos + distance * rayDir, current_time);
        float closestDist = maps;

        if (closestDist < epsilon) {
            vec3 hitPoint = camPos + distance * rayDir;
         //   vec3 normal = computeNormal(hitPoint, vec3(0.5, 0.3, 0.3));
          //  vec3 normal = computerSphereNormal(hitPoint,sdf);
            vec3 normal = computeNormalTime(hitPoint,0.001,current_time);
            //  vec3 normal = computeSphereNormals(hitPoint);

            float depthIntensity = 1.0 + smoothstep(0.0, 0., distance / maxDist);
             
            // Check if the point lies on a grid line
            bool isGridLineX = mod(hitPoint.x, 1.0) < 0.02;
            bool isGridLineZ = mod(hitPoint.z, 1.0) < 0.02;

            // Color the ground based on grid lines
            //vec3 groundColor = isGridLineX || isGridLineZ ? vec3(0.0, 1.0, 0.0) : vec3(0.0); // Green lines, black ground
         

              vec3 lightDir = normalize(Light_direction);
              vec3 sky_light_dir = normalize(sky_light_direction);




            // Toon Shader code

             float sky_intensity = dot(sky_light_direction, normalize(normal));
        vec3 sky_toonColor;

if (sky_intensity > 0.95) {
    sky_toonColor = vec3(1.0,0.5,0.5);
} else if (sky_intensity > 0.5) {
    sky_toonColor = vec3(0.6,0.3,0.3);
}
else if (sky_intensity > 0.25) {
    
    sky_toonColor = vec3(0.4,0.2,0.2);
    }
    else {
    sky_toonColor = vec3(0.6,0.3,0.3); // Default color for lower intensities
}

        float sky_celShadeLevels =  2;
        sky_toonColor *= ceil(sky_intensity * sky_celShadeLevels);


            // MAIN SKY LIGHT

            // SKy = Sky_light 


            // Sky light Diffuse 
            float sky_diff_strengt = 5.0;
            float sky_diffuse_strength = max(dot(normal,sky_light_dir),0.0);
            vec3 sky_diffuse_color = sky_toonColor;
            vec3 sky_diffuse = sky_diffuse_strength * sky_diffuse_color;

            //Skylight Ambient 

            float sky_ambient_strength = 5.0; 
            vec3  sky_ambient_color = sky_toonColor;
            vec3 sky_ambient =  sky_ambient_color * sky_ambient_strength;




            // Tooon Shader 
    float intensity = dot(Light_direction, normalize(normal));
        vec3 toonColor;

        if (intensity > 0.9) {
            toonColor = vec3(1.0, 0.0, 0.85);
        } else if (intensity > 0.3) {
   
            toonColor = vec3(0.0, 1.0, 0.87); 
        }  else {
            toonColor = vec3(0.0);
        } 

             // Diffuse component


        float dif_strength = 2.5;
        float diffuseStrength = max(dot(normal, lightDir), 0.0);
        vec3 diffuse_color = vec3(0.95, 0.74, 0.0);
        vec3 diffuse = diffuseStrength * toonColor;

        // Specular component (Blinn-Phong)
        vec3 viewDir = normalize(camPos - hitPoint);
        vec3 halfwayDir = normalize(lightDir + viewDir);

        float shininess = 0.0;
        float specularStrength = pow(max(dot(normal, halfwayDir), 0.0), shininess);
        vec3 specularColor = specularStrength * vec3(1.0) * shininess;

        

        // Ambient component
        float ambientStrength = 2.50;
        vec3 ambient_color = vec3(0.8, 0.0, 0.0);
        vec3 ambient = ambientStrength * toonColor;


        vec3 biPhong_use_color = vec3(0.0, 0.24, 1.0);

        // Combine all components
  
        vec3 total_ambient = ambient + sky_ambient;
        vec3 total_diffuse = diffuse + sky_diffuse;


         vec3 biPhongColor = (total_ambient + total_diffuse + specularColor);

        // Mix Bi-Phong and Toon colors
        vec3 finalColor = biPhongColor;
        



         
            // Add some noise to the color
            float noiseValue = noise(hitPoint * 0.5); // Adjust the noise frequency
//            finalColor += noiseValue * 1.5; // Adjust noise influence


          

            vec3 shadowColor = vec3(0.2);  // Adjust the shadow color

      //      finalColor = mix(biPhongColor,shadowColor,sky_shadowIntensity);
           
         //finalColor = toonShader(1.0,finalColor,3.0);   
         FragColor = vec4(sky_toonColor, 1.0);

            return;
        }

        distance -= closestDist;
        if (distance > maxDist) break;
    }

    FragColor = Back_ground_color; // Background color
}