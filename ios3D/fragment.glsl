// Fragment shader

uniform lowp sampler2D TextureSampler;
uniform lowp sampler2D DetailSampler;

uniform lowp vec4 matDiffuse;
uniform lowp vec4 matAmbient;
uniform lowp vec4 matSpecular;
uniform lowp float matShininess;

//uniform lowp vec4 LightColor;
uniform lowp float LightIntensity;

varying lowp vec3 EyeVec;
varying lowp vec3 LightDirection; //already normalized
varying lowp vec3 Normal; 
varying lowp vec2 FragmentTexCoord0;
 
void main(void)
{
    
    lowp vec3 N = normalize(Normal);
    lowp vec3 E = normalize(EyeVec);
    lowp vec3 LD = normalize(LightDirection);
    lowp vec3 R = reflect(-LD, N);


    // diffuse
    lowp float ndotl = max(dot(N, LD), 0.0);
    lowp vec3 DiffuseColor = ndotl * vec3(1.0);
    lowp vec4 diffuseTotal = vec4(DiffuseColor, 1.0) * matDiffuse * LightIntensity;

    // specular

	lowp float specFloat = pow( max(dot(R, E), 0.0), matShininess );
    lowp vec4 specVec = matSpecular * specFloat;
   


    /* Add detail texture */
    // lowp vec2 FragmentTexCoord1 = FragmentTexCoord0*6.0;
    // (detail_tex - vec3(0.5)) * u_detail_info.x;
   // gl_FragColor = ((texture2D(DetailSampler, FragmentTexCoord1)*0.3 + texture2D(TextureSampler, FragmentTexCoord0))/2.0) * (diffuseTotal + matAmbient + specVec) ;
    
    //lowp vec4 finalColor = texture2D(TextureSampler, FragmentTexCoord0) * (diffuseTotal + matAmbient + specVec) ;
    lowp vec4 finalColor = (diffuseTotal + matAmbient + specVec) ;
    //finalColor += (texture2D(DetailSampler, FragmentTexCoord1)-vec4(0.5))*0.3;
    gl_FragColor = finalColor ;
    //gl_FragColor = diffuseTotal;
}