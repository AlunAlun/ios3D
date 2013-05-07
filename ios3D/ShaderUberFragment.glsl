

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

#ifdef USE_DIFFUSE_TEXTURE
uniform sampler2D u_textureSampler;
varying mediump vec2 v_fragmentTexCoord0;
#endif

#ifdef USE_DETAIL_TEXTURE
uniform sampler2D u_detailSampler;
#endif

varying highp vec4 v_shadowCoord;
uniform sampler2D u_shadowMap;

const float cos_outer_cone_angle = 0.8; // 36 degrees

float UnpackDepth32(vec4 depth)
{
    const vec4 bitShifts = vec4( 1.0/(256.0*256.0*256.0), 1.0/(256.0*256.0), 1.0/256.0, 1);
    return dot(depth.xyzw , bitShifts);
}

void main(void)
{
    //normalize all first
    highp vec3 E = normalize(u_camera_eye-v_pos);
    highp vec3 L = normalize(u_light_pos-v_pos);
    highp vec3 N = normalize(v_normal);
    highp vec3 D = normalize(u_light_dir);
    
    //ambient
    highp vec4 finalColor = u_mat_ambient;
  

    highp float spot = 1.0;
#ifdef USE_SPOT_LIGHT
    //****************************************************
	// Spot light without dynamic branching
    float cos_cur_angle = dot(-L, D);
    float cos_inner_cone_angle = u_light_spot_cutoff;
    float cos_inner_minus_outer_angle = cos_inner_cone_angle - cos_outer_cone_angle;
	spot = clamp((cos_cur_angle - cos_outer_cone_angle) / cos_inner_minus_outer_angle, 0.0, 1.0);
	//****************************************************
#endif
    
    // diffuse
    float ndotl = max(dot(N, L), 0.0);
    highp vec3 diffuse_light = ndotl * u_light_color;
    finalColor += vec4(diffuse_light, 1.0) * u_mat_diffuse * u_light_intensity*spot;
    
    // specular
    highp vec3 R = reflect(-L, N);
    finalColor += pow( max(dot(R, E), 0.0), u_mat_shininess )*u_mat_specular*spot;

#ifdef USE_DIFFUSE_TEXTURE
    finalColor *= texture2D(u_textureSampler, v_fragmentTexCoord0);
#endif

#ifdef USE_DETAIL_TEXTURE
    mediump vec2 detailTexCoord = v_fragmentTexCoord0*6.0; //change scaling of detail texture //ADD UNIFORM!!
    finalColor += (texture2D(u_detailSampler, detailTexCoord)-vec4(0.5))*0.3; //change effect of detail tex //ADD UNIFORM
#endif
    
    
    
    float bias = 0.005;
    float visibility = 1.0;

    
    
    
    /*
    vec2 sample = (v_shadowCoord.xy / v_shadowCoord.w) * vec2(0.5) + vec2(0.5);
    float shadow = 0.0;
    float depth = 0.0;
    
    text
    
    
    if (depth > 0.0) {
        float bias = 0.0;   //-1.0;
        shadow = clamp(30000.0 * (bias + v_shadowCoord.z / v_shadowCoord.w * 0.5 + 0.5 - depth), 0.0, 1.0);
    }
    visibility = 1.0 - shadow;
    */
    
    float a[5];
    a = float[](3.4, 4.2, 5.0, 5.2, 1.1);
    highp vec2 poissonDisk[4] = vec2[4](vec2( -0.94201624, -0.39906216 ),
                                       vec2( 0.94558609, -0.76890725 ),
                                       vec2( -0.094184101, -0.92938870 ),
                                       vec2( 0.34495938, 0.29387760 ));
    

    highp vec2 sample = v_shadowCoord.xy;
    float sampleDepth = texture2D( u_shadowMap, sample ).z;
    float depth = (sampleDepth == 1.0) ? 1.0e9 : sampleDepth; //on empty data send it to far away
    
    //if ( texture2D( u_shadowMap, v_shadowCoord.xy ).z  <  v_shadowCoord.z-bias)
    if (depth < v_shadowCoord.z-bias)
    {
        visibility -= 0.1;
    }

    highp vec2 sample = v_shadowCoord.xy;
    float sampleDepth = texture2D( u_shadowMap, sample ).z;
    float depth = (sampleDepth == 1.0) ? 1.0e9 : sampleDepth; //on empty data send it to far away

    if (depth < v_shadowCoord.z-bias)
    {
        visibility = 0.5;
    }

    
    finalColor *= visibility;
    
    gl_FragColor = finalColor ;




}