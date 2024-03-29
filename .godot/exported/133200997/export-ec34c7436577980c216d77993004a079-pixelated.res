RSRC                    VisualShader            ��������                                            <      resource_local_to_scene    resource_name    output_port_for_preview    default_input_values    expanded_output_ports    input_name    script    parameter_name 
   qualifier    hint    min    max    step    default_value_enabled    default_value    op_type 	   operator 	   function    source    texture    texture_type    code    graph_offset    mode    modes/blend    flags/skip_vertex_transform    flags/unshaded    flags/light_only    nodes/vertex/0/position    nodes/vertex/connections    nodes/fragment/0/position    nodes/fragment/2/node    nodes/fragment/2/position    nodes/fragment/3/node    nodes/fragment/3/position    nodes/fragment/4/node    nodes/fragment/4/position    nodes/fragment/5/node    nodes/fragment/5/position    nodes/fragment/6/node    nodes/fragment/6/position    nodes/fragment/7/node    nodes/fragment/7/position    nodes/fragment/connections    nodes/light/0/position    nodes/light/connections    nodes/start/0/position    nodes/start/connections    nodes/process/0/position    nodes/process/connections    nodes/collide/0/position    nodes/collide/connections    nodes/start_custom/0/position    nodes/start_custom/connections     nodes/process_custom/0/position !   nodes/process_custom/connections    nodes/sky/0/position    nodes/sky/connections    nodes/fog/0/position    nodes/fog/connections        $   local://VisualShaderNodeInput_icjon ?      -   local://VisualShaderNodeFloatParameter_beeq7 t      '   local://VisualShaderNodeVectorOp_2mclv       )   local://VisualShaderNodeVectorFunc_08cx4 w      '   local://VisualShaderNodeVectorOp_5aavt �      &   local://VisualShaderNodeTexture_m4v6l O	         local://VisualShader_antj5 �	         VisualShaderNodeInput             uv          VisualShaderNodeFloatParameter             Pixelation 	         
        �C        �D         @                 �C         VisualShaderNodeVectorOp                    
                 
                                       VisualShaderNodeVectorFunc                    
                                       VisualShaderNodeVectorOp                    
                 
                                       VisualShaderNodeTexture                      VisualShader          A  shader_type canvas_item;
render_mode blend_mix;

uniform float Pixelation : hint_range(256, 1080, 2) = 256;
uniform sampler2D screen_tex_frg_7 : hint_screen_texture;



void fragment() {
// Input:2
	vec2 n_out2p0 = UV;


// FloatParameter:3
	float n_out3p0 = Pixelation;


// VectorOp:4
	vec2 n_out4p0 = n_out2p0 * vec2(n_out3p0);


// VectorFunc:5
	vec2 n_out5p0 = floor(n_out4p0);


// VectorOp:6
	vec2 n_out6p0 = n_out5p0 / vec2(n_out3p0);


	vec4 n_out7p0;
// Texture2D:7
	n_out7p0 = texture(screen_tex_frg_7, n_out6p0);


// Output:0
	COLOR.rgb = vec3(n_out7p0.xyz);


}
                                     
   �PWİ��B!            "   
     W�  \C#            $   
     ��   C%            &   
     ��   C'            (   
     ��  HC)            *   
   �P�B��)C+                                                                                                                 RSRC