shader_type canvas_item;

// Base Colors & Highlights
uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 last_move_color : source_color = vec4(0.9, 0.8, 0.2, 0.4);
uniform vec4 forbidden_color : source_color = vec4(0.92, 0.2, 0.22, 0.35);
uniform vec4 check_color : source_color = vec4(0.95, 0.2, 0.2, 0.65);
uniform vec4 defender_color : source_color = vec4(0.22, 0.65, 1.0, 0.95);
uniform vec4 selected_color : source_color = vec4(0.2, 0.6, 1.0, 0.45);
uniform vec4 legal_color : source_color = vec4(0.0, 0.0, 0.0, 0.35);

// State Flags
uniform bool is_last_move = false;
uniform bool is_forbidden = false;
uniform bool is_defender = false;
uniform bool is_in_check = false;
uniform bool is_selected = false;
uniform bool is_legal_move = false;
uniform bool is_capture_target = false;
uniform bool is_drag_hovered = false;

// Scales & Dimensions
uniform float selected_scale : hint_range(0.0, 1.0) = 0.0;
uniform float legal_scale : hint_range(0.0, 1.0) = 0.0;
uniform float capture_dim_alpha : hint_range(0.0, 1.0) = 0.38;
uniform vec2 cell_size = vec2(64.0, 64.0);

vec4 blend_over(vec4 top, vec4 bot) {
	float out_a = top.a + bot.a * (1.0 - top.a);
	if (out_a <= 0.0001) {
		return vec4(0.0);
	}
	vec3 out_rgb = (top.rgb * top.a + bot.rgb * bot.a * (1.0 - top.a)) / out_a;
	return vec4(out_rgb, out_a);
}

void fragment() {
	vec2 uv = UV;
	vec2 center = vec2(0.5, 0.5);
	float dist = distance(uv, center);
	
	// Analisis subpixel derivative untuk anti-aliasing super halus
	float aa = max(fwidth(dist), 1.0 / max(cell_size.x, 1.0)) * 1.5;

	// 1. Base Layer
	vec4 final_col = base_color;

	// 2. Last Move Highlight
	if (is_last_move) {
		final_col = blend_over(last_move_color, final_col);
	}

	// 3. Forbidden Square Highlight
	if (is_forbidden && !is_selected && !is_legal_move) {
		final_col = blend_over(forbidden_color, final_col);
	}

	// 4. Defender Border
	if (is_defender && !is_selected && !is_legal_move) {
		vec2 pixel_coord = uv * cell_size;
		float d_left = pixel_coord.x;
		float d_right = cell_size.x - pixel_coord.x;
		float d_top = pixel_coord.y;
		float d_bottom = cell_size.y - pixel_coord.y;
		float min_edge = min(min(d_left, d_right), min(d_top, d_bottom));
		
		float bw = 2.0;
		float border_mask = 1.0 - smoothstep(bw - 0.75, bw + 0.75, min_edge);
		vec4 def_tint = defender_color;
		def_tint.a *= border_mask;
		final_col = blend_over(def_tint, final_col);
	}

	// 5. Check Warning (King)
	if (is_in_check) {
		final_col = blend_over(check_color, final_col);
	}

	// 6. Selected Ripple (Circular SDF Expansion)
	if (is_selected && selected_scale > 0.001) {
		float sel_radius = 0.72 * selected_scale;
		float sel_mask = 1.0 - smoothstep(sel_radius - aa, sel_radius + aa, dist);
		vec4 sel_tint = selected_color;
		sel_tint.a *= sel_mask;
		final_col = blend_over(sel_tint, final_col);
	}

	// 7. Legal Move Indicator (SDF Solid Dot / SDF Dimmed Hole)
	if (is_legal_move && legal_scale > 0.001) {
		if (is_capture_target) {
			// Dimmed square dengan lubang lingkaran SDF transparan di tengah
			float hole_radius = 0.375 * clamp(legal_scale, 0.0, 1.0);
			float hole_mask = smoothstep(hole_radius - aa, hole_radius + aa, dist);
			float d_alpha = capture_dim_alpha * clamp(legal_scale, 0.0, 1.0) * hole_mask;
			vec4 dim_tint = vec4(0.0, 0.0, 0.0, d_alpha);
			final_col = blend_over(dim_tint, final_col);
		} else {
			// Solid dot SDF dengan subpixel anti-aliasing murni
			float dot_radius = 0.16 * legal_scale;
			float dot_mask = 1.0 - smoothstep(dot_radius - aa, dot_radius + aa, dist);
			vec4 dot_tint = legal_color;
			dot_tint.a *= dot_mask * clamp(legal_scale, 0.0, 1.0);
			final_col = blend_over(dot_tint, final_col);
		}
	}

	// 8. Drag Hover Outline
	if (is_drag_hovered) {
		vec2 pixel_coord = uv * cell_size;
		float d_left = pixel_coord.x;
		float d_right = cell_size.x - pixel_coord.x;
		float d_top = pixel_coord.y;
		float d_bottom = cell_size.y - pixel_coord.y;
		float min_edge = min(min(d_left, d_right), min(d_top, d_bottom));
		
		float bw = 2.5;
		float hover_mask = 1.0 - smoothstep(bw - 0.75, bw + 0.75, min_edge);
		vec4 hover_tint = vec4(1.0, 1.0, 1.0, 0.85);
		hover_tint.a *= hover_mask;
		final_col = blend_over(hover_tint, final_col);
	}

	COLOR = final_col;
}
