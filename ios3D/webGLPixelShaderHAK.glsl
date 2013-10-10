
precision highp float;
 
 varying vec3 v_pos;
 varying vec3 v_normal;
 varying vec2 v_uvs;
 varying vec2 v_uvs_transformed;
 varying vec3 v_tangent;
 varying vec4 v_screenpos; //used for projective textures
 
 #ifdef USE_COLOR_STREAM
 varying vec4 v_color;
 #endif

#ifdef USE_COLOR_TEXTURE
 uniform sampler2D color_texture;
 #endif
 
 #ifdef USE_OPACITY_TEXTURE
 uniform sampler2D opacity_texture;
 #endif
 
 #ifdef USE_SPECULAR_TEXTURE
 uniform sampler2D specular_texture;
 #endif
 
 #ifdef USE_AMBIENT_TEXTURE
 uniform sampler2D ambient_texture;
 #endif
 
 #ifdef USE_EMISSIVE_TEXTURE
 uniform sampler2D emissive_texture;
 #endif
 
 #ifdef USE_NORMAL_TEXTURE
 uniform mat4 u_normal_model;
 uniform sampler2D normal_texture;
 #endif
 
 #ifdef USE_DISPLACEMENT_TEXTURE
 uniform sampler2D displacement_texture;
 #endif
 
 #ifdef USE_NORMALMAP_FACTOR
 uniform float u_normalmap_factor;
 #endif
 
 #ifdef USE_DISPLACEMENTMAP_FACTOR
 uniform float u_displacementmap_factor;
 #endif
 
 
 #ifdef USE_DETAIL_TEXTURE
 uniform sampler2D detail_texture;
 uniform vec3 u_detail_info;
 #endif
 
 #ifdef USE_REFLECTIVITY_TEXTURE
 uniform sampler2D reflectivity_texture;
 #endif
 
 uniform vec2 u_reflection_info;
 #ifdef USE_ENVIRONMENT_TEXTURE
 uniform sampler2D environment_texture;
 #endif
 
 #ifdef USE_ENVIRONMENT_CUBEMAP
 uniform samplerCube environment_cubemap;
 #endif
 
 #ifdef USE_IRRADIANCE_TEXTURE
 uniform sampler2D irradiance_texture;
 #endif
 
 #ifdef USE_IRRADIANCE_CUBEMAP
 uniform samplerCube irradiance_cubemap;
 #endif
 
 #ifdef USE_PROJECTIVE_LIGHT
 uniform sampler2D light_texture;
 #endif
 
 #ifdef USE_SOFT_PARTICLES
 uniform sampler2D depth_texture;
 #endif
 
 #ifdef USE_VELVET
 uniform vec4 u_velvet_info;
 #endif
 
 #ifdef USE_BACKLIGHT
 uniform float u_backlight_factor;
 #endif
 
 #ifdef USE_LIGHT_OFFSET
 uniform float u_light_offset;
 #endif
 
 #ifdef USE_BRIGHTNESS_FACTOR
 uniform float u_brightness_factor;
 #endif
 
 #ifdef USE_COLORCLIP_FACTOR
 uniform float u_colorclip_factor;
 #endif
 
 uniform vec4 u_material_color;
 uniform vec3 u_ambient_color;
 uniform vec3 u_diffuse_color;
 uniform vec3 u_emissive_color;
 uniform vec3 u_light_pos;
 uniform vec3 u_light_front;
 uniform vec3 u_light_color;
 uniform vec4 u_light_angle; //start,end,phi,theta
 uniform vec2 u_light_att; //start,end
 
 uniform vec3 u_camera_eye;
 uniform vec2 u_camera_planes; //far near
 
 uniform vec3 u_fog_info;
 uniform vec3 u_fog_color;
 
 uniform vec2 u_specular;
 
 uniform vec4 u_clipping_plane;
 
 

 
void main() {
    float temp;
    vec2 temp_v2;
    vec3 temp_v3;

    //surface color
    vec3 final_color = vec3(0.0);
    vec3 color = u_material_color.xyz;
    float alpha = u_material_color.a;



    float spec_factor = u_specular.x;
    float spec_gloss = u_specular.y;

    vec3 N = normalize(v_normal);

    //* COMPUTE TEXTURE COORDINATES ***************************
    vec2 uvs_0 = v_uvs;







    #ifdef USE_COLOR_TEXTURE
    vec4 diffuse_tex = texture2D(color_texture, USE_COLOR_TEXTURE );
    color *= diffuse_tex.xyz;
    #ifndef USE_OPACITY_TEXTURE
    alpha *= diffuse_tex.a;
    #endif
    #endif





    #ifdef USE_SPECULAR_TEXTURE
    vec3 spec_tex = texture2D(specular_texture, USE_SPECULAR_TEXTURE ).xyz;
    spec_factor *= spec_tex.x;
    spec_gloss *= spec_tex.y;
    #endif

    


    
    
    //lighting calculation
    float shadow = 1.0;

    vec3 E = (u_camera_eye - v_pos);
    float cam_dist = length(E);

    #ifdef USE_ORTHOGRAPHIC_CAMERA
    E = normalize(u_camera_eye);
    #else
    E /= cam_dist;
    #endif

    vec3 L = (u_light_pos - v_pos);
    float light_dist = length(L);
    L /= light_dist;


    vec3 R = reflect(E,N);


    float NdotL = 1.0;
    #ifdef USE_DIFFUSE_LIGHT
    NdotL = dot(N,L);
    #endif
    float EdotN = dot(E,N); //clamp(dot(E,N),0.0,1.0);
    #ifdef USE_SPECULAR_LIGHT
    spec_factor *= pow( clamp(dot(R,-L),0.001,1.0), spec_gloss);
    #else
    spec_factor = 0.0;
    #endif

    vec3 light = vec3(0.0,0.0,0.0);

    //ambient light
    #ifdef FIRST_PASS
    temp_v3 = u_ambient_color;


    light += temp_v3;
    #endif


    float att = 1.0;


    vec3 light_color = u_light_color;


    

    #ifndef USE_AMBIENT_ONLY

    #ifdef USE_BACKLIGHT
    if(NdotL > 0.0 != gl_FrontFacing)
    NdotL *= u_backlight_factor;
    #else
    if(NdotL > 0.0 != gl_FrontFacing)
    NdotL = 0.0;
    #endif
    
    NdotL = abs(NdotL);
    light += u_diffuse_color * light_color * att * NdotL * shadow;
    #endif


    //final color
    final_color = color * light;
    
    gl_FragColor = vec4(final_color, alpha); //regular color

    /*

    //apply spec factor
    #ifndef USE_AMBIENT_ONLY
    #ifdef USE_SPECULAR_ONTOP
    final_color += light_color * (att * spec_factor * shadow);
    #else
    final_color += color * light_color * (att * spec_factor * shadow);
    #endif
    #ifdef USE_SPECULAR_ON_ALPHA
    alpha += spec_factor;
    #endif
    #endif






    gl_FragColor = vec4(final_color, alpha); //regular color

 */
 
    //gl_FragColor = vec4(1.0,0.0,1.0,1.0);
    //gl_FragColor = vec4(-E,1.0); //front vector
    //gl_FragColor = vec4(v_pos * 0.005,1.0); //pos vector
    //gl_FragColor = vec4(light,1.0);
 }