
//#extension GL_EXT_shadow_samplers : require

// Fragment shader
precision highp float;


uniform lowp vec4 u_material_color;
uniform lowp vec3 u_ambient_color;
uniform lowp float u_mat_specular;
uniform mediump float u_mat_shininess;
uniform highp mat3 u_normal_model;
//light1
uniform lowp vec3 u_light_color;
uniform lowp float u_light_intensity;
uniform highp vec3 u_light_dir;
uniform highp float u_light_spot_cutoff;
uniform highp vec3 u_light_pos;
//light2
uniform lowp vec3 u_light2_color;
uniform lowp float u_light2_intensity;
uniform highp vec3 u_light2_dir;
uniform highp float u_light2_spot_cutoff;
uniform highp vec3 u_light2_pos;

uniform highp vec3 u_camera_eye;

uniform mediump vec3 u_scene_ambient;


varying highp vec3 v_normal;
varying highp vec3 v_pos;
varying highp vec2 v_fragmentTexCoord0;

#ifdef USE_DIFFUSE_TEXTURE
uniform lowp sampler2D color_texture;

#endif

#ifdef USE_DETAIL_TEXTURE
uniform sampler2D detail_texture;
#endif

#ifdef USE_SPECULAR_TEXTURE
uniform sampler2D specular_texture;
#endif

#ifdef USE_NORMAL_TEXTURE
uniform sampler2D normal_texture;
#endif

#if defined (USE_HARD_SHADOWS) | defined (USE_SOFT_SHADOWS)
varying highp vec4 v_shadowCoord;
uniform sampler2D u_shadowMap;
#endif

const float cos_outer_cone_angle = 0.8; // 36 degrees

#extension GL_OES_standard_derivatives : enable
mat3 cotangent_frame(vec3 N, vec3 p, vec2 uv)
{
    // get edge vectors of the pixel triangle
    vec3 dp1 = dFdx( p );
    vec3 dp2 = dFdy( p );
    vec2 duv1 = dFdx( uv );
    vec2 duv2 = dFdy( uv );
    
    // solve the linear system
    vec3 dp2perp = cross( dp2, N );
    vec3 dp1perp = cross( N, dp1 );
    vec3 T = dp2perp * duv1.x + dp1perp * duv2.x;
    vec3 B = dp2perp * duv1.y + dp1perp * duv2.y;
    //B *= -1.0; //reverse y, HACK, dont know why but works
    
    // construct a scale-invariant frame
    float invmax = inversesqrt( max( dot(T,T), dot(B,B) ) );
    return mat3( T * invmax, B * invmax, N );
}

vec3 perturb_normal( vec3 N, vec3 V, vec2 texcoord, vec3 map )
{
    // assume N, the interpolated vertex normal and
    // V, the view vector (vertex to eye)
    //vec3 map = texture2D(normalmap, texcoord ).xyz;
    map = map * 255./127. - 128./127.;
    mat3 TBN = cotangent_frame(N, -V, texcoord);
    return normalize(TBN * map);
}

#ifdef USE_SOFT_SHADOWS

float getShadow(vec2 coords)
{
    float bias = 0.02;
    float shadow = 0.0;
    highp vec2 sample = v_shadowCoord.xy + coords;///1000.0;
    //float sampleDepth = texture2D( u_shadowMap, sample ).z;
    float sampleDepth = texture2D( u_shadowMap, sample ).z;
    //float sampleDepth = shadow2DEXT(u_shadowMap, v_shadowCoord.xyz);
    float depth = (sampleDepth == 1.0) ? 1.0e9 : sampleDepth; //on empty data send it to far away
    if (depth < v_shadowCoord.z-bias)
        shadow = 1.0;
    
    return shadow;
    
}
#endif

