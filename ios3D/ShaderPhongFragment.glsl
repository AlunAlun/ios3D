// Fragment shader
precision highp float;

uniform mediump vec4 u_mat_diffuse;
uniform mediump vec4 u_mat_ambient;
uniform mediump vec4 u_mat_specular;
uniform mediump float u_mat_shininess;
//uniform mediump vec4 LightColor;
uniform mediump float u_light_intensity;
uniform mediump vec3 u_light_spot_dir;
uniform mediump float u_light_spot_cutoff;
uniform mediump vec3 u_light_pos;

varying mediump vec3 v_light_dir; 
varying mediump vec3 v_normal;
varying mediump vec3 v_pos;

 
void main(void)
{
    //normalize all first
    mediump vec3 E = normalize(u_light_pos-v_pos);
    mediump vec3 LD = normalize(u_light_pos - v_pos);
    mediump vec3 N = normalize(v_normal);
    
    //ambient
    mediump vec4 finalColor = u_mat_ambient;
    
    // diffuse
    float ndotl = max(dot(N, LD), 0.0);
    mediump vec3 DiffuseColor = ndotl * vec3(0.5); //modify diffuse color here in future
    finalColor += vec4(DiffuseColor, 1.0) * u_mat_diffuse * u_light_intensity;

    // specular
    mediump vec3 R = reflect(-LD, N);
    float specFloat = pow( max(dot(R, E), 0.0), u_mat_shininess );
    mediump vec4 specVec = u_mat_specular * specFloat;
    finalColor += specVec;

    gl_FragColor = finalColor ;

}