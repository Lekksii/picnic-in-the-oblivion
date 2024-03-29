RSRC                    VisualShader            ��������                                            G      resource_local_to_scene    resource_name    output_port_for_preview    default_input_values    expanded_output_ports    parameter_name 
   qualifier    texture_type    color_default    texture_filter    texture_repeat    texture_source    script    source    texture    input_name    op_type    code    graph_offset    mode    modes/blend    modes/depth_draw    modes/cull    modes/diffuse    modes/specular    flags/depth_prepass_alpha    flags/depth_test_disabled    flags/sss_mode_skin    flags/unshaded    flags/wireframe    flags/skip_vertex_transform    flags/world_vertex_coords    flags/ensure_correct_normals    flags/shadows_disabled    flags/ambient_light_disabled    flags/shadow_to_opacity    flags/vertex_lighting    flags/particle_trails    flags/alpha_to_coverage     flags/alpha_to_coverage_and_one    flags/debug_shadow_splits    nodes/vertex/0/position    nodes/vertex/connections    nodes/fragment/0/position    nodes/fragment/2/node    nodes/fragment/2/position    nodes/fragment/3/node    nodes/fragment/3/position    nodes/fragment/4/node    nodes/fragment/4/position    nodes/fragment/5/node    nodes/fragment/5/position    nodes/fragment/6/node    nodes/fragment/6/position    nodes/fragment/connections    nodes/light/0/position    nodes/light/connections    nodes/start/0/position    nodes/start/connections    nodes/process/0/position    nodes/process/connections    nodes/collide/0/position    nodes/collide/connections    nodes/start_custom/0/position    nodes/start_custom/connections     nodes/process_custom/0/position !   nodes/process_custom/connections    nodes/sky/0/position    nodes/sky/connections    nodes/fog/0/position    nodes/fog/connections        1   local://VisualShaderNodeTexture2DParameter_c8vkc �      &   local://VisualShaderNodeTexture_4cmcs �      $   local://VisualShaderNodeInput_wnagj 	      .   local://VisualShaderNodeVectorDecompose_c0xvw K	      "   local://VisualShaderNodeMix_s4k6x {	         local://VisualShader_2h2dn �	      #   VisualShaderNodeTexture2DParameter             Texture2DParameter 	                  VisualShaderNodeTexture                      VisualShaderNodeInput             normal           VisualShaderNodeVectorDecompose             VisualShaderNodeMix                                                �?      )   ��������         VisualShader          x  shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform sampler2D Texture2DParameter : filter_nearest;



void fragment() {
	vec4 n_out3p0;
// Texture2D:3
	n_out3p0 = texture(Texture2DParameter, UV);


// Input:4
	vec3 n_out4p0 = NORMAL;


// VectorDecompose:5
	float n_out5p0 = n_out4p0.x;
	float n_out5p1 = n_out4p0.y;
	float n_out5p2 = n_out4p0.z;


// Mix:6
	float n_in6p1 = 1.00000;
	float n_in6p2 = -0.02500;
	float n_out6p0 = mix(n_out5p2, n_in6p1, n_in6p2);


// Output:0
	ALBEDO = vec3(n_out3p0.xyz);
	ALPHA = n_out6p0;
	EMISSION = vec3(n_out3p0.xyz);


}
    
   7�î�aC+   
     9D  C,             -   
     �  �B.            /   
     �  �B0            1   
     ��  �C2            3   
     ��  �C4            5   
   �VcC���C6                                                                                                   RSRC