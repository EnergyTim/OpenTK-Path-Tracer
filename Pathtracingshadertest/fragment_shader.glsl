#version 430 core

layout(origin_upper_left) in vec4 gl_FragCoord;

layout(std430, binding = 0) buffer TrianglesBuffer
{
    float triangles[];
};

out vec4 color_out;

vec2 res = vec2(1280.0, 720.0);

const int numberofspheres = 3;
const float pos_infinity = intBitsToFloat(0x7F800000);
int MaxBounceCount = 8;
int NumRaysPerPixel = 2;
vec3 SkyColorHorizon = vec3(1.0, 1.0, 1.0);
vec3 SkyColorZenith = vec3(0.15, 0.6, 1.0);
vec3 GroundColor = vec3(0.5, 0.5, 0.5);
vec3 SunLightDirection = normalize(vec3(1.0, -0.5, 0.2));
float SunFocus = 5.0;
float SunIntensity = 1.0;

struct Ray
{
    vec3 Origin;
    vec3 Direction;
};

struct Material
{
    vec3 Color;
    vec3 EmissionColor;
    float EmissionStrength;
};

struct Sphere
{
    vec3 position;
    float radius;
    Material material;
};

struct Triangle
{
    vec3 posA;
    vec3 posB;
    vec3 posC;
    Material material;
};

struct HitInfo
{
    bool didHit;
    float dst;
    vec3 hitPoint;
    vec3 normal;
    Material material;
};

const Sphere spheres[3] = Sphere[3](
Sphere(vec3(2.0, 3.0, -10.0), 5.0, Material(vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), 0.0)), 
Sphere(vec3(0.0, 0.0, -5.0), 3.0, Material(vec3(0.0, 1.0, 0.0), vec3(0.0, 0.0, 0.0), 0.0)), 
Sphere(vec3(0.0, -100, -10), 97.0, Material(vec3(0.5, 0.0, 0.6), vec3(0.0, 0.0, 0.0), 0.0))\
);

//const Triangle tris[12] = Triangle[12](
//Triangle(vec3(2., -1., -6.1881323), vec3(2., -1., -4.1881323), vec3(2., 1., -4.1881323), Material(vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), 0.0)),
//Triangle(vec3(2., -1., -6.1881323), vec3(2., 1., -4.1881323), vec3(2., 1., -6.1881323), Material(vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), 0.0)),
//Triangle(vec3(2., 1., -6.1881323), vec3(2., 1., -4.1881323), vec3(4., 1., -4.1881323), Material(vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), 0.0)),
//Triangle(vec3(2., 1., -6.1881323), vec3(4., 1., -4.1881323), vec3(4., 1., -6.1881323), Material(vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), 0.0)),
//Triangle(vec3(4., 1., -6.1881323), vec3(4., 1., -4.1881323), vec3(4., -1., -4.1881323), Material(vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), 0.0)),
//Triangle(vec3(4., 1., -6.1881323), vec3(4., -1., -4.1881323), vec3(4., -1., -6.1881323), Material(vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), 0.0)),
//Triangle(vec3(4., -1., -6.1881323), vec3(4., -1., -4.1881323), vec3(2., -1., -4.1881323), Material(vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), 0.0)),
//Triangle(vec3(4., -1., -6.1881323), vec3(2., -1., -4.1881323), vec3(2., -1., -6.1881323), Material(vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), 0.0)),
//Triangle(vec3(2., 1., -6.1881323), vec3(4., 1., -6.1881323), vec3(4., -1., -6.1881323), Material(vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), 0.0)),
//Triangle(vec3(2., 1., -6.1881323), vec3(4., -1., -6.1881323), vec3(2., -1., -6.1881323), Material(vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), 0.0)),
//Triangle(vec3(4., 1., -4.1881323), vec3(2., 1., -4.1881323), vec3(2., -1., -4.1881323), Material(vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), 0.0)),
//Triangle(vec3(4., 1., -4.1881323), vec3(2., -1., -4.1881323), vec3(4., -1., -4.1881323), Material(vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), 0.0))
//);

Material defaultmaterial = Material(vec3(1.0,0.0,0.5), vec3(0.0,0.0,0.0), 0.0);