void main(void)
{
    
    //normalize all first
    highp vec3 E = normalize(u_camera_eye-v_pos);
    highp vec3 L = normalize(u_light_pos-v_pos);
    highp vec3 LunNorm = u_light_pos-v_pos;
    float light_dist = length(LunNorm);
    float att = 100.0/light_dist;
    highp vec3 N = normalize(v_normal);
    highp vec3 D = normalize(u_light_dir);
    
#ifdef USE_NORMAL_TEXTURE
    vec3 normalmap_pixel = texture2D( normal_texture, v_fragmentTexCoord0 ).xyz;
    N = normalize((normalmap_pixel - vec3(0.5)) * 2.0);
#endif
    
    //base color
    highp vec4 finalColor = u_material_color;
    
    //ambient
    finalColor *= vec4(u_ambient_color,1.0);
    
    //setup specular
    float spec_factor = u_mat_specular;
    float spec_gloss = u_mat_shininess;
#ifdef USE_SPECULAR_TEXTURE
    highp vec3 spec_tex = texture2D(specular_texture, v_fragmentTexCoord0.xy ).xyz;
    spec_factor *= spec_tex.x;
    spec_gloss *= spec_tex.y;
#endif
    
    
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
    finalColor += vec4(diffuse_light, 1.0) * (u_light_intensity*spot);
    
    // specular
    highp vec3 R = reflect(-L, N);
    finalColor += pow( max(dot(R, E), 0.01), spec_gloss )*spec_factor*spot;
    
#ifdef LIGHT2
    highp vec3 L2 = normalize(u_light2_pos-v_pos);
    highp vec3 L2unNorm = u_light2_pos-v_pos;
    highp vec3 D2 = normalize(u_light2_dir);
    float light2_dist = length(L2unNorm);
    float att2 = 1.0;
#ifdef LIGHT2_LINEAR_ATTENUATION
    att2 = 100.0/light2_dist;
#endif
    
    // diffuse
    float ndotl2 = max(dot(N, L2), 0.0);
    highp vec3 diffuse_light2 = ndotl2 * u_light2_color;
    finalColor += vec4(diffuse_light2, 1.0) * (u_light2_intensity*spot)*att2;
    // specular
    highp vec3 R2 = reflect(-L2, N);
    finalColor += pow( max(dot(R2, E), 0.01), spec_gloss )*spec_factor;
#endif
    
    
#ifdef USE_DIFFUSE_TEXTURE
    finalColor *= texture2D(color_texture, v_fragmentTexCoord0);
#endif
    
#ifdef USE_DETAIL_TEXTURE
    mediump vec2 detailTexCoord = v_fragmentTexCoord0*6.0; //change scaling of detail texture //ADD UNIFORM!!
    finalColor += (texture2D(detail_texture, detailTexCoord)-vec4(0.5))*0.3; //change effect of detail tex //ADD UNIFORM
#endif
    
    
    
    float shadow = 1.0;
#ifdef USE_HARD_SHADOWS
    float bias = 0.015;
    highp vec2 sample = v_shadowCoord.xy;
    float sampleDepth = texture2D( u_shadowMap, sample ).z;
    float depth = (sampleDepth == 1.0) ? 1.0e9 : sampleDepth; //on empty data send it to far away
    if (depth < v_shadowCoord.z-bias)
        shadow = 0.0;
#endif
    
#ifdef USE_SOFT_SHADOWS
    shadow = 2.0 * getShadow(vec2( 0, 0 ));
    float spread = 0.003;
    shadow += getShadow(vec2( 0.0, spread ));
    shadow += getShadow(vec2( 0.0, -spread  ));
    shadow += getShadow(vec2( -spread, 0.0 ));
    shadow += getShadow(vec2( spread, 0.0 ));
    /*
     shadow += getShadow(vec2( -spread, spread ));
     shadow += getShadow(vec2( spread, -spread  ));
     shadow += getShadow(vec2( -spread, spread ));
     shadow += getShadow(vec2( spread, spread ));
     */
    shadow = 1.0 - shadow*0.1;
#endif
    
    gl_FragColor = finalColor*shadow;
    
#ifdef DRAW_LINES
    gl_FragColor = vec4(0.0, 1.0, 0.0, 1.0);
#endif
    
    
}

