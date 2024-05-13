#define MAX_STEP 100.
const float EPS = 0.001;
const float MAX = 1000.;

const vec3 bgCol = vec3(0.027,0.398,0.545);
const vec3 lPos = vec3(10.);
const vec3 lCol = vec3(0.940,0.871,0.853);

float map(float v, float v1, float v2, float v3, float v4){
    float a, b;
    a = (v4-v3)/(v2-v1);
    b = v3- a*v1;
    return a*v+ b;
}

float n(float f1, float f2){ return max(f1,f2); }
float u(float f1, float f2){ return min(f1,f2); }
float diff(float f1, float f2){ return max(f1,-f2); }

float sphereSDF(vec3 ray, float r){
    return distance(ray, vec3(0.))-r;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}


float SDF(vec3 ray){
    // ray *= rotate()
    float result;
    
    float s1 = sphereSDF(ray, 1.);
    float b1 = sdBox(ray, vec3(.8));
    result = n(s1, b1);
    
    float s2 = sphereSDF(ray, 0.918);
    result = diff(result, s2);
    
    float s3 = sphereSDF(ray, 0.392);
    result = u(result, s3);
    
    return result;

}

vec3 getN(vec3 p){
    vec2 e = vec2(EPS, 0.);
    
    float dx = SDF(p)-SDF(p-e.xyy);
    float dy = SDF(p)-SDF(p-e.yxy);
    float dz = SDF(p)-SDF(p-e.yyx);
    return normalize(vec3(dx, dy, dz));
}

float intersect(vec3 cam, vec3 dir){
    float md = 0.;
    
    vec3 p;
    for(int i=0; i<100; ++i){
        p = cam + dir*md;
        
        float d = SDF(p);
        if(d<EPS){
            return md;
        }
        md += d;
        if(md>MAX){
            return MAX;
        }
    }
    return MAX;
}

vec3 shading(vec3 a,vec3 d,vec3 s,float smoothness,float metalic,vec3 p,vec3 cam)
{    
    float fresnel = metalic;
    
    vec3 N = getN(p);
    vec3 L = normalize(lPos - p);
    vec3 C = normalize(cam - p);
    vec3 H = normalize(L + C);
    
    float dp = clamp(dot(N, L), 0., 1.);
    float sp = pow(clamp(dot(H, N), 0., 1.), smoothness);
    float ap = pow(1.-clamp(dot(N, C), 0., 1.), map(pow(metalic, .5), 0., 1., 5., 2.));
    
    vec3 diffuse = d*dp*lCol;
    vec3 specular = s*sp;
    vec3 ambient = a*ap;
    
    vec3 retCol = diffuse*(1.-fresnel) + specular*fresnel + ambient;
    
    return retCol;
}

mat3 rotate(vec3 axis, float angle){
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s, 
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c);
}


mat3 easyCam( vec2 angle ) {// peasyCam effect
    vec2 t = angle;
    angle.x = t.y*-1.;
    angle.y = t.x;
	vec2 c = cos( angle );
	vec2 s = sin( angle );
	
	return mat3(c.y      ,  0.0, -s.y,
                s.y * s.x,  c.x,  c.y * s.x,
                s.y * c.x, -s.x,  c.y * c.x);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord/iResolution.xy;
    uv = uv*2.-1.;
    uv.x *= iResolution.x/iResolution.y;
    
    vec3 cam = vec3(0,0,3);
    vec3 dir = normalize(vec3(uv, -1.));
    
    vec2 mouse = iMouse.xy/iResolution.xy;
    mouse = mouse*2.-1.;
    mouse *= 5.;
    cam *= easyCam(mouse);
    dir *= easyCam(mouse);
    float dist = intersect(cam, dir);
    
    vec3 col;    
	if(dist>MAX-EPS){
        col = bgCol;
        vec3 C2L = normalize(lPos-cam);
        
        float sunR = pow(clamp(dot(dir, C2L), 0., 1.), 10.);
        col = mix(col, lCol, sunR);
        fragColor = vec4(col, 1.);
        return;
    }    
    
    vec3 p = cam + dir*dist;
    vec3 a = bgCol;
    vec3 d = vec3(0.449,0.995,0.094);
    vec3 s = lCol;
    float smoothness = 1000.120;
    float metalic = 0.860; 
    col = shading(a,d,s,smoothness,metalic,p,cam);
    fragColor = vec4(col,1.0);
}
