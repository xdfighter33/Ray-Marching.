#version 410 core
#define PI2 6.28318531


out vec4 FragColor;

#define inf 1e20

uniform vec2 iMouse;
uniform vec2 resolution;
uniform float time;
uniform vec4 Back_ground_color;
uniform vec3 Light_direction;
uniform vec3 sky_light_direction;
uniform vec3 Global_light;
uniform vec3 camPos;
uniform vec3 door_cords;
uniform vec3 camera;
uniform vec3 sphere_cords;
uniform float inten_value;

float noise(vec3 p) {
    return fract(sin(dot(p, vec3(12.9898, 78.233, 98.422))) * 43758.5453);
}





float sdPlane( vec3 p, vec3 n, float h )
{
  // n must be normalized
  return dot(p,n) + h;
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


vec3 computeSphNormals(vec3 p, float radius){
    const float eps = 0.001;
    vec3 normal = vec3(
        sdf_sphere_1(p + vec3(eps,0.0,0.0), radius) - sdf_sphere_1(p - vec3(eps,0.0,0.0), radius),
        sdf_sphere_1(p + vec3(0.0,eps,0.0), radius) - sdf_sphere_1(p - vec3(0.0,eps,0.0), radius),
        sdf_sphere_1(p + vec3(0.0,0.0,eps), radius) - sdf_sphere_1(p - vec3(0.0,0.0,eps), radius)
    );
    return normalize(normal);
}

vec3 computePlaneNormals(vec3 p, vec3 radius,float h){
    const float eps = 0.001;
    vec3 normal = vec3(
        sdPlane(p + vec3(eps,0.0,0.0), radius, h) - sdPlane(p - vec3(eps,0.0,0.0), radius, h),
        sdPlane(p + vec3(0.0,eps,0.0), radius, h) - sdPlane(p - vec3(0.0,eps,0.0), radius, h),
        sdPlane(p + vec3(0.0,0.0,eps), radius, h) - sdPlane(p - vec3(0.0,0.0,eps), radius, h)
    );
    return normalize(normal);
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

    //cpu_cam_pos.z *= sin(time) * 2;
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
    return sdBox(q,vec3(1));
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

                float animated = sin(r.x * 1.0 + timeEffect) * cos(r.y * 1.0) * sin(r.z * 1.0);

                // Twisted and warped pattern
                float twisted = cos(r.x * time) * cos(r.y * time);
                float warped = sin(r.x * 1.0) * sin(r.y * 1.0) * sin(r.z * 1.0);
                
                float shift_down = sin(r.z * timeEffect);
              //  d = min(d, sdVerticalCapsule(r - vec3(0,0,sin(-4) * time), 1.5, 0.05));

             //d = min(d,opRev(r,1.55));
            vec3 pos = vec3(-4,-2,-2 * sin(time));

          //  pos.z *= time;
          //   d = min(d,opElongate(r - pos,vec3(0.5)));
             d = min(d,sdVerticalCapsule(r - pos,3.0,1.0));
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


float repeat_rectangular_ONLY_SYMMETRIC_SDFS( vec3 p,  vec3 size, float s )
{
    p = abs(p/s) - (vec3(size)*0.5-0.5);
   p = (p.x < p.y) ? ((p.y < p.z) ? p.yxz : ((p.x < p.z) ? p.xyz : p.zxy)) :
                  ((p.x < p.z) ? p.xzy : ((p.y < p.z) ? p.zxy : p.yxz));
    p.z -= min(0.0, round(p.x));
    return sdBox(p*s,vec3(1.25));
}

float sdCross( vec3 p )
{
  float da = sdBox(p.xyz,vec3(inf,1.0,1.0));
  float db = sdBox(p.yzx,vec3(1.0,inf,1.0));
  float dc = sdBox(p.zxy,vec3(1.0,1.0,inf));
  return min(da,min(db,dc));
}


float limited_repeated( vec3 p, vec3 size, float s )
{
    
    vec3 id = round( p/s);
    vec3  o = sign(p-s*id);
    float d = 1e20;
    for( int j=0; j<3; j++ )
    for( int i=0; i<3; i++ )
    {
        vec3 rid = id + vec3(i,j,1.0)*o;
	// limited repetition
        rid = clamp(rid,-(size-1.0)*0.5,(size-1.0)*0.5);
        vec3 r = p - s*rid;
        d = min( d, opElongate(r,vec3(1)));
    }
    return d;
}




vec3 palette(float t,vec3 a,vec3 b,vec3 c,vec3 d ){
    return a + b*cos( 6.28318*(c*t+d));
}


vec3 computerSphereNormal(vec3 p, vec3 sphereCenter){
    return normalize(p - sphereCenter);
}


float repeated_rectanlgle(vec3 p, vec3 size){
    int count = 10;
    float b = 6.283185/float(count);
    float theta = acos(p.x / length(p));

    float a = atan(p.y,p.x);
    float i = floor(theta /b);

    
  float c1 = b * (i + 0.0); 
vec3 p1 = mat3(cos(c1), -sin(c1), 0.0,
               sin(c1), cos(c1), 0.0,
               0.0, 0.0, 1.0) * p;

float c2 = b * (i + 1.0); 
vec3 p2 = mat3(cos(c2), -sin(c2), 0.0,
               sin(c2), cos(c2), 0.0,
               0.0, 0.0, 1.0) * p;



    return min(sdBox(p1,size),sdBox(p2,size));
}
float wall(vec3 p){
        float plane = -p.y + .75;
    vec3 window_pos = vec3(0,0,-4.0);
    vec3 door_pos = door_cords;
    
    
    vec3 v = p;
    float cylinder = length(v.xz) - 2 ;


    cylinder = max(cylinder,v.y - 2.0);
    cylinder = max(cylinder,-v.y - 2.0);
    
    cylinder *= .5;
    float maps = smin(plane,cylinder,2.5);





   

    return maps;
}



float map(vec3 p, float time){


vec3 spherePos = vec3(.5,0,0);
vec3 boxPos = vec3(0,0,0);
vec3 infBoxPos = vec3(0,-1,0);
vec3 linePos = vec3( 0,0,5);
vec3 light1_physical_pos = Light_direction;
vec3 physical_light_pos = sky_light_direction;
vec3 global_light_pos = Global_light;
vec3 plane_pos = vec3(0,0,0);


vec3 zx = p;
p.x *= 2;
normalize(zx.y);
//zx = fract(p) - .45;

vec3 planeNormal = normalize(vec3(0.0, -.5, 0));

float sphere = sdf_sphere_1(p - sphere_cords,1.0);

 
float physical_light = sdf_sphere_1(p -physical_light_pos, 0.25);

float light1 = sdf_sphere_1(p - light1_physical_pos, 0.75);
float global_light = sdf_sphere_1(p - global_light_pos, 0.75);
float cylinder = sdCylinder(p,vec3(1.0));
float plane = sdPlane(p - plane_pos,planeNormal,1.0);

float bent_box = opCheapBend(p);
float line = sdVerticalCapsule(zx,0.25,0.252);

float box = sdBox(p - boxPos,vec3(1.0));

float ground1 = -p.y + .75;
float ground2 = p.y + .75;

float wall = wall(p);

float test = repeated(p,5.5);

float test1 = opRev(p,0.25);
float test2 = opElongate(p,vec3(1.5));

float test3 = opRound(p - infBoxPos,5.5);
float combined =  smin(ground1,sphere,1.0);

float test4 = opDisplace(p);
//return smoothstep(ground1,box,1.0);
//return min(sphere,smin(ground1,box,10.5));
//return min(sphere,min(physical_light,light1));
//return opSmoothUnion(global_light,min(box,min(sphere,min(plane,min(light1,physical_light)))),1.0);
//return min(physical_light,min(global_light,opSmoothUnion(sphere,plane,1.5)));
//return box;
//return plane;
return wall;
}


vec3 computeNormalTime(vec3 p, float epsilon, float time) {
    // Compute the gradient using central differences
    float dx = (map(p + vec3(epsilon, 0.0, 0.0), time) - map(p - vec3(epsilon, 0.0, 0.0), time)) / (2.0 * epsilon);
    float dy = (map(p + vec3(0.0, epsilon, 0.0), time) - map(p - vec3(0.0, epsilon, 0.0), time)) / (2.0 * epsilon);
    float dz = (map(p + vec3(0.0, 0.0, epsilon), time) - map(p - vec3(0.0, 0.0, epsilon), time)) / (2.0 * epsilon);

    // Normalize the gradient to get the normal
    return normalize(vec3(dx, dy, dz));


}
vec3 computeMapNormals(vec3 p, float radius){
    const float eps = 0.001;
    vec3 normal = vec3(
        map(p + vec3(eps,0.0,0.0), radius) - map(p - vec3(eps,0.0,0.0), radius),
        map(p + vec3(0.0,eps,0.0), radius) - map(p - vec3(0.0,eps,0.0), radius),
        map(p + vec3(0.0,0.0,eps), radius) - map(p - vec3(0.0,0.0,eps), radius)
    );
    return normalize(normal);
}


vec3 toonShader(float intensity, vec3 BaseColor, float numLevels) {
return BaseColor * ceil(intensity * numLevels) / numLevels;
}

vec3 reflect(vec3 I, vec3 N)
{
    return I - 2.0 * dot(I, N) * N;
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
vec3 computeTestNormal(vec3 p,float time){
    const float eps = 0.001;
        vec3 normal = vec3(
        map(p + vec3(eps,0.0,0.0),time) - map(p - vec3(eps,0.0,0.0),time),
        map(p + vec3(0.0,eps,0.0),time) - map(p - vec3(0.0,eps,0.0),time),
        map(p + vec3(0.0,0.0,eps),time) - map(p - vec3(0.0,0.0,eps),time)
    );

    return normalize(normal);
}
vec3 calculateRimLighting(vec3 normal,vec3 viewDirection) {
    // Calculate the dot product between the surface normal and the view direction
    float rimFactor = dot(normalize(normal), normalize(viewDirection));
    
    // Apply threshold to rimFactora
    float rimThreshold = .25;

    rimFactor = clamp((rimFactor - rimThreshold) / (1.0 - rimThreshold), 0.0, 1.0);
    
    // Scale rimFactor to control intensity
    float rimIntensity = 0.25;
    rimFactor *= rimIntensity;
    
    // Combine rim lighting color with base color
    vec3 rimColor = vec3(1.0, 1.0, 1.0); // Rim lighting color (usually white)
    return rimColor * rimFactor;
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
    const float epsilon = 0.01;


// float shadowIntensity = shadow(camPos, normalize(vec3(0.0, -1.0, -4.0)), 0.001, maxDist);
float light_shadowIntensity = shadow(camPos, normalize(Light_direction), 0.001, maxDist);
float sky_shadowIntensity = shadow(camPos, normalize(sky_light_direction), 0.001, maxDist);



    float distance = 0.0;
    float edge_width = 0.5;
    float lastDistEval = 1e10;
    float edge = 0;
    for (int i = 0; i < maxSteps; ++i) {
        float maps = map(camPos + distance * rayDir, current_time);
        float closestDist = maps;
        vec3 finalColor;
        if (closestDist < epsilon) {
            vec3 hitPoint = camPos + distance * rayDir;
            vec3 previousPoint = camPos - distance * rayDir;
            vec3 previous_nroaml = computeSphNormals(previousPoint,1.0);
            //vec3 normal = computeNormalTime(hitPoint,epsilon,time);
            vec3 scene_normal = computeTestNormal(hitPoint,time);
            vec3 normal = computeSphNormals(hitPoint,1.0);
            vec3 plane_normal = computePlaneNormals(hitPoint,normalize(vec3(0.0,-1.0,0.0)),1.0);
            float depthIntensity = 1.0 + smoothstep(0.0, 0., distance / maxDist);
            // Check if the point lies on a grid line
            bool isGridLineX = mod(hitPoint.x, 1.0) < 0.02;
            bool isGridLineZ = mod(hitPoint.z, 1.0) < 0.02;

            // Color the ground based on grid lines
            //vec3 groundColor = isGridLineX || isGridLineZ ? vec3(0.0, 1.0, 0.0) : vec3(0.0); // Green lines, black ground
         
vec3 viewDirection = normalize(camPos - hitPoint);
              vec3 lightDir = normalize(Light_direction);
              vec3 sky_light_dir = normalize(sky_light_direction);
              vec3 global_light_dir = normalize(Global_light);
              



            // Edge Detectoion
            float dotProduct = dot(scene_normal,previous_nroaml);
            vec3 edge_color = vec3(0.0);
            float edge_thresh = 0.1;
            float edge_width = 0.01;
            float edge_factor = smoothstep(edge_thresh - edge_width,edge_thresh,dotProduct);
          /*   if (dotProduct < .1){
            //    FragColor = vec4(1.0, 0.0, 0.0, 1.0);
                return;
            }
         */
            vec3 deriv_normal_x = dFdx(scene_normal);
            vec3 deriv_normal_y = dFdy(scene_normal);

            float line = length(deriv_normal_x) + length(deriv_normal_y);

            vec3 color2 = deriv_normal_x + deriv_normal_y;

            color2 *= 2;
            // Toon Shader code

             float sky_intensity = dot(sky_light_direction, normalize(normal));
        vec3 sky_toonColor;


//vec3 mediumIntensityColor = vec3(0.88, 0.11, 0.11);
//vec3 highIntensityColor = vec3(0.0, 0.1, 0.68);

//vec3 color = vec3(float(0x66) / 255.0, float(0x7d) / 255.0, float(0xb6) / 255.0);
vec3 highIntensityColor = vec3(float(0x1a) / 255.0, float(0x2a) / 255.0, float(0x6c) / 255.0);
vec3 mediumIntensityColor = vec3(float(0xb2) / 255.0, float(0x1f) / 255.0, float(0x1f) / 255.0);
vec3 lowIntensityColor = vec3(float(0xfd) / 255.0, float(0xbb) / 255.0, float(0x2d) / 255.0);

vec3 med_color = vec3(0.62, 0.08, 0.0);
vec3 high_color = vec3(0.86, 0.11, 0.0);
vec3 rimLighting = calculateRimLighting(normal,sky_light_dir);


if (sky_intensity > 0.33) {
     sky_toonColor = med_color;
}
else if (sky_intensity > 0.66) {
     sky_toonColor = high_color;
}
    else {
  //  sky_toonColor = vec3(0.76, 0.36, 1.0); // Default color for lower intensities

    sky_toonColor = highIntensityColor;
}

        float sky_celShadeLevels =  5;
     //  sky_toonColor *= floor(sky_intensity * sky_celShadeLevels);


            // MAIN SKY LIGHT

            // SKy = Sky_light 

            
            // Sky light Diffuse 
            float sky_diff_strengt = 5.5;
            float sky_diffuse_strength = max(dot(normal,sky_light_dir),0.0);
            float plane_sky_diffuse_strength = max(dot(plane_normal,sky_light_dir),0.0);
            vec3 sky_diffuse_color = sky_toonColor;
            vec3 sky_diffuse = (sky_toonColor * sky_diffuse_strength) * sky_diff_strengt;
            vec3 plane_sky_diffuse = sky_toonColor * plane_sky_diffuse_strength;

            //Skylight Ambient 

            float sky_ambient_strength = 1.0; 
            vec3  sky_ambient_color = sky_toonColor;
            vec3 color = vec3(0.28, 0.0, 1.0);
            vec3 sky_ambient =  color * sky_ambient_strength;




            // Tooon Shader 
    float intensity = dot(Light_direction, normalize(normal));
        vec3 toonColor;

        if (intensity > 0.75) {
            toonColor = vec3(0.79, 0.01, 0.01);
        } else if (intensity > 0.5) {
   
            toonColor = vec3(0.94, 0.0, 0.0); 
        }  else {
            toonColor = vec3(0.28, 0.0, 0.0);
        } 

             // Diffuse component

        
        float dif_strength = 1.5;
        float diffuseStrength = max(dot(normal, lightDir), 0.0);
        vec3 diffuse_color = vec3(1.0, 0.82, 0.0);
        vec3 diffuse = diffuseStrength * toonColor;
        
        float plane_diffuseStrength = max(dot(plane_normal, global_light_dir), 0.0);

        vec3 plane_color =  (plane_diffuseStrength * sky_toonColor);
        
        // Specular component (Blinn-Phong)
        vec3 viewDir = normalize(camPos - hitPoint);
        vec3 halfwayDir = normalize(lightDir + viewDir);

        float shininess = 1000.0;
        float specularStrength = pow(max(dot(normal, halfwayDir), 0.0), shininess);
        vec3 specularColor = (specularStrength * vec3(1.0)) * shininess;

        




        // Ambient component
        float ambientStrength = 2.50;
        vec3 ambient_color = vec3(0.8, 0.0, 0.0);
        vec3 ambient = sky_toonColor * ambient_color;


        vec3 biPhong_use_color = vec3(0.0, 0.24, 1.0);

        // Combine all components
  
        vec3 total_ambient = sky_ambient;
        vec3 total_diffuse = diffuse + sky_diffuse + plane_sky_diffuse + plane_color;

         vec3 biPhongColor = (total_diffuse + specularColor);
        //biPhongColor = total_diffuse;


            // Toon shader outline
            float outlineThickness = 0.5; // Adjust the thickness of the outline
            float outline = smoothstep(0.5 - outlineThickness, 0.5 + outlineThickness, maps);


        // Mix Bi-Phong and Toon colors
        vec3 finalColor = biPhongColor;
        
             finalColor += rimLighting;
            vec3 outlienColor = vec3(0.02);

         
            // Add some noise to the color
            float noiseValue = noise(hitPoint * 5.1); // Adjust the noise frequency
           // finalColor += noiseValue * .5; // Adjust noise influence


          

            vec3 shadowColor = vec3(0.2);  // Adjust the shadow color

      //      finalColor = mix(biPhongColor,shadowColor,sky_shadowIntensity);
           
         //finalColor = toonShader(1.0,finalColor,5.0);   
        // vec3 test_color = toonShader(3.0,ambient_color,5);

      //  vec3 test_color = mix(finalColor,edge_color,edge_factor);
      line *= 55;
	line = line-1.0;
	line = clamp(line,.0,1.0);
      vec3 colors3 = vec3(line);
    vec3 n_color = scene_normal * 15;
      vec3 test_c = mix(finalColor,n_color,color2);

      vec3 color4 = mix(test_c,vec3(0.0),colors3);
         FragColor = vec4(color4, 1.0);

            return;
        }

        distance -= closestDist;
        if (distance > maxDist) break;
    }

    FragColor = Back_ground_color; // Background color
}