vec3 GetEnvironmentalLight(Ray ray)
{
    float skyGradientT = pow(smoothstep(0.0, 0.4, ray.Direction.y), 0.35);
    vec3 skyGradient = mix(SkyColorHorizon, SkyColorZenith, skyGradientT);
    float sun = pow(max(0.0, dot(ray.Direction, -SunLightDirection)), SunFocus) * SunIntensity;
    float groundToSkyT = smoothstep(-0.01, 0.0, ray.Direction.y);
    return mix(GroundColor, skyGradient, groundToSkyT) + sun;
}

float RandomValue(inout uint state)
{
    state = state * uint(747796405) + uint(2891336453);
    uint result = ((state >> ((state >> 28) + uint(4)) ^ state) * uint(277803737));
    result = (result >> 22) ^ result;
    return float(result) / 4294967295.0;
}

float RandomValueNormalDistribution(inout uint state)
{
    float theta = 2.0 * 3.1415926 * RandomValue(state);
    float rho = sqrt(-2.0 * log(RandomValue(state)));
    return rho * cos(theta);
}

vec3 RandomDirection(inout uint state)
{
    float x = RandomValueNormalDistribution(state);
    float y = RandomValueNormalDistribution(state);
    float z = RandomValueNormalDistribution(state);
    return normalize(vec3(x, y, z));
}

vec3 RandomDirectionSpherical(inout uint state)
{
    float pi = 3.14159265359;

    float phi = RandomValue(state) * 2 * pi;
    float theta = RandomValue(state) * 2 * pi;

    
    float x = sin(phi) * cos(theta);
    float y = sin(phi) * sin(theta);
    float z = cos(phi);
    return normalize(vec3(x, y, z));
}

vec3 RandomHemisphereDirection(vec3 normal, inout uint state)
{
    vec3 dir = RandomDirectionSpherical(state);
    return dir * sign(dot(normal, dir));
}

HitInfo RayTriangle(Ray ray, Triangle tri)
{
	vec3 edgeAB = tri.posB - tri.posA;
	vec3 edgeAC = tri.posC - tri.posA;
	vec3 normalVector = cross(edgeAB, edgeAC);
	vec3 normal = normalize(normalVector);
	vec3 ao = ray.Origin - tri.posA;
	vec3 dao = cross(ao, ray.Direction);

	float determinant = -dot(ray.Direction, normalVector);
	float invdet = 1 / determinant;
	
	float dst = dot(ao, normalVector) * invdet;
	float u = dot(edgeAC, dao) * invdet;
	float v = -dot(edgeAB, dao) * invdet;
	float w = 1 - u - v;
	
	HitInfo hitInfo;
	hitInfo.didHit = false;

	if (determinant >= 1E-6 && dst >= 0 && u >= 0 && v >= 0 && w >= 0)
	{
		hitInfo.didHit = true;
	}

	hitInfo.hitPoint = ray.Origin + ray.Direction * dst;
	hitInfo.normal = normal * -sign(dot(ray.Direction, normal));
	hitInfo.dst = dst;
	hitInfo.material = tri.material;
	return hitInfo;
}

HitInfo RaySphere(Ray ray, vec3 sphereCentre, float sphereRadius)
{
    HitInfo hitInfo;

    hitInfo.didHit = false;
    hitInfo.dst = pos_infinity;
    
    vec3 offsetRayOrigin = ray.Origin - sphereCentre;
    
    float a = dot(ray.Direction, ray.Direction);
    float b = 2.0 * dot(offsetRayOrigin, ray.Direction);
    float c = dot(offsetRayOrigin, offsetRayOrigin) - sphereRadius * sphereRadius;
    
    float discriminant = b * b - 4.0 * a * c;
    
    if (discriminant >= 0.0) 
    {
        float dst = (-b - sqrt(discriminant)) / (2.0 * a);
        
        if (dst >= 0.0)
        {
            hitInfo.didHit = true;
            hitInfo.dst = dst;
            hitInfo.hitPoint = ray.Origin + ray.Direction * dst;
            hitInfo.normal = normalize(hitInfo.hitPoint - sphereCentre);
        }
    }
    return hitInfo;
}

