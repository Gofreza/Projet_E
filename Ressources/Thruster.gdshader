shader_type spatial;

uniform vec4 color : source_color = vec4(1.0, 0.5, 0.0, 1.0);
uniform float intensity = 1.0;
uniform float speed = 1.0;
uniform float noise_scale = 1.0;

float random(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = FRAGCOORD.xy / VIEWPORT_SIZE;
    uv = uv * 2.0 - 1.0; // Convert to normalized device coordinates
    
    float noise = random(uv * noise_scale);
    float flame = max(0.0, 1.0 - length(uv) * 2.0);
    flame += noise * 0.1;
    
    vec4 flame_color = color * flame * intensity;
    
    ALBEDO = flame_color.rgb;
    ALPHA = flame_color.a;
}

void vertex() {
    float time = TIME * speed;
    VERTEX.y += sin(VERTEX.x * 10.0 + time) * 0.1;
}
