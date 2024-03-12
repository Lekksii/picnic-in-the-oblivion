shader_type spatial;
render_mode depth_draw_opaque, unshaded;
uniform sampler2D ditherpattern;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform int dithersize = 8;
uniform float alpha_var = 0.5;
uniform sampler2D maintex : filter_nearest;

void fragment() {
	vec4 color = texture(maintex, UV) * COLOR;
	// Use the local Z-coordinate of the model
	vec4 model_pos = MODEL_MATRIX * vec4(VERTEX,1.0);
	
    float vertical_position = -model_pos.z;

    // Define the gradient range (adjust as needed)
    float gradient_start = 0.2;
    float gradient_end = 1.0;

    // Smoothly interpolate alpha based on local Z-coordinate
    float alpha = smoothstep(gradient_start, gradient_end, vertical_position);

    // Output the final color with adjusted alpha
    ALBEDO = color.rgb; // Set your desired color
    ALPHA = alpha;
}