HitInfo CalculateRayCollision(Ray ray)
{
    HitInfo closestHit;
    
    closestHit.didHit = false;
    closestHit.dst = pos_infinity;
    
    for (int i = 0; i < numberofspheres; i++)
    {
        Sphere sphere = spheres[i];
        HitInfo hitInfo = RaySphere(ray, sphere.position, sphere.radius);
        
        if (hitInfo.didHit && hitInfo.dst < closestHit.dst)
        {
            closestHit = hitInfo;
            closestHit.material = sphere.material;
        }
    }
    
    return closestHit;
    
}

//HitInfo CalculateRayCollisionTriangle(Ray ray)
//{
//    HitInfo closestHit;
//    
//    closestHit.didHit = false;
//    closestHit.dst = pos_infinity;
//    
//    for (int i = 0; i < tris.length(); i++)
//    {
//        Triangle tri = tris[i];
//        HitInfo hitInfo = RayTriangle(ray, tri);
//        
//        if (hitInfo.didHit && hitInfo.dst < closestHit.dst)
//        {
//            closestHit = hitInfo;
//        }
//    }
//    
//    return closestHit;
//    
//}

HitInfo CalculateRayCollisionTriangle(Ray ray)
{
    HitInfo closestHit;
    
    closestHit.didHit = false;
    closestHit.dst = pos_infinity;
    
    for (int i = 0; i < triangles.length(); i += 9)
    {
        Triangle tri = Triangle(vec3(triangles[i], triangles[i+1], triangles[i+2]), vec3(triangles[i+3], triangles[i+4], triangles[i+5]), vec3(triangles[i+6], triangles[i+7], triangles[i+8]), defaultmaterial);

        HitInfo hitInfo = RayTriangle(ray, tri);
        
        if (hitInfo.didHit && hitInfo.dst < closestHit.dst)
        {
            closestHit = hitInfo;
        }
    }
    
    return closestHit;
    
}

vec3 Trace(Ray ray, inout uint state)
{
    vec3 incomingLight = vec3(0.0, 0.0, 0.0);
    vec3 rayColor = vec3(1.0, 1.0, 1.0);
    
    for (int i = 0; i <= MaxBounceCount; i++)
    {
        HitInfo hitInfo = CalculateRayCollisionTriangle(ray);
        if (hitInfo.didHit)
        {
            ray.Origin = hitInfo.hitPoint;
            
            Material material = hitInfo.material;
            
            vec3 DiffuseDirection = RandomHemisphereDirection(hitInfo.normal, state);
            ray.Direction = DiffuseDirection;
            
            vec3 emittedLight = material.EmissionColor * material.EmissionStrength;

            float cosinedist = dot(ray.Direction, hitInfo.normal);

            incomingLight = emittedLight + incomingLight * rayColor;

            //incomingLight += emittedLight * rayColor;

            rayColor *= material.Color * cosinedist;
        }
        else
        {
            incomingLight += GetEnvironmentalLight(ray) * rayColor;
            break;
        }
    }
    return incomingLight;
}

void main()
{
    vec2 FragCoordBottomLeft = gl_FragCoord.xy;
    FragCoordBottomLeft.y = res.y - gl_FragCoord.y;

    vec2 uv = FragCoordBottomLeft.xy / res.xy - vec2(0.5);
    uv.x *= res.x / res.y;
    
    uint pixelIndex = uint(FragCoordBottomLeft.y * res.x + FragCoordBottomLeft.x);
    
    //Ray ray = Ray(vec3(0.0, 2.5, 12.0),  normalize(vec3(uv.x, uv.y, -1.0))); //No antialiasing
    
    vec3 totalIncomingLight = vec3(0.0, 0.0, 0.0);
    
    for (int rayIndex = 0; rayIndex < NumRaysPerPixel; rayIndex++)
    {
        Ray ray = Ray(vec3(0.0, 2.5, 12.0),  normalize(vec3(uv.x + RandomValue(pixelIndex) / res.y, uv.y + RandomValue(pixelIndex) / res.y, -1.0))); //Antialiasing
        totalIncomingLight += Trace(ray, pixelIndex);
    }
    
    vec3 pixelCol = totalIncomingLight / float(NumRaysPerPixel);

    color_out = vec4(pixelCol, 1.0);
}