/*

//#extension GL_EXT_shadow_samplers : require

// Fragment shader
precision highp float;


uniform lowp vec4 u_material_color;
uniform lowp vec3 u_ambient_color;
uniform lowp vec3 u_diffuse_color;
uniform lowp float u_mat_specular;
uniform mediump float u_mat_shininess;
uniform highp mat3 u_normal_model;
uniform lowp vec4 u_velvet_info;
//light1
uniform lowp vec3 u_light_color;
uniform lowp float u_light_intensity;
uniform highp vec3 u_light_dir;
uniform highp float u_light_spot_cutoff;
uniform highp vec3 u_light_pos;
//light2
uniform lowp vec3 u_light2_color;
uniform lowp float u_light2_intensity;
uniform highp vec3 u_light2_dir;
uniform highp float u_light2_spot_cutoff;
uniform highp vec3 u_light2_pos;

uniform highp vec3 u_camera_eye;

uniform mediump vec3 u_scene_ambient;


varying highp vec3 v_normal;
varying highp vec3 v_pos;
varying highp vec2 v_fragmentTexCoord0;

#ifdef USE_DIFFUSE_TEXTURE
uniform lowp sampler2D color_texture;

#endif

#ifdef USE_DETAIL_TEXTURE
uniform sampler2D detail_texture;
#endif

#ifdef USE_SPECULAR_TEXTURE
uniform sampler2D specular_texture;
#endif

#ifdef USE_NORMAL_TEXTURE
uniform sampler2D normal_texture;
#endif

#if defined (USE_HARD_SHADOWS) | defined (USE_SOFT_SHADOWS)
varying highp vec4 v_shadowCoord;
uniform sampler2D u_shadowMap;
#endif

const float cos_outer_cone_angle = 0.8; // 36 degrees

#extension GL_OES_standard_derivatives : enable
mat3 cotangent_frame(vec3 N, vec3 p, vec2 uv)
{
    // get edge vectors of the pixel triangle
    vec3 dp1 = dFdx( p );
    vec3 dp2 = dFdy( p );
    vec2 duv1 = dFdx( uv );
    vec2 duv2 = dFdy( uv );
    
    // solve the linear system
    vec3 dp2perp = cross( dp2, N );
    vec3 dp1perp = cross( N, dp1 );
    vec3 T = dp2perp * duv1.x + dp1perp * duv2.x;
    vec3 B = dp2perp * duv1.y + dp1perp * duv2.y;
    //B *= -1.0; //reverse y, HACK, dont know why but works
    
    // construct a scale-invariant frame
    float invmax = inversesqrt( max( dot(T,T), dot(B,B) ) );
    return mat3( T * invmax, B * invmax, N );
}

vec3 perturb_normal( vec3 N, vec3 V, vec2 texcoord, vec3 map )
{
    // assume N, the interpolated vertex normal and
    // V, the view vector (vertex to eye)
    //vec3 map = texture2D(normalmap, texcoord ).xyz;
    map = map * 255./127. - 128./127.;
    mat3 TBN = cotangent_frame(N, -V, texcoord);
    return normalize(TBN * map);
}

#ifdef USE_SOFT_SHADOWS

float getShadow(vec2 coords)	
{
    float bias = 0.02;
    float shadow = 0.0;
    highp vec2 sample = v_shadowCoord.xy + coords;///1000.0;
    //float sampleDepth = texture2D( u_shadowMap, sample ).z;
    float sampleDepth = texture2D( u_shadowMap, sample ).z;
    //float sampleDepth = shadow2DEXT(u_shadowMap, v_shadowCoord.xyz);
    float depth = (sampleDepth == 1.0) ? 1.0e9 : sampleDepth; //on empty data send it to far away
    if (depth < v_shadowCoord.z-bias)
        shadow = 1.0;
    
    return shadow;
    
}
#endif

void main(void)
{
    
    //normalize all first
    highp vec3 E = normalize(u_camera_eye-v_pos);
    highp vec3 L = normalize(u_light_pos-v_pos);
    highp vec3 LunNorm = u_light_pos-v_pos;
    float light_dist = length(LunNorm);
    float att = 100.0/light_dist;
    highp vec3 N = normalize(v_normal);
    highp vec3 D = normalize(u_light_dir);

#ifdef USE_NORMAL_TEXTURE
    vec3 normalmap_pixel = texture2D( normal_texture, v_fragmentTexCoord0 ).xyz;
    N = normalize((normalmap_pixel - vec3(0.5)) * 2.0);
#endif
    
    //base color
    highp vec3 color = u_material_color.xyz;
    
#ifdef USE_DIFFUSE_TEXTURE
    highp vec4 diffuse_texture = texture2D(color_texture, v_fragmentTexCoord0);
    color *= diffuse_texture.xyz;
#endif

#ifdef USE_DETAIL_TEXTURE
    mediump vec2 detailTexCoord = v_fragmentTexCoord0*6.0; //change scaling of detail texture //ADD UNIFORM!!
    color += (texture2D(detail_texture, detailTexCoord)-vec4(0.5))*0.3; //change effect of detail tex //ADD UNIFORM
#endif

  
    //setup specular
    float spec_factor = u_mat_specular;
    float spec_gloss = u_mat_shininess;
#ifdef USE_SPECULAR_TEXTURE
    highp vec3 spec_tex = texture2D(specular_texture, v_fragmentTexCoord0.xy ).xyz;
    spec_factor *= spec_tex.x;
    spec_gloss *= spec_tex.y;
#endif
    
    highp vec3 light = vec3(0.0);
    
    float shadow = 1.0;
#ifdef USE_HARD_SHADOWS
    float bias = 0.015;
    highp vec2 sample = v_shadowCoord.xy;
    float sampleDepth = texture2D( u_shadowMap, sample ).z;
    float depth = (sampleDepth == 1.0) ? 1.0e9 : sampleDepth; //on empty data send it to far away
    if (depth < v_shadowCoord.z-bias)
        shadow = 0.0;
#endif
    
#ifdef USE_SOFT_SHADOWS
    shadow = 2.0 * getShadow(vec2( 0, 0 ));
    float spread = 0.003;
    shadow += getShadow(vec2( 0.0, spread ));
    shadow += getShadow(vec2( 0.0, -spread  ));
    shadow += getShadow(vec2( -spread, 0.0 ));
    shadow += getShadow(vec2( spread, 0.0 ));

    shadow = 1.0 - shadow*0.1;
#endif
    
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
    light += diffuse_light * (u_light_intensity*spot);
    
    // specular
    highp vec3 R = reflect(-L, N);
    //spec_factor *= pow( clamp(dot(R,-L),0.01,1.0), spec_gloss);
    light += pow( max(dot(R, E), 0.01), spec_gloss )*spec_factor*spot;
    
    highp vec3 light_color = u_light_color;
    
    highp vec3 final_color = light * color;
    
 
    float velvet_factor = 0.0;
    float alpha = 1.0;
    gl_FragColor = vec4(final_color, alpha);
    
#ifdef DRAW_LINES
    gl_FragColor = vec4(0.0, 1.0, 0.0, 1.0);
#endif
    



}

*/
/*
#ifdef LIGHT2
highp vec3 L2 = normalize(u_light2_pos-v_pos);
highp vec3 L2unNorm = u_light2_pos-v_pos;
highp vec3 D2 = normalize(u_light2_dir);
float light2_dist = length(L2unNorm);
float att2 = 1.0;
#ifdef LIGHT2_LINEAR_ATTENUATION
att2 = 100.0/light2_dist;
#endif

// diffuse
float ndotl2 = max(dot(N, L2), 0.0);
highp vec3 diffuse_light2 = ndotl2 * u_light2_color;
light += diffuse_light2 * (u_light2_intensity*spot)*att2;
// specular
highp vec3 R2 = reflect(-L2, N);
light += pow( max(dot(R2, E), 0.01), spec_gloss )*spec_factor;
#endif
 */




