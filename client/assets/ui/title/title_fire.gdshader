shader_type canvas_item;
// Layer 3 + 5 of the title scene (TD-073 / R243): live fire and breathing light over the
// matte-painted Collegium.
//
// The hall's hundred-odd candles are already PAINTED into the matte, so this shader does not
// place lights — it FINDS them. Warm, bright pixels are treated as flame and given an additive
// halo that flickers. That is what makes hand-placing a hundred Light2Ds unnecessary, and it
// scales for free if the matte is ever repainted.
//
// A shader rather than Light2D because Light2D does not reach Control nodes (TD-047) — the same
// ruling that made board_surface.gdshader exist.
//
// `anim` is the reduced-motion lever: at 0.0 every flame sits at its base energy, so the frame
// is fully lit and simply still (R244).

uniform float flicker_amp : hint_range(0.0, 0.6) = 0.22;   // per-flame, independent
uniform float breathe_amp : hint_range(0.0, 0.3) = 0.05;   // the room's slow swell
uniform float glow_gain   : hint_range(0.0, 3.0) = 1.05;
uniform float glow_radius : hint_range(0.0, 0.03) = 0.0065;
uniform float anim = 1.0;                                   // 0 = reduced motion / lights off

float hash12(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);

	// Ring-sample for nearby flame. Warm bias (r above b) keeps cold stained glass and pale
	// stone from blooming — only firelight should breathe.
	vec3 glow = vec3(0.0);
	for (int i = 0; i < 12; i++) {
		float a = float(i) * 0.5235988;
		vec2 o = vec2(cos(a), sin(a) * 1.6) * glow_radius;   // taller than wide, like a flame
		vec3 s = texture(TEXTURE, UV + o).rgb;
		float lum = dot(s, vec3(0.299, 0.587, 0.114));
		float warm = clamp(s.r - s.b, 0.0, 1.0);
		glow += s * smoothstep(0.40, 0.92, lum) * (0.35 + warm * 1.5);
	}
	glow /= 12.0;

	// Phase seeded from position, so neighbouring flames are never in step. Synchronised
	// flicker is the single clearest tell that a scene is faked.
	float ph = hash12(floor(UV * 160.0)) * 6.2831853;
	float f = 1.0 + flicker_amp * (sin(TIME * 3.3 + ph) * 0.62 + sin(TIME * 8.1 + ph * 2.3) * 0.38);
	float breathe = 1.0 + breathe_amp * sin(TIME * 0.33);

	vec3 lit = base.rgb + glow * glow_gain * mix(1.0, f * breathe, anim);
	// NOT `* COLOR`: on entry to fragment(), COLOR already holds texture(TEXTURE,UV) times the
	// node's modulate, so multiplying by it again squares the image (measured: a 4x darkening).
	// The incoming COLOR.rgb/base.rgb ratio recovers that modulate without needing MODULATE,
	// which this Godot build does not expose to canvas_item fragment shaders.
	vec3 mod_rgb = base.rgb.r + base.rgb.g + base.rgb.b > 0.003
		? COLOR.rgb / max(base.rgb, vec3(0.0015))
		: vec3(1.0);
	COLOR = vec4(lit * clamp(mod_rgb, vec3(0.0), vec3(4.0)), COLOR.a);
}
