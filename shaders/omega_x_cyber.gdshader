shader_type canvas_item;

// Yengil GL Compatibility shader: Frost Guardian piksel-art detallarini
// OMEGA-X Central AI Guardian faza palitrasiga moslashtiradi.
uniform vec3 armor_shadow : source_color = vec3(0.08, 0.10, 0.17);
uniform vec3 armor_highlight : source_color = vec3(0.62, 0.72, 0.84);
uniform vec3 energy_shadow : source_color = vec3(0.05, 0.10, 0.30);
uniform vec3 energy_mid : source_color = vec3(0.0, 0.82, 0.98);
uniform vec3 energy_highlight : source_color = vec3(0.84, 0.98, 1.0);
uniform float armor_blend : hint_range(0.0, 1.0) = 0.78;
uniform float energy_blend : hint_range(0.0, 1.0) = 0.75;
uniform float core_pulse : hint_range(0.0, 0.8) = 0.0;
uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;
uniform vec3 flash_color : source_color = vec3(1.0, 0.90, 0.94);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float alpha_mult = tex.a > 0.001 ? COLOR.a / tex.a : 1.0;

	// Energiya/kristall piksellarida ko'k (B) qizil (R) dan ustun, zirhda esa teskari.
	float is_energy = step(0.01, tex.b - tex.r);
	float luma = dot(tex.rgb, vec3(0.299, 0.587, 0.114));

	float t_armor = clamp((luma - 0.11) / 0.68, 0.0, 1.0);
	vec3 armor_target = mix(armor_shadow, armor_highlight, t_armor);
	vec3 armor_rgb = mix(tex.rgb, armor_target, armor_blend);

	float t_energy = clamp((luma - 0.08) / 0.80, 0.0, 1.0);
	vec3 e_low = mix(energy_shadow, energy_mid, clamp(t_energy * 1.82, 0.0, 1.0));
	vec3 e_full = mix(e_low, energy_highlight, clamp((t_energy - 0.55) * 2.22, 0.0, 1.0));
	float core_mask = smoothstep(0.42, 0.88, t_energy);
	e_full += core_pulse * core_mask * mix(energy_mid, energy_highlight, 0.55);
	vec3 energy_rgb = mix(tex.rgb, e_full, energy_blend);

	vec3 adapted = mix(armor_rgb, energy_rgb, is_energy);
	vec3 final_rgb = mix(adapted, flash_color, hit_flash);

	COLOR = vec4(clamp(final_rgb, 0.0, 1.5), tex.a * alpha_mult);
}
