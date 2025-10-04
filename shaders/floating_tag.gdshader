shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled;

uniform float near_distance : hint_range(0.1, 50.0) = 0.0;
uniform float far_distance : hint_range(50.0, 1000.0) = 100.0;
uniform float near_scale : hint_range(0.1, 5.0) = 1.0;
uniform float far_scale : hint_range(0.1, 64.0) = 48.0;
uniform sampler2D albedo_texture : source_color;

uniform float scale_curve = 0.5;

void vertex() {
	vec3 world_center = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float dist = distance(CAMERA_POSITION_WORLD, world_center);

	float t = clamp((dist - near_distance) / max(0.0001, (far_distance - near_distance)), 0.0, 1.0);
	t = pow(t, scale_curve);
	float scale_factor = mix(near_scale, far_scale, t);

	vec3 cam_right = MAIN_CAM_INV_VIEW_MATRIX[0].xyz;
	vec3 cam_up    = MAIN_CAM_INV_VIEW_MATRIX[1].xyz;
	
	vec3 world_pos = world_center
		+ cam_right * (VERTEX.x * scale_factor)
		+ cam_up    * (VERTEX.y * scale_factor);
	
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world_pos, 1.0);
	UV = UV;
}

void fragment() {
	vec4 color = texture(albedo_texture, UV);

	ALBEDO = color.rgb;
	ALPHA = color.a;
}