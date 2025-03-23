uniform float time;
uniform vec2 screen_size;
const float SCAN_LINE_HEIGHT = 4.0;
const float SCAN_LINE_ALPHA = 0.05;  // Reduced from 0.1
const float SCAN_LINE_SPEED = 1.0;
const float NOISE_STRENGTH = 0.01;    // Reduced from 0.02

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    // Sample the texture
    vec4 pixel = Texel(tex, texture_coords);
    
    // Scanlines
    float scan_line = mod(screen_coords.y + time * SCAN_LINE_SPEED, SCAN_LINE_HEIGHT);
    float scan_alpha = float(scan_line < SCAN_LINE_HEIGHT/2.0) * SCAN_LINE_ALPHA;
    
    // Subtle noise
    float noise = fract(sin(dot(texture_coords + time * 0.01, vec2(12.9898,78.233))) * 43758.5453);
    noise = noise * NOISE_STRENGTH - (NOISE_STRENGTH / 2.0);
    
    // Vignette effect
    vec2 position = (screen_coords / screen_size.xy) - vec2(0.5);
    float vignette = 1.0 - length(position);
    vignette = smoothstep(0.0, 1.0, vignette);
    
    // Combine effects
    pixel.rgb *= (1.0 - scan_alpha);
    pixel.rgb += noise;
    pixel.rgb *= vignette * 1.1; // Slightly boost the center
    
    return pixel;
}
