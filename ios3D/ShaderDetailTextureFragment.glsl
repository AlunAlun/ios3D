// Fragment shader
precision highp float;

uniform mediump vec4 u_mat_diffuse;
uniform mediump vec4 u_mat_ambient;
uniform mediump vec4 u_mat_specular;
uniform mediump float u_mat_shininess;
uniform mediump vec3 u_light_color;
uniform mediump float u_light_intensity;
uniform mediump vec3 u_light_spot_dir;
uniform mediump float u_light_spot_cutoff;
uniform mediump vec3 u_light_pos;

uniform sampler2D u_textureSampler;
uniform sampler2D u_detailSampler;
uniform bool u_useDetail;

varying mediump vec3 v_light_dir;
varying mediump vec3 v_normal;
varying mediump vec3 v_pos;
varying mediump vec2 v_fragmentTexCoord0;

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
    mediump vec3 DiffuseColor = ndotl * u_light_color; 
    finalColor += vec4(DiffuseColor, 1.0) * u_mat_diffuse * u_light_intensity;
    
    // specular
    mediump vec3 R = reflect(-LD, N);
    float specFloat = pow( max(dot(R, E), 0.0), u_mat_shininess );
    mediump vec4 specVec = u_mat_specular * specFloat;
    finalColor += specVec;
    
    //add texture
    finalColor *= texture2D(u_textureSampler, v_fragmentTexCoord0);
    
    /* Add detail texture */
    if (u_useDetail)
    {
        mediump vec2 detailTexCoord = v_fragmentTexCoord0*6.0; //change scaling of detail texture //ADD UNIFORM!!
        finalColor += (texture2D(u_detailSampler, detailTexCoord)-vec4(0.5))*0.3; //change effect of detail tex //ADD UNIFORM
    }
    
    gl_FragColor = finalColor ;
    
}


/*

// Fragment shader

uniform sampler2D TextureSampler;
uniform sampler2D DetailSampler;
uniform bool UseDetail;

uniform mediump vec4 matDiffuse;
uniform mediump vec4 matAmbient;
uniform mediump vec4 matSpecular;
uniform mediump float matShininess;

//uniform mediump vec4 LightColor;
uniform mediump float LightIntensity;

varying mediump vec3 E; // Eye Vector, already normalized
varying mediump vec3 LD; // Light Direction, already normalized
varying mediump vec3 N; // Normal, already normalized
varying mediump vec3 R; // reflect component
varying mediump vec2 FragmentTexCoord0;
 
void main(void)
{
    
    // diffuse
    mediump float ndotl = max(dot(N, LD), 0.0);
    mediump vec3 DiffuseColor = ndotl * vec3(1.0);
    mediump vec4 diffuseTotal = vec4(DiffuseColor, 1.0) * matDiffuse * LightIntensity;

    // specular

	mediump float specFloat = pow( max(dot(R, E), 0.0), matShininess );
    mediump vec4 specVec = matSpecular * specFloat;
   
    //texture + phong
    mediump vec4 finalColor = texture2D(TextureSampler, FragmentTexCoord0) * (diffuseTotal + matAmbient + specVec) ;

    /* Add detail texture *
    if (UseDetail)
    {
        mediump vec2 FragmentTexCoord1 = FragmentTexCoord0*6.0;
        finalColor += (texture2D(DetailSampler, FragmentTexCoord1)-vec4(0.5))*0.3;
    }

    gl_FragColor = finalColor ;

}
*/