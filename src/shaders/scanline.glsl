uniform float time;
uniform vec2 screen_size;
#define SCAN_LINE_HEIGHT (4.0 * (screen_size.y / 600.0))  // Scale with resolution
#define SCAN_LINE_ALPHA 0.1
#define SCAN_LINE_SPEED 10.0
#define NOISE_STRENGTH (0.02 * (screen_size.y / 600.0))   // Scale with resolution

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    // Sample the texture
    vec4 pixel = Texel(tex, texture_coords);
    
    // Scanlines - thinner and more subtle
    float scan_line = mod(screen_coords.y + time * SCAN_LINE_SPEED, SCAN_LINE_HEIGHT);
    float scan_alpha = float(scan_line < SCAN_LINE_HEIGHT/2.0) * SCAN_LINE_ALPHA;
    
    // Subtle noise
    float noise = fract(sin(dot(texture_coords + time * 0.01, vec2(12.9898,78.233))) * 43758.5453);
    noise = noise * NOISE_STRENGTH - (NOISE_STRENGTH / 2.0);
    
    // Vignette effect - you might want to adjust this too
    vec2 position = (screen_coords / screen_size.xy) - vec2(0.5);
    float vignette = 1.0 - length(position);
    vignette = smoothstep(0.0, 1.0, vignette);
    
    // Combine effects
    pixel.rgb *= (1.0 - scan_alpha);
    pixel.rgb += noise;
    pixel.rgb *= vignette * 1.1; // Slightly boost the center
    
    return pixel;
}


