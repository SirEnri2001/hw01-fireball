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

// code modified from https://www.shadertoy.com/view/XslGRr
float map( in vec3 p, int oct )
{
	vec3 q = p - vec3(0.0,0.1,1.0);
    float g = 0.5+0.5*noise( q*0.3 );
    
	float f;
    f  = 0.50000*noise( q ); q = q*2.02;
    f += 0.25000*noise( q ); q = q*2.23;
    f += 0.12500*noise( q ); q = q*2.41;
    f += 0.06250*noise( q ); q = q*2.62;
    f += 0.03125*noise( q ); 
    
    f = mix( f*0.1-0.5, f, g*g );
        
    return 1.5*f - 0.5 - p.y;
}
float atan2(in float y, in float x)
{
    bool s = (abs(x) > abs(y));
    return mix(PI/2.0 - atan(x,y), atan(y,x), s);
}
const int kDiv = 1; // make bigger for higher quality
vec4 raymarch( in vec3 ro, in vec3 rd, in vec3 bgcol)
{
    // bounding planes	
    const float yb = -5.0;
    const float yt =  5.0;
    float tb = (yb-ro.y)/rd.y;
    float tt = (yt-ro.y)/rd.t;

    // find tigthest possible raymarching segment
    float tmin, tmax;
    if( ro.y>yt )
    {
        // above top plane
        if( tt<0.0 ) return vec4(0.0); // early exit
        tmin = tt;
        tmax = tb;
    }
    else
    {
        // inside clouds slabs
        tmin = 0.0;
        tmax = 60.0;
        if( tt>0.0 ) tmax = min( tmax, tt );
        if( tb>0.0 ) tmax = min( tmax, tb );
    }
    
    // dithered near distance
    float t = tmin + 0.1*Hash21(rd.xy);
    // raymarch loop
	vec4 sum = vec4(0.0);
    for( int i=0; i<190*kDiv; i++ )
    {
       // step size
       float dt = max(0.05,0.02*t/float(kDiv));

       // lod
       int oct = 5 - int( log2(1.0+t*0.5) );
       
       // sample cloud
       vec3 pos = ro + t*rd;
        
        vec3 worldPos = ro + t*rd;
        vec3 lighrRecvDirection = Random3D(worldPos);
        float inCube = checkInCube(vec4(worldPos, 1.));
        float den = 0.2 * inCube;
       if(den>0.01 ) // if inside
       {
            float fTime = float(u_Time);
            vec3 pos1 = pos;
            pos1 *= 1./length(pos1.z);
            float theta = fTime / 5000. * pos1.z;
            pos1.xy = vec2(cos(theta) * pos1.x + sin(theta) * pos1.y, -sin(theta) * pos1.x + cos(theta) * pos1.y);
            den *= fBMWorley( 2.*pos1, 2.0, 0.5, 4 );
           vec3  lin = vec3(0.65,0.65,0.75)*1.1;
           vec3  lin2 = vec3(0.95,0.85,0.65)*1.1;
           vec4  col = vec4( mix( vec3(1.0,1,1), vec3(0.,0.,0.), den ), den );
           col.xyz *=u_Color.xyz + vec3(0.1,0.1,0.1);
           if(length(pos)<0.3){
            col.xyz += lin / length(pos) /3.3333;
           }
           if(length(pos.xy)<0.2){
           col.xyz *= lin / length(pos.xy) /3.3333;
           }
           if(length(pos)<0.7){
            col.xyz *= lin2 * (0.7 - length(pos));
           }
           col.w    = min(col.w*8.0*dt,1.0);
           col.rgb *= col.a;
           sum += col*(1.0-sum.a);
       }
       // advance ray
       t += dt;
       // until far clip or full opacity
       if( t>tmax || sum.a>0.99 ) break;
    }

    return clamp( sum, 0.0, 1.0 );
}


mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main1(){
    vec2 fRes = vec2(u_Resolution);
    vec2 p = (2.*gl_FragCoord.xy-fRes.xy)/fRes.y;

    // camera
    vec3 ro = u_Eye.xyz;
	vec3 ta = u_CameraTarget.xyz;
    mat3 ca = setCamera( ro, ta, 0.);
    // ray
    vec3 rd = ca * normalize( vec3(p.xy,1.5));
    out_Col = raymarch( ro, rd, vec3(0.));
    out_Col.w = 1.;
}

// cosine based palette, 4 vec3 params
vec3 palette( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.283185*(c*t+d) );
}

vec3 fire_palette(in float t){
    return palette((1.-t)*(1.-t), vec3(0.5, 0.5, 0.5),vec3(0.5, 0.5, 0.5), vec3(1.0, 1.0, 1.0), vec3(0.00, 0.10, 0.20));
}

void main()
{
    // Material base color (before shading)
    vec3 FlameDir = normalize(vec3(u_FlameDir));
    float FlameSize = length(u_FlameDir);
    float FlameAmp = (noise(fs_NoiseUVW * 4.)+fs_NoiseOffset)*0.5 * FlameSize;
    float FireTemperature = atan(FlameAmp*2.) / PI * 2.;
    out_Col = vec4(fire_palette(FireTemperature), 1.);
    return;
}
