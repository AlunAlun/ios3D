// Fragment shader
precision highp float;

uniform highp vec4 u_mat_diffuse;
uniform highp vec4 u_mat_ambient;
uniform highp float u_mat_specular;
uniform highp float u_mat_shininess;
uniform highp vec3 u_light_color;
uniform highp float u_light_intensity;
uniform highp vec3 u_light_dir;
uniform highp float u_light_spot_cutoff;
uniform highp vec3 u_light_pos;
uniform highp vec3 u_camera_eye;


varying highp vec3 v_light_dir; 
varying highp vec3 v_normal;
varying highp vec3 v_pos;

 
void main(void)
{
    //normalize all first
    highp vec3 E = normalize(u_light_pos-v_pos);
    highp vec3 L = normalize(u_light_pos - v_pos);
    highp vec3 N = normalize(v_normal);
    highp vec3 D = normalize(u_light_dir);
    
    //ambient
    highp vec4 finalColor = u_mat_ambient;

   // highp float cos_cur_angle = dot(-L, D);
    
    //float cos_inner_cone_angle
    
    if (dot(-L, D) > 0.9)
	{
        // diffuse
        float ndotl = max(dot(N, L), 0.0);
        highp vec3 DiffuseColor = ndotl * u_light_color;
        finalColor += vec4(DiffuseColor, 1.0) * u_mat_diffuse * u_light_intensity;
        
        // specular
        highp vec3 R = reflect(-L, N);
        float specFactor = pow( max(dot(R, E), 0.0), u_mat_shininess )*u_mat_specular;
        finalColor += specFactor;
        
    }

    gl_FragColor = finalColor ;

}

/*
 // Fragment shader
 precision highp float;
 
 uniform mediump vec4 u_mat_diffuse;
 uniform mediump vec4 u_mat_ambient;
 uniform mediump float u_mat_specular;
 uniform mediump float u_mat_shininess;
 uniform mediump vec3 u_light_color;
 uniform mediump float u_light_intensity;
 uniform mediump vec3 u_light_spot_dir;
 uniform mediump float u_light_spot_cutoff;
 uniform mediump vec3 u_light_pos;
 uniform mediump vec3 u_camera_eye;
 
 
 varying mediump vec3 v_light_dir;
 varying mediump vec3 v_normal;
 varying mediump vec3 v_pos;
 
 
 void main(void)
 {
 //normalize all first
 mediump vec3 E = normalize(u_camera_eye - v_pos);
 mediump vec3 L = normalize(u_light_pos - v_pos);
 
 mediump vec3 N = normalize(v_normal);
 
 mediump vec3 light_direction = vec3(0.0, -1.0, 0.0); //light direction
 mediump vec3 D = normalize(light_direction); //light direction
 
 //ambient
 highp vec4 finalColor = vec4(0.0, 0.0, 0.0, 1.0);  //u_mat_ambient;
 
 highp float ndotl = max(dot(N, L), 0.0);
 highp vec3 DiffuseColor = vec3(1.0, 1.0, 1.0) * ndotl;// * u_light_color;
 
 
 if (dot(-L, D) > 0.9)
 {
 // diffuse
 
 
 finalColor += vec4(DiffuseColor, 1.0) * vec4(1.0, 0.0, 0.0, 1.0);// * u_mat_diffuse * u_light_intensity;
 
 // specular
 //mediump vec3 R = reflect(-L, N);
 //float specFactor = pow( max(dot(R, E), 0.0), u_mat_shininess )*u_mat_specular;
 //finalColor += specFactor;
 //finalColor = vec4(1.0, 1.0, 0.0, 1.0);
 
 }
 
 gl_FragColor = finalColor ;
 
 }
*/