shader_type canvas_item;
render_mode unshaded;

uniform float warning : hint_range(0.0, 1.0) = 0.0;
uniform vec4 warn_color : source_color = vec4(1.0, 0.702, 0.278, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.65;

void fragment() {
    COLOR.rgb = mix(COLOR.rgb, warn_color.rgb, warning * strength);
}
