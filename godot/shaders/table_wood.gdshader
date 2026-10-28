shader_type spatial;

group_uniforms colour;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float brightness : hint_range(0.0, 2.0) = 1.0;

group_uniforms surface;

uniform sampler2D roughness_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float roughness_scale : hint_range(0.0, 1.0) = 1.0;
uniform float normal_strength : hint_range(0.0, 2.0) = 1.0;

group_uniforms mapping;

uniform float uv_scale : hint_range(0.25, 8.0) = 1.0;

group_uniforms;

void fragment() {
    vec2 uv = UV * uv_scale;

    ALBEDO = texture(albedo_tex, uv).rgb * tint.rgb * brightness;
    ROUGHNESS = texture(roughness_tex, uv).r * roughness_scale;
    NORMAL_MAP = texture(normal_tex, uv).rgb;
    NORMAL_MAP_DEPTH = normal_strength;
}
