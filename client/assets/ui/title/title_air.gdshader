// title_air.gdshader — the Collegium's air, in one pass (TD-079).
//
// Ground haze, atmospheric perspective, god rays, altar emphasis and the slow breath of the light,
// all computed on the plate's OWN quad. That quad is rasterised every frame regardless, so every
// effect here costs ALU and *zero* additional fill — where the layers it replaces (three particle
// fog banks and a `light_shaft.png` overlay) cost ~1.4 screens of additive blending between them.
// Testament is browser-first; this is the cheapest surface in the scene (P138).
//
// TWO RULES hold everything together:
//
//   1. NOTHING MOVES. Every animated term varies in INTENSITY only (P139). Rays do not sweep, haze
//      does not roll, the plate is never offset or scaled. Motion that draws the eye is the failure
//      this shader exists to avoid — the hall should look almost frozen and reveal its life only
//      after several seconds.
//   2. THE PLATE IS NEVER RESAMPLED. This samples UV 1:1 under the CanvasItem's own NEAREST filter
//      and only modulates the colour it gets back. A sub-pixel transform would shimmer a pixel-art
//      image, which is why there is no camera breath (R284).
//
// Depth has no buffer to read, so distance from the nave's VANISHING POINT is the proxy: pixels
// near the VP are far down the hall, pixels at the frame edge are the near piers. That single
// scalar drives both the atmospheric perspective and the altar's emphasis.
shader_type canvas_item;

// ── geometry ────────────────────────────────────────────────────────────────
// The nave's vanishing point, DERIVED (see title_scene.gd NAVE_VP — measured, then corrected for
// the plate's crop). Everything spatial here hangs off it, so an eyeballed value would disagree
// with the architecture in a way that is hard to name but easy to feel.
uniform vec2  vp_uv = vec2(0.5, 0.898);
uniform float aspect = 1.7777;          // so UV distance is round, not squashed

// ── atmospheric perspective (R282) ──────────────────────────────────────────
// Distance does not blur, it loses contrast: blacks lift toward the air's colour and saturation
// falls. Blur would cost a second sample set and read as a lens defect rather than as air.
uniform vec3  air_col   : source_color = vec3(0.60, 0.56, 0.50);
uniform float air_reach = 0.62;         // UV radius over which the effect falls to nothing
uniform float air_lift  = 0.17;         // how far the far distance moves toward `air_col`
uniform float air_desat = 0.28;         // saturation lost at maximum distance

// ── ground haze (R277) ──────────────────────────────────────────────────────
// A band of standing air low in the frame. It does not roll or loop; it breathes, barely.
uniform float haze_y      = 0.88;       // where the band sits
uniform float haze_soft   = 0.30;       // how far it reaches up the frame
uniform float haze_amount = 0.075;

// ── god rays (R280) ─────────────────────────────────────────────────────────
// Each ray hangs from an upper window, WIDENS as it descends, and dies before the floor. Soft
// edges, low opacity, and animated by intensity alone — the wedge geometry is constant.
uniform vec4  ray_a = vec4(0.335, 0.045, 0.055, 0.185);  // x0, y0, half-width at top, lean
uniform vec4  ray_b = vec4(0.665, 0.045, 0.045, -0.150);
uniform float ray_spread   = 0.115;     // half-width gained per unit of descent
uniform float ray_die_y    = 0.74;      // fully gone by here — a shaft needs dust to be seen in
uniform float ray_strength = 0.085;
uniform vec3  ray_col : source_color = vec3(1.00, 0.94, 0.80);

// ── the altar, and the breath (R281) ────────────────────────────────────────
uniform float altar_lift = 0.055;       // emphasis, NOT a glow: no edge should be findable
uniform float altar_r    = 0.30;
uniform float breath_amp = 0.040;       // +-4%, inside the brief's 3-5%
uniform float breath_hz  = 0.0092;      // ~109s cycle: long enough to never read as a pulse

float luma(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

// One shaft. `p` is aspect-corrected UV; returns 0..1 before strength.
float shaft(vec2 p, vec4 r) {
	float drop = p.y - r.y;
	if (drop < 0.0) return 0.0;
	float half_w = r.z + ray_spread * drop;          // widens as it falls
	float centre = r.x + r.w * drop;                 // leans, but never moves over time
	float d = abs(p.x - centre) / max(half_w, 1e-4);
	if (d >= 1.0) return 0.0;
	// Soft edges: a squared cosine profile has no hard rim, so the shaft reads as light in air
	// rather than as a polygon with an alpha ramp.
	float across = pow(cos(d * 1.5707963), 2.0);
	// Vertical envelope: fades in below the window, gone before the floor.
	float in_top = smoothstep(0.0, 0.09, drop);
	float out_bot = 1.0 - smoothstep(ray_die_y - r.y - 0.22, ray_die_y - r.y, drop);
	return across * in_top * max(out_bot, 0.0);
}

void fragment() {
	// COLOR on entry ALREADY holds texture(TEXTURE, UV) * modulate — Godot samples for you. Taking
	// a second sample and multiplying by COLOR squares the image, which on a hall this dark cost a
	// factor of five in mean luminance and read as "the shader broke the plate". Read COLOR, write
	// COLOR: it is both correct and one texture fetch cheaper.
	vec3 col = COLOR.rgb;

	// Aspect-corrected position, and the depth proxy.
	vec2 p = vec2(UV.x, UV.y);
	vec2 dv = vec2((UV.x - vp_uv.x) * aspect, UV.y - vp_uv.y);
	float dist = length(dv);
	float far = 1.0 - smoothstep(0.0, air_reach, dist);   // 1 at the VP, 0 at the near piers

	// ── atmospheric perspective ──
	float g = luma(col);
	col = mix(col, vec3(g), far * air_desat);             // saturation falls with distance
	col = mix(col, air_col, far * air_lift * (1.0 - g * 0.55));  // blacks lift more than highlights

	// ── ground haze: a standing band, breathing almost imperceptibly ──
	float band = 1.0 - smoothstep(0.0, haze_soft, abs(UV.y - haze_y));
	band *= 0.55 + 0.45 * (1.0 - smoothstep(0.10, 0.60, abs(UV.x - 0.5)));  // thickest down the nave
	float haze_breath = 1.0 + 0.10 * sin(TIME * 0.031);   // +-10% of a already-small term
	col = mix(col, air_col, band * haze_amount * haze_breath);

	// ── god rays: additive light in the air, intensity-animated only ──
	// Each breathes on its own slow period; rays pulsing together is the tell that reads as fake.
	float r1 = shaft(p, ray_a) * (1.0 + 0.16 * sin(TIME * 0.047));
	float r2 = shaft(p, ray_b) * (1.0 + 0.16 * sin(TIME * 0.036 + 2.1));
	// They fall THROUGH the haze, so they are strongest where there is air to catch them.
	float catch_air = 0.55 + 0.45 * band;
	col += ray_col * (r1 + r2) * ray_strength * catch_air;

	// ── the altar: emphasis with no findable edge ──
	float altar = 1.0 - smoothstep(0.0, altar_r, dist);
	col += air_col * altar * altar * altar_lift;

	// ── the breath: one slow cycle over the whole image ──
	col *= 1.0 + breath_amp * sin(TIME * breath_hz * 6.2831853);

	COLOR.rgb = col;
}
