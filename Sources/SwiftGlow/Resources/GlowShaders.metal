#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

struct GlowLayerUniform {
    float coverage;
    float opacity;
    float relativeOffset;
    float placement;
    float progress;
    float4 glowSize;
};

struct GlowUniforms {
    float2 resolution;
    float2 rectSize;
    float cornerRadius;
    float borderWidth;
    float borderProgress;
    uint layerCount;
    float masterOpacity;
    float isBorderAnimated;
    float4 backgroundColor;
    GlowLayerUniform layers[10];
    float4 borderColors[8];
    float4 layerColors[80];
};

vertex VertexOut glowVertex(const device float2 *vertices [[buffer(0)]], uint vertexID [[vertex_id]]) {
    VertexOut out;
    out.position = float4(vertices[vertexID], 0, 1);
    out.uv = vertices[vertexID] * 0.5 + 0.5;
    return out;
}

static float smoothCubic(float t) {
    return t * t * (3.0 - 2.0 * t);
}

static float sdfRoundedBox(float2 p, float2 b, float r) {
    float2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

static float calculatePerimeterProgress(float2 p, float2 b, float r) {
    constexpr float pi = 3.14159265359;
    float w = b.x - r;
    float h = b.y - r;
    float c = pi * r / 2.0;
    float horizontal = 2.0 * w;
    float vertical = 2.0 * h;
    float s0End = c;
    float s1End = s0End + horizontal;
    float s2End = s1End + c;
    float s3End = s2End + vertical;
    float s4End = s3End + c;
    float s5End = s4End + horizontal;
    float s6End = s5End + c;
    float perimeter = s6End + vertical;
    if (perimeter == 0.0) {
        return 0.0;
    }

    float dist = 0.0;
    if (p.x < -w) {
        if (p.y < -h) {
            float2 corner = p - float2(-w, -h);
            dist = c * ((atan2(corner.y, corner.x) + pi) / (pi / 2.0));
        } else if (p.y > h) {
            float2 corner = p - float2(-w, h);
            dist = s5End + c * ((atan2(corner.y, corner.x) - pi / 2.0) / (pi / 2.0));
        } else {
            dist = s6End + (h - p.y);
        }
    } else if (p.x > w) {
        if (p.y < -h) {
            float2 corner = p - float2(w, -h);
            dist = s1End + c * ((atan2(corner.y, corner.x) + pi / 2.0) / (pi / 2.0));
        } else if (p.y > h) {
            float2 corner = p - float2(w, h);
            dist = s3End + c * (atan2(corner.y, corner.x) / (pi / 2.0));
        } else {
            dist = s2End + (h + p.y);
        }
    } else {
        if (p.y < 0.0) {
            dist = s0End + (w + p.x);
        } else {
            dist = s4End + (w - p.x);
        }
    }
    return dist / perimeter;
}

static float interpolatedSize(float progress, float4 sizes) {
    float segmentLength = 1.0 / 3.0;
    if (progress < segmentLength) {
        return mix(sizes.x, sizes.y, smoothCubic(progress / segmentLength));
    }
    if (progress < 2.0 * segmentLength) {
        return mix(sizes.y, sizes.z, smoothCubic((progress - segmentLength) / segmentLength));
    }
    return mix(sizes.z, sizes.w, smoothCubic((progress - 2.0 * segmentLength) / segmentLength));
}

static float gaussian(float x, float mu, float sigma) {
    if (sigma <= 0.0) {
        return 0.0;
    }
    return exp(-(pow(x - mu, 2.0)) / (2.0 * pow(sigma, 2.0)));
}

static float4 gradientColor(float progress, const constant float4 *colors) {
    float t = progress * 7.0;
    float4 finalColor = colors[7];
    for (int i = 6; i >= 0; i--) {
        if (t < float(i + 1)) {
            finalColor = mix(colors[i], colors[i + 1], t - float(i));
        }
    }
    return finalColor;
}

fragment float4 glowFragment(VertexOut in [[stage_in]], constant GlowUniforms &uniforms [[buffer(0)]]) {
    float2 fragCoord = in.uv * uniforms.resolution;
    float2 center = uniforms.resolution * 0.5;
    float2 p = fragCoord - center;
    float2 b = uniforms.rectSize * 0.5;
    float d = sdfRoundedBox(p, b, uniforms.cornerRadius);
    float perimeterProgress = calculatePerimeterProgress(p, b, uniforms.cornerRadius);

    float4 behindGlow = float4(0.0);
    float4 frontGlow = float4(0.0);

    for (uint i = 0; i < 10; i++) {
        if (i >= uniforms.layerCount) {
            break;
        }
        GlowLayerUniform layer = uniforms.layers[i];
        float animatedProgress = fract(perimeterProgress - layer.progress + layer.relativeOffset);
        if (animatedProgress > layer.coverage || layer.coverage == 0.0) {
            continue;
        }
        float segmentProgress = animatedProgress / layer.coverage;
        float currentGlowSize = interpolatedSize(segmentProgress, layer.glowSize);
        float calculatedOpacity = gaussian(abs(d), 0.0, currentGlowSize);
        if (d > 0.0 && layer.placement == 1.0) {
            calculatedOpacity = 0.0;
        }
        if (calculatedOpacity > 0.0) {
            float4 color = gradientColor(segmentProgress, &uniforms.layerColors[i * 8]);
            float4 glowComponent = color * calculatedOpacity * layer.opacity;
            if (layer.placement == 0.0) {
                behindGlow += glowComponent;
            } else {
                frontGlow += glowComponent;
            }
        }
    }

    float4 finalColor = behindGlow;
    if (d <= 0.0) {
        finalColor = mix(finalColor, uniforms.backgroundColor, uniforms.backgroundColor.a);
    }
    finalColor += frontGlow;

    if (uniforms.isBorderAnimated > 0.5 && uniforms.borderWidth > 0.0) {
        float borderDistance = abs(d);
        float halfWidth = uniforms.borderWidth / 2.0;
        float borderStrength = 1.0 - smoothstep(halfWidth - 1.0, halfWidth + 1.0, borderDistance);
        if (borderStrength > 0.0) {
            float borderAnimatedProgress = fract(perimeterProgress - uniforms.borderProgress);
            float4 borderColor = gradientColor(borderAnimatedProgress, uniforms.borderColors);
            finalColor = mix(finalColor, borderColor, borderStrength);
        }
    }

    return finalColor * uniforms.masterOpacity;
}
