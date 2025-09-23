#version 300 es
//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.
precision mediump float;
uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

uniform mat4 u_View;
uniform mat4 u_ViewInv;
uniform vec4 u_FlameDir;

uniform float u_Time;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_ModelNor;
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_WorldPos;
out float fs_NoiseOffset;
out vec3 fs_NoiseUVW;
const float PI = 3.14159265358979;
const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

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

float Random1D1( float p ) {
    return fract(sin(p)*437158.5453);
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

float Noise1D(in float st){
    float i = floor(st);
    float f = fract(st);
    float a = Random1D1(i);
    float b = Random1D1(i+1.);
    float u = f * f *  (3.0 - 2.0 * f);
    return mix(a, b, u);
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
float easeInSine(in float x) {
  return 1. - cos((x * PI) / 2.);
}

float sawWave(in float x){
    return fract(x);
}
float easeOutSine(float x) {
  return sin((x * PI) / 2.);
}
void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.
    fs_ModelNor = vs_Nor;
    vec3 FlameDir = normalize(vec3(u_FlameDir));
    float FlameSize = length(u_FlameDir);
    vec3 inNoiseUVW = vec3(vs_Nor) * (2. - 0.7*dot(vec3(vs_Nor),FlameDir)) - u_Time / 500. * pow(3., FlameSize) * FlameDir;
    fs_NoiseUVW = inNoiseUVW;
    float noiseOffset = noiseWorley(inNoiseUVW);
    float burstOffset = noise(inNoiseUVW * 8.0);
    float dotDir = (dot(normalize(vs_Nor), normalize(u_FlameDir)) + 1.0) * 0.5;
    float burstNoise = Noise1D(u_Time / 100.);
    float burstAmp;
    if(burstNoise>0.){
        burstAmp = 0.5*(exp(-burstNoise) + 1.);
    }else{
        burstAmp = 0.5*(-exp(burstNoise) + 1.);
    }
    burstAmp *= max(0., pow(2., (dotDir - 0.7)) - 1.);
    burstAmp *= FlameSize;
    vec4 burstDir = vs_Nor;
    float noiseAmp = easeInSine(dotDir) * FlameSize;
    fs_NoiseOffset = noiseOffset;
    vec4 vs_offset = noiseOffset * vs_Nor * noiseAmp + burstOffset * burstAmp * burstDir;
    vs_offset.w = 0.;
    vec4 modelposition = u_Model * (vs_offset + vs_Pos);   // Temporarily store the transformed vertex positions for use below

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
