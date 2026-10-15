// Shared textured dust implementation. tools/build_shaders.py embeds this
// in GLSL (OpenMW) and translates the small common subset to HLSL (MGE XE).
// The wrappers provide dustSampleTexture; no meshes or history buffers are used.
vec3 dustHash(vec3 p)
{
    p = fract(p * vec3(0.1031, 0.1030, 0.0973));
    p += dot(p, p.yxz + 33.33);
    return fract((p.xxy + p.yxx) * p.zyx);
}

// Rotate a flake's local X/Y axes around all three world axes. Each mote has
// stable phases, speeds, and directions; a full turn takes roughly 50-100 s.
void dustAxes(vec3 seed, float seconds, out vec3 axisU, out vec3 axisV)
{
    vec3 speed = mix(vec3(0.065, 0.075, 0.060), vec3(0.115, 0.125, 0.105), seed);
    speed *= step(vec3(0.5, 0.5, 0.5), seed.zxy) * 2.0 - 1.0;
    vec3 angle = seed * 6.2831853 + seconds * speed;
    vec3 s = sin(angle);
    vec3 c = cos(angle);
    axisU = vec3(c.z * c.y, s.z * c.y, -s.y);
    axisV = vec3(c.z * s.y * s.x - s.z * c.x,
                 s.z * s.y * s.x + c.z * c.x, c.y * s.x);
}

vec4 dustMotes(vec3 eye, vec3 ray, float sceneDistance,
                float pixelAngle, float seconds, float density)
{
    const float cellSize = 96.0;
    const float nearDistance = 12.0;
    const float farDistance = 768.0;
    float endDistance = min(sceneDistance, farDistance);
    if (endDistance <= nearDistance)
        return vec4(0.0, 0.0, 0.0, 0.0);

    // Traverse only the grid cells actually crossed by this pixel's ray.
    // 20 steps cover the worst-case diagonal through the 768-unit volume.
    vec3 start = eye + ray * nearDistance;
    vec3 cell = floor(start / cellSize);
    vec3 direction = step(vec3(0.0, 0.0, 0.0), ray) * 2.0 - 1.0;
    vec3 inverseRay = direction / max(abs(ray), vec3(0.000001, 0.000001, 0.000001));
    vec3 boundary = (cell + step(vec3(0.0, 0.0, 0.0), ray)) * cellSize;
    vec3 nextCrossing = (boundary - start) * inverseRay + nearDistance;
    vec3 crossingDelta = abs(inverseRay) * cellSize;
    float entered = nearDistance;
    // Front-to-back premultiplied color, with coverage in alpha.
    vec4 dust = vec4(0.0, 0.0, 0.0, 0.0);

    for (int i = 0; i < 20; ++i)
    {
        if (entered >= endDistance)
            break;

        vec3 seed = dustHash(cell);
        if (fract(seed.x * 17.0 + seed.y * 29.0) < density)
        {
            // Keep centers well inside their cells, including all drift.
            // This avoids popping at cell boundaries and camera movement.
            vec3 drift = sin(seed * 6.2831853 + seconds * vec3(0.31, 0.23, 0.17)) * 0.08;
            vec3 center = (cell + 0.2 + seed * 0.6 + drift) * cellSize;
            vec3 offset = center - eye;
            float along = dot(offset, ray);
            vec3 perpendicular = offset - along * ray;
            // Include the transparent border of the original dust texture.
            float radius = mix(0.8, 2.0, seed.z);
            float footprint = max(radius, along * pixelAngle * 0.75);
            // Reject pixels outside the flake's bounding sphere before trig
            // and texture work. The image, rather than this bound, sets shape.
            if (along > nearDistance && along < endDistance + footprint &&
                dot(perpendicular, perpendicular) < 2.0 * footprint * footprint)
            {
                vec3 axisU, axisV;
                dustAxes(seed, seconds, axisU, axisV);
                vec3 normal = cross(axisU, axisV);
                float facing = dot(ray, normal);
                // Intersect the ray with the actual rotating plane. This
                // foreshortens and flips the image as the flake turns over.
                if (abs(facing) > 0.001)
                {
                    float hit = dot(offset, normal) / facing;
                    vec3 local = ray * hit - offset;
                    vec2 uv = vec2(dot(local, axisU), dot(local, axisV)) / (2.0 * footprint) + 0.5;
                    if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0)
                    {
                        // Explicit LOD works inside divergent loops on SM3.
                        // Preserve coverage when a flake is below pixel size.
                        float lod = max(0.0, log2(128.0 * max(along * pixelAngle, 0.00001) /
                                                  (footprint * max(abs(facing), 0.01))));
                        vec4 texel = dustSampleTexture(uv, lod);
                        float visibility = smoothstep(nearDistance, 36.0, hit);
                        visibility *= 1.0 - smoothstep(512.0, farDistance, hit);
                        visibility *= clamp((sceneDistance - hit - 0.5) / 4.0, 0.0, 1.0);
                        float mote = texel.a * visibility * 0.85;
                        mote *= radius * radius / (footprint * footprint);
                        dust += (1.0 - dust.a) * vec4(texel.rgb * mote, mote);
                    }
                }
            }
        }

        float crossing = min(nextCrossing.x, min(nextCrossing.y, nextCrossing.z));
        // Advance all tied axes, including rays exactly on edges/corners.
        vec3 axes = step(nextCrossing, vec3(crossing, crossing, crossing));
        cell += axes * direction;
        nextCrossing += axes * crossingDelta;
        entered = crossing;
    }
    return dust;
}

vec3 dustComposite(vec3 scene, vec4 dust)
{
    // Approximate illumination from the scene: subtle motes in dark rooms,
    // brighter in lit rooms. This is not a local-light or shadow simulation.
    float illumination = clamp(dot(scene, vec3(0.2126, 0.7152, 0.0722)) * 2.2 + 0.06, 0.06, 1.0);
    // Lift the dark source albedo so the textured motes remain visible.
    return scene * (1.0 - dust.a) + dust.rgb * (1.6 * illumination);
}
