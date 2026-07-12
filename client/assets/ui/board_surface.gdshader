// board_surface.gdshader — normal-mapped torch lighting for the Contract Board surround.
// Board Dynamic Lighting v1 (TD-047). Godot's Light2D does NOT reach these Control nodes
// (verified: a PointLight2D cranked to energy 8 changed nothing), so the lighting is done
// here from UNIFORM lights sampling a normal map — the robust fallback the spec flagged.
// Hybrid: N·L relief (from the normal) + an ember rim/warmth. Render-only (I1/I2).
shader_type canvas_item;

uniform sampler2D normal_tex : hint_normal;
uniform vec2  light_uv[3];      // torch positions in SCREEN_UV space (0..1)
uniform vec4  light_col[3];     // rgb = light colour, a = energy
uniform float light_rad[3];     // reach, in UV-height units
uniform int   light_count = 2;
uniform float aspect = 1.777;   // viewport w/h, so UV distance is round not squashed
uniform float ambient = 0.42;   // base fill so the far-from-torch side stays legible
uniform float gain = 1.7;       // lit-term strength
uniform float diffuse_gain = 1.0;   // pre-lift a dark diffuse (e.g. backing_v1) before lighting
uniform vec3  ember : source_color = vec3(1.0, 0.62, 0.30);
uniform float rim_strength = 0.7;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	tex.rgb *= diffuse_gain;
	vec3 N = normalize(texture(normal_tex, UV).xyz * 2.0 - 1.0);
	vec3 lit = tex.rgb * ambient;
	for (int i = 0; i < light_count; i++) {
		vec2 toL2 = (light_uv[i] - SCREEN_UV) * vec2(aspect, 1.0);   // frag -> light (screen space)
		float dist = length(toL2);
		float atten = clamp(1.0 - dist / light_rad[i], 0.0, 1.0);
		atten *= atten;
		vec3 L = normalize(vec3(toL2, 0.55));                         // z toward viewer
		float ndl = clamp(dot(N, L), 0.0, 1.0);
		float e = light_col[i].a;
		vec3 warm = mix(light_col[i].rgb, ember, 0.35);
		lit += tex.rgb * warm * ndl * atten * e * gain;              // normal-mapped relief
		lit += ember * pow(ndl, 3.0) * rim_strength * atten * e;     // ember rim on light-facing edges
	}
	COLOR = vec4(lit, tex.a);
}
