shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D viewport_texture;

void fragment() {
	ALBEDO = texture(viewport_texture, SCREEN_UV).rgb;
}