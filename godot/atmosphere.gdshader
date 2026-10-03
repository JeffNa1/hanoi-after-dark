shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
void fragment() {
    vec3 color = texture(screen_texture, SCREEN_UV).rgb;
    float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
    color = mix(vec3(luma), color, 0.90);
    float shadow = 1.0-smoothstep(0.08, 0.5, luma);
    color *= mix(vec3(1.0), vec3(0.92, 1.01, 1.055), shadow*0.35);
    vec2 p = SCREEN_UV*2.0-1.0;
    float edge = smoothstep(0.30, 1.65, dot(p,p));
    color *= 1.0-edge*0.10;
    COLOR = vec4(color, 1.0);
}
