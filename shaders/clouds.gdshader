// Based on: https://www.reddit.com/r/godot/comments/gxqsaj/comment/ft49hkn/?utm_source=share&utm_medium=web2x&context=3
shader_type spatial;

uniform sampler2D noise_texture;
uniform float speed : hint_range(0.0, 1.0) = 0.005;
uniform float brightness : hint_range(0.0, 2.0) = 0.5;
uniform float threshold : hint_range(0.0, 2.0) = 1.2;
uniform float fluffiness : hint_range(0.0, 2.0) = 0.1;

uniform float distance_fade_min : hint_range(0.0, 4096.0, 0.01) = 2500.0;
uniform float distance_fade_max : hint_range(0.0, 4096.0, 0.01) = 2000.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 noise_1 = texture(noise_texture, mod(UV + TIME * 2.5 * speed / 10.0, 0.0));
	vec4 noise_2 = texture(noise_texture, mod(UV + TIME * (2.5 + fluffiness * 3.0) * speed / 10.0, 0.0));
	vec4 combined_noise = noise_1 + noise_2;
	ALBEDO = combined_noise.rgb * brightness;
	ALPHA = 1.0;
	if (combined_noise.r < threshold) {
		ALPHA = 0.0;
	}
	
	float fade_distance = distance(CAMERA_POSITION_WORLD, world_pos);
	// --- Now apply your original Distance Fade: Pixel Dither (unchanged mechanics) ---
	const vec3 magic = vec3(0.06711056, 0.00583715, 52.9829189);
	float fade = clamp(smoothstep(distance_fade_min, distance_fade_max, fade_distance), 0.0, 1.0);
	// Keep the hard cap dither as before — this will run for both expensive and fallback paths.
	if (fade < 0.001 || fade < fract(magic.z * fract(dot(FRAGCOORD.xy, magic.xy)))) {
		discard;
	}
}