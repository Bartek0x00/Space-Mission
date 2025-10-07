shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_prepass_alpha;

// --------------------------------------------------
// Flame controls
// --------------------------------------------------
uniform float intensity : hint_range(0.0, 1.0) = 0.0; // 0 = off, 1 = full flame
uniform vec3 flame_color : source_color = vec3(0.1, 0.2, 1.0); // bluish
uniform float max_length = 3;      // flame length when intensity=1
uniform float wobble_strength = 0.05; // wobble magnitude
uniform float wobble_speed = 1.5;     // wobble speed
uniform float tip_wobble = 2.0;       // multiplier at tip
uniform float fade_power = 3.0;       // how quickly it fades out
uniform float base_alpha = 0.8;       // opacity near nozzle

// varyings
varying float v_t;
varying float v_wobble;

void vertex() {
    // normalize Y along flame (assume nozzle at y=0, tip at y=max_length)
    float y_norm = clamp(VERTEX.y / max_length, 0.0, 1.0);

    // flame length scales with intensity (always attached at nozzle)
    float new_y = y_norm * max_length * intensity;

    // compute wobble amount: stronger toward the tip
    float wobble = wobble_strength * mix(1.0, tip_wobble, y_norm);
    float noise = sin((VERTEX.y * 4.0 + TIME * wobble_speed) + VERTEX.x * 3.0) *
                  cos((VERTEX.z * 4.0 + TIME * wobble_speed * 0.8));
    VERTEX.xz += normalize(VERTEX.xz + 0.001) * noise * wobble * intensity;

    // store normalized position and wobble for fragment
    v_t = y_norm;
    v_wobble = noise;

    // apply new flame length
    VERTEX.y = new_y;
}

void fragment() {
    if (intensity <= 0.001) {
        ALPHA = 0.0;
        discard;
    }

    // base bluish color — fades from bright to transparent along flame
    vec3 color = mix(vec3(0.1, 0.3, 1.0), flame_color, 1.0 - v_t);
    color *= 0.5 + 0.5 * intensity; // desaturate when low intensity

    // alpha falloff
    float alpha = pow(1.0 - v_t, fade_power) * base_alpha * intensity;

    // slight flicker using v_wobble
    float flicker = 0.9 + 0.1 * v_wobble;
    alpha *= flicker;
    vec3 emission = color * (1.5 + 1.5 * flicker);

    ALBEDO = color;
    EMISSION = emission;
    ALPHA = clamp(alpha, 0.0, 1.0);
}
