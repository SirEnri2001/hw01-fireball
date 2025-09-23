#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision mediump float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_ModelNor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_WorldPos;
in vec3 fs_NoiseUVW;
in float fs_NoiseOffset;
uniform ivec2 u_Resolution;

uniform mat4 u_View;
uniform mat4 u_ViewInv;
uniform vec4 u_Eye;
uniform vec4 u_CameraTarget;
uniform float u_Time;
uniform vec4 u_FlameDir;
uniform float u_FlameSize;
uniform float u_FlameBurst;
uniform float u_BurstSpeed;
uniform float u_WindSpeed;
uniform float u_Brightness;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.


float checkInCube(vec4 pos){
    if(pos.x>1. || pos.x<-1.){
        return 0.;
    }
    if(pos.y>1. || pos.y<-1.){
        return 0.;
    }
    if(pos.z>1. || pos.z<-1.){
        return 0.;
    }
    return 1.;
}

#define PI 3.14159265359

const vec3 sundir = vec3(-0.7071,0.0,-0.7071);
float GetIntegerNoise(vec2 p)  // replace this by something better, p is essentially ivec2
{
    p  = 53.7 * fract( (p*0.3183099) + vec2(0.71,0.113));
    return fract( p.x*p.y*(p.x+p.y) );
}

float Hash(float f)
{
    return fract(sin(f)*43758.5453);
}

float Hash21(vec2 v)
{
    return Hash(dot(v, vec2(253.14, 453.74)));
}

float Hash31(vec3 v)
{
    return Hash(dot(v, vec3(253.14, 453.74, 183.3)));
}

vec3 Random3D( vec3 p ) {
    return fract(sin(vec3(dot(p,vec3(127.1,311.7,217.3)),dot(p,vec3(269.5,183.3,431.1)), dot(p,vec3(365.6,749.9,323.7))))*437158.5453);
}

float Random3D1( vec3 p ) {
    return fract(sin(dot(p,vec3(127.1,311.7,217.3)))*437158.5453);
}

float Noise3D (in vec3 st) {
    vec3 i = floor(st);
    vec3 f = fract(st);

    // Four corners in 2D of a tile
    float a = Random3D1(i);
    float b = Random3D1(i + vec3(1.0, 0.0, 0.0));
    float c = Random3D1(i + vec3(0.0, 1.0, 0.0));
    float d = Random3D1(i + vec3(1.0, 1.0, 0.0));
    
    float a1 = Random3D1(i + vec3(0.,  0.,  1.));
    float b1 = Random3D1(i + vec3(1.0, 0.0,  1.));
    float c1 = Random3D1(i + vec3(0.0, 1.0,  1.));
    float d1 = Random3D1(i + vec3(1.0, 1.0,  1.));

    vec3 u = f * f * (3.0 - 2.0 * f);

    float m0 = mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;

    float m1 = mix(a1, b1, u.x) +
            (c1 - a1)* u.y * (1.0 - u.x) +
            (d1 - b1) * u.x * u.y;
    return mix(m0, m1, u.z);
}

vec2 Rotate2D(vec2 v, float theta)
{
    float c = cos(theta);
    float s = sin(theta);
    
    mat2 rotMat = mat2(c,s,-s,c);
    return rotMat * v;
}

vec4 GetWorleyNoise3D(vec3 uvw)
{
    float noise = 0.0;
    
    vec3 p = floor(uvw);
    vec3 f = fract(uvw);
    
    vec4 res = vec4(1.0);
    for(int x = -1; x <=1; ++x)
    {
        for(int y = -1; y <=1; ++y)
        {
            for(int z = -1; z <=1; ++z)
            {
                vec3 gp = p + vec3(x, y, z);	//grid point

                vec3 v = Random3D(gp);

				vec3 diff = gp + v - uvw;
                
                float d = length(diff);
                
                if(d < res.x)
                {
                    res.xyz = vec3(d, res.x, res.y);
                }
                else if(d < res.y)
                {
                    res.xyz = vec3(res.x, d, res.y);
                }
                else if(d < res.z)
                {
                    res.z = d;
                }
                
                res.w = Hash31(gp);
            }
        }
    }

    return res;
}

float fBMWorley(vec3 x, float lacunarity, float gain, int numOctaves)
{
    float total = 0.0;
    float frequency = 1.0;
    float amplitude = 1.0;
	float totalAmplitude = 0.0;
    for(int i = 0; i < numOctaves; ++i)
    {
        totalAmplitude += amplitude;
        
        vec4 n = GetWorleyNoise3D(x * frequency);
        total += amplitude * n.x;
        
        frequency *= lacunarity;
        amplitude *= gain;
    }
    
    return total/totalAmplitude;
}

float fbm(vec3 x, float lacunarity, float gain, int numOctaves)
{
    float total = 0.0;
    float frequency = 1.0;
    float amplitude = 1.0;
	float totalAmplitude = 0.0;
    for(int i = 0; i < numOctaves; ++i)
    {
        totalAmplitude += amplitude;
        
        float n = Noise3D(x * frequency);
        total += amplitude * n;
        
        frequency *= lacunarity;
        amplitude *= gain;
    }
    
    return total/totalAmplitude;
}

float noiseWorley( in vec3 x )
{
    return fBMWorley(x, 2.0, 0.5, 4);
}

float noise( in vec3 x)
{
    return fbm(x, 2.0, 0.5, 4);
}

float atan2(in float y, in float x)
{
    bool s = (abs(x) > abs(y));
    return mix(PI/2.0 - atan(x,y), atan(y,x), s);
}

// cosine based palette, 4 vec3 params
vec3 palette( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.283185*(c*t+d) );
}

vec3 default_fireball_palette[] = vec3[](
    vec3(0.5,0.5,0.5), vec3(0.5, 0.5, 0.5), vec3(1., 1., 1.), vec3(0.2, 0.1, 0.0)
);
vec3 default_fireball_palette1[] = vec3[](
vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(2.0,1.0,0.0),vec3(0.5,0.20,0.25)
);
vec3 black_white_palette[] = vec3[](
vec3(0.,0.,0.),vec3(1.,1.,1.),vec3(0.25,0.25,0.25),vec3(0.75,0.75,0.75)
);

vec3 fire_palette(in float t, in vec3 args_palette[4]){
    return palette(t, args_palette[0],args_palette[1], args_palette[2], args_palette[3]);
}

void main()
{
    // Material base color (before shading)
    vec3 FlameDir = normalize(vec3(u_FlameDir));
    float FlameSize = u_FlameSize;
    float FlameAmp = (noise(fs_NoiseUVW * 4.)+fs_NoiseOffset)*0.5;

    float t = min(1., max(0., mix(0.0+u_Brightness*0.3, 0.3+u_Brightness * 0.7, FlameAmp)));

    out_Col = vec4(fire_palette(t, default_fireball_palette), 1.);
    return;
}
