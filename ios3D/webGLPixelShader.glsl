
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
 
 #if defined(USE_SHADOW_MAP) || defined(USE_PROJECTIVE_LIGHT)
 varying vec4 v_light_coord;
 #endif
 
 #ifdef USE_SHADOW_MAP
 
 #ifndef SHADOWMAP_OFFSET 
 #define SHADOWMAP_OFFSET (1.0/1024.0)
 #endif 
 uniform sampler2D shadowMap;
 uniform vec2 u_shadow_params; // (1.0/(texture_size), bias)
 
 float UnpackDepth24(vec3 depth)
 {
 return dot(vec3(65536.0, 256.0, 1.0), depth) / 65025.0;
 }
 
 float UnpackDepth32(vec4 depth)
 {
 const vec4 bitShifts = vec4( 1.0/(256.0*256.0*256.0), 1.0/(256.0*256.0), 1.0/256.0, 1);
 return dot(depth.xyzw , bitShifts);
 }
 
 float testShadow(vec2 offset)
 {
 vec2 sample = (v_light_coord.xy / v_light_coord.w) * vec2(0.5) + vec2(0.5) + offset;
 float shadow = 0.0;
 float depth = 0.0;
 
 //is inside light frustum
 if (clamp(sample, 0.0, 1.0) == sample) { 
 float sampleDepth = UnpackDepth32( texture2D(shadowMap, sample) );
 depth = (sampleDepth == 1.0) ? 1.0e9 : sampleDepth; //on empty data send it to far away
 }
 else return 0.0; //outside of shadowmap, no shadow
 
 if (depth > 0.0) {
 float bias = -1.0 * u_shadow_params.y;
 shadow = clamp(30000.0 * (bias + v_light_coord.z / v_light_coord.w * 0.5 + 0.5 - depth), 0.0, 1.0);
 }
 return shadow;
 }
 #endif
 
 #ifdef USE_SPOT_LIGHT
 float spotFalloff(vec3 spotDir, vec3 lightDir, float angle_phi, float angle_theta)
 {
 float sqlen = dot(lightDir,lightDir);
 float atten = 1.0;
 
 vec4 spotParams = vec4( angle_phi, angle_theta, 1.0, 0.0 );
 spotParams.w = 1.0 / (spotParams.x-spotParams.y);
 
 vec3 dirUnit = lightDir * sqrt(sqlen); //we asume they are normalized
 float spotDot = dot(spotDir, -dirUnit);
 if (spotDot <= spotParams.y)// spotDot <= cos phi/2
 return 0.0;
 else if (spotDot > spotParams.x) // spotDot > cos theta/2
 return 1.0;
 
 // vertex lies somewhere beyond the two regions
 float ifallof = pow( (spotDot-spotParams.y)*spotParams.w,spotParams.z );
 return ifallof;
 }
 #endif
 
 #ifdef USE_TANGENT_NORMALMAP
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
 B *= -1.0; //reverse y, HACK, dont know why but works
 
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
 #endif
 
 #ifdef USE_DISPLACEMENT_TEXTURE
 #extension GL_OES_standard_derivatives : enable 
 
 // Project the surface gradient (dhdx, dhdy) onto the surface (n, dpdx, dpdy)
 vec3 CalculateSurfaceGradient(vec3 n, vec3 dpdx, vec3 dpdy, float dhdx, float dhdy)
 {
 vec3 r1 = cross(dpdy, n);
 vec3 r2 = cross(n, dpdx);
 
 return (r1 * dhdx + r2 * dhdy) / dot(dpdx, r1);
 }
 
 // Move the normal away from the surface normal in the opposite surface gradient direction
 vec3 PerturbNormal(vec3 normal, vec3 dpdx, vec3 dpdy, float dhdx, float dhdy)
 {
 return normalize(normal - CalculateSurfaceGradient(normal, dpdx, dpdy, dhdx, dhdy));
 }
 
 // Calculate the surface normal using screen-space partial derivatives of the height field
 vec3 displace_normal(vec3 position, vec3 normal, float height)
 {
 vec3 dpdx = dFdx(position);
 vec3 dpdy = dFdy(position);
 
 float dhdx = dFdx(height);
 float dhdy = dFdy(height);
 
 return PerturbNormal(normal, dpdx, dpdy, dhdx, dhdy);
 }
 #endif
 
 void main() {
 float temp;
 vec2 temp_v2;
 vec3 temp_v3;
 
 #ifdef USE_CLIPPING_PLANE
 if( dot(v_pos, u_clipping_plane.xyz) < u_clipping_plane.w)
 discard;
 #endif
 
 //surface color
 vec3 final_color = vec3(0.0);
 vec3 color = u_material_color.xyz;
 float alpha = u_material_color.a;
 #ifdef USE_COLOR_STREAM
 color *= v_color.xyz;
 alpha *= v_color.w;
 #endif
 
 float spec_factor = u_specular.x;
 float spec_gloss = u_specular.y;
 
 vec3 N = normalize(v_normal);
 
 //* COMPUTE TEXTURE COORDINATES ***************************
 vec2 uvs_0 = v_uvs;
 vec2 uvs_1 = uvs_0;
 vec2 uvs_transformed = v_uvs_transformed;
 vec2 uvs_worldxy = v_pos.xy * 0.1;
 vec2 uvs_worldxz = v_pos.xz * 0.1;
 vec2 uvs_worldyz = v_pos.yz * 0.1;
 vec2 uvs_screen = (v_screenpos.xy / v_screenpos.w) * 0.5 + 0.5;
 uvs_screen.x = 1.0 - uvs_screen.x;
 
 #ifdef USE_NORMAL_TEXTURE
 //warning: v_normal is in World space
 vec3 normalmap_pixel = texture2D( normal_texture, USE_NORMAL_TEXTURE ).xyz;
 #ifdef USE_TANGENT_NORMALMAP
 N = perturb_normal(N, v_pos, USE_NORMAL_TEXTURE, normalmap_pixel );
 //N is in world space
 #else
 N = (normalmap_pixel - vec3(0.5)) * 2.0;
 //N is in object space so we need to convert it to world space
 N = (u_normal_model * vec4(N,1.0)).xyz;
 #endif
 
 #ifdef USE_NORMALMAP_FACTOR
 N = normalize( mix(v_normal, N, u_normalmap_factor) );
 #endif
 #endif
 
 #ifdef USE_DISPLACEMENT_TEXTURE
 vec3 prev_norm = N;
 float pixel_height = texture2D( displacement_texture, USE_DISPLACEMENT_TEXTURE ).x;
 N = displace_normal(v_pos, N, pixel_height );
 #ifdef USE_DISPLACEMENTMAP_FACTOR
 N = normalize( mix(prev_norm, N, u_displacementmap_factor) );
 #endif
 #endif
 
 vec2 uvs_polar = vec2( 1.0 - atan(N.z,N.x) / 6.28318531 + 0.5, asin(N.y) / 1.57079633 * 0.5 + 0.5);
 vec2 uvs_polar_reflected = uvs_polar; //computed later when we know the Reflected vector
 //uvs_polar_reflected = vec2( 1.0 - (atan(R.z,R.x) / 6.28318531 + 0.5), 0.5 - asin(R.y) / 1.57079633 * 0.5);
 
 //********************************************************
 
 #ifdef USE_OPACITY_TEXTURE
 alpha *= texture2D(opacity_texture,USE_OPACITY_TEXTURE).x;
 #endif
 
 #ifdef USE_COLOR_TEXTURE
 vec4 diffuse_tex = texture2D(color_texture, USE_COLOR_TEXTURE );
 color *= diffuse_tex.xyz;
 #ifndef USE_OPACITY_TEXTURE
 alpha *= diffuse_tex.a;
 #endif
 #endif
 
 #ifdef USE_ALPHA_TEST
 if(alpha < USE_ALPHA_TEST)
 discard;
 #endif
 
 #ifdef USE_SPECULAR_TEXTURE
 vec3 spec_tex = texture2D(specular_texture, USE_SPECULAR_TEXTURE ).xyz;
 spec_factor *= spec_tex.x;
 spec_gloss *= spec_tex.y;
 #endif
 
 #ifdef USE_DETAIL_TEXTURE
 vec3 detail_tex = texture2D(detail_texture,uvs_0 * u_detail_info.yz).xyz;
 color += (detail_tex - vec3(0.5)) * u_detail_info.x;
 #endif
 
 //lighting calculation
 float shadow = 1.0;
 #if defined(USE_SHADOW_MAP) && !defined(USE_AMBIENT_ONLY)
 
 #ifdef USE_HARD_SHADOWS
 shadow = 1.0 - testShadow(vec2(0.,0.));
 #else
 
 if (v_light_coord.w > 0.0) //inside the light frustrum
 {
 /* poison distribution
 shadow = testShadow(vec2(-0.326212*u_shadow_params.x, -0.405805*u_shadow_params.x));
 shadow += testShadow(vec2(-0.840144*u_shadow_params.x, -0.07358*u_shadow_params.x));
 shadow += testShadow(vec2(-0.695914*u_shadow_params.x, 0.457137*u_shadow_params.x));
 shadow += testShadow(vec2(-0.203345*u_shadow_params.x, 0.620716*u_shadow_params.x));
 shadow += testShadow(vec2(0.96234*u_shadow_params.x, -0.194983*u_shadow_params.x));
 shadow += testShadow(vec2(0.473434*u_shadow_params.x, -0.480026*u_shadow_params.x));
 shadow += testShadow(vec2(0.519456*u_shadow_params.x, 0.767022*u_shadow_params.x));
 shadow += testShadow(vec2(0.185461*u_shadow_params.x, -0.893124*u_shadow_params.x));
 shadow += testShadow(vec2(0.507431*u_shadow_params.x, 0.064425*u_shadow_params.x));
 shadow += testShadow(vec2(0.89642*u_shadow_params.x, 0.412458*u_shadow_params.x));
 shadow += testShadow(vec2(-0.32194*u_shadow_params.x, -0.932615*u_shadow_params.x));
 shadow += testShadow(vec2(-0.791559*u_shadow_params.x, -0.597705*u_shadow_params.x));
 shadow = 1.0 - shadow / 12.;
 */
 shadow = 2.0 * testShadow(vec2(0.0,0.0));
 shadow += testShadow(vec2(0.0,u_shadow_params.x));
 shadow += testShadow(vec2(0.0,-u_shadow_params.x));
 shadow += testShadow(vec2(-u_shadow_params.x,0.0));
 shadow += testShadow(vec2(u_shadow_params.x,0.0));
 shadow += testShadow(vec2(-u_shadow_params.x,-u_shadow_params.x));
 shadow += testShadow(vec2(u_shadow_params.x,-u_shadow_params.x));
 shadow += testShadow(vec2(-u_shadow_params.x,u_shadow_params.x));
 shadow += testShadow(vec2(u_shadow_params.x,u_shadow_params.x));
 shadow = 1.0 - shadow * 0.1;
 }
 #endif	
 #endif
 
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
 
 #if defined(USE_SPOT_LIGHT) || defined(USE_DIRECTIONAL_LIGHT)
 L = u_light_front;
 #endif
 
 vec3 R = reflect(E,N);
 uvs_polar_reflected = vec2( 1.0 - (atan(R.z,R.x) / 6.28318531 + 0.5), 0.5 - asin(R.y) / 1.57079633 * 0.5);
 
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
 
 vec3 light;
 
 //ambient light
 #ifdef FIRST_PASS
 temp_v3 = u_ambient_color;
 #ifdef USE_AMBIENT_TEXTURE
 temp_v3 *= texture2D(ambient_texture,uvs_0).xyz;
 #endif
 
 #ifdef USE_IRRADIANCE_CUBEMAP
 temp_v3 *= textureCube(irradiance_cubemap,N).xyz;
 #else
 #ifdef USE_IRRADIANCE_TEXTURE
 temp_v3 *= texture2D(irradiance_texture, uvs_polar ).xyz;
 #endif
 #endif
 
 light += temp_v3;
 #endif
 
 
 float att = 1.0;
 #ifdef USE_LINEAR_ATTENUATION
 att = 100.0 / light_dist;
 #endif
 
 #ifdef USE_RANGE_ATTENUATION
 if(light_dist >= u_light_att.y)
 att = 0.0;
 else if(light_dist >= u_light_att.x)
 att *= 1.0 - (light_dist - u_light_att.x) / (u_light_att.y - u_light_att.x);
 #endif
 
 vec3 light_color = u_light_color;
 
 #ifdef USE_PROJECTIVE_LIGHT
 vec2 light_sample = (v_light_coord.xy / v_light_coord.w) * vec2(0.5) + vec2(0.5);
 light_color *= texture2D(light_texture,light_sample).xyz;
 
 #ifndef USE_SPOT_CONE
 if (light_sample.x < 0.001 || light_sample.y < 0.001 || light_sample.x > 0.999 || light_sample.y > 0.999)
 att = 0.0;
 #endif
 #endif
 
 #ifdef USE_SPOT_LIGHT
 #ifdef USE_SPOT_CONE
 att *= spotFalloff(u_light_front, -normalize(u_light_pos - v_pos), u_light_angle.z, u_light_angle.w);
 #endif
 #endif
 
 
 #ifndef USE_AMBIENT_ONLY
 #ifdef USE_LIGHT_OFFSET
 NdotL += u_light_offset;
 #endif
 
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
 
 //emissive
 temp_v3 = u_emissive_color;
 #ifdef USE_EMISSIVE_TEXTURE
 temp_v3 *= texture2D(emissive_texture,USE_EMISSIVE_TEXTURE).xyz;
 #endif
 #ifndef USE_EMISSIVE_MATERIAL
 light += temp_v3;
 #endif
 
 //final color
 final_color = color * light;
 
 #ifdef USE_EMISSIVE_MATERIAL
 final_color = max(temp_v3,final_color);
 #endif
 
 float velvet_factor = 0.0;
 #ifdef FIRST_PASS
 #ifdef USE_VELVET
 velvet_factor = pow( 1.0 - abs(EdotN), abs(u_velvet_info.w) );
 
 #ifdef USE_VELVET_ALPHA
 alpha += velvet_factor;
 #endif
 
 #ifdef USE_DETAIL_TEXTURE
 velvet_factor += (detail_tex.x - 0.5) * u_detail_info.x;
 #endif
 
 if(u_velvet_info.w > 0.0)
 final_color += u_velvet_info.xyz * velvet_factor;
 else
 final_color = final_color * (1.0 - velvet_factor) + u_velvet_info.xyz * velvet_factor;
 
 #ifdef USE_SKIN_SHADER
 spec_factor = pow(spec_factor,velvet_factor);
 #endif
 #endif
 #endif
 
 //apply reflection
 #ifdef FIRST_PASS
 #if defined(USE_ENVIRONMENT_TEXTURE) || defined(USE_ENVIRONMENT_CUBEMAP)
 float reflection_factor = u_reflection_info.x * pow( 1.0 - clamp(0.0,EdotN,1.0), abs(u_reflection_info.y) );
 
 #ifdef USE_REFLECTIVITY_TEXTURE
 reflection_factor *= texture2D(reflectivity_texture, USE_REFLECTIVITY_TEXTURE).x;
 #endif
 
 #ifdef USE_SPECULAR_IN_REFLECTION
 reflection_factor *= spec_factor;
 #endif
 
 #ifdef USE_ENVIRONMENT_CUBEMAP
 final_color = final_color * (1.0 - reflection_factor) + textureCube(environment_cubemap,vec3(-1.,1.,1.)*R).xyz * reflection_factor;
 #endif
 #ifdef USE_ENVIRONMENT_TEXTURE
 temp_v2 = vec2(0.0);
 #ifdef USE_NORMAL_TEXTURE
 //temp_v2 += vec2(0.0, -length(normalmap_pixel.xy)) * 0.1; //this can be improved, it is just a hack
 temp_v2 = vec2(0.0,-0.025) * (1.0 - dot(N, normalize(v_normal)));
 #ifdef USE_NORMALMAP_FACTOR
 temp_v2 *= u_normalmap_factor;
 #endif
 #endif
 final_color = mix( final_color, texture2D(environment_texture, USE_ENVIRONMENT_TEXTURE + temp_v2).xyz, reflection_factor );
 #endif
 #endif
 #endif
 
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
 
 /* TODO
 #ifdef USE_SOFT_PARTICLES
 alpha *= clamp((v_screenpos.z - texture2D(depth_texture,uvs_screen).r),0.0,1.0);
 #endif
 */
 
 //apply fog
 #ifdef USE_FOG
 #ifdef USE_FOG_EXP
 float fog = 1. - 1.0 / exp(max(0.0,cam_dist - u_fog_info.x) * u_fog_info.z);
 #elif defined(USE_FOG_EXP2)
 float fog = 1. - 1.0 / exp(pow(max(0.0,cam_dist - u_fog_info.x) * u_fog_info.z,2.0));
 #else
 float fog = 1. - clamp((u_fog_info.y - cam_dist) / (u_fog_info.y - u_fog_info.x),0.,1.);
 #endif
 
 final_color = mix(final_color, u_fog_color, fog);
 #endif
 
 #ifdef USE_BRIGHTNESS_FACTOR
 final_color *= u_brightness_factor;
 #endif
 #ifdef USE_COLORCLIP_FACTOR
 final_color -= vec3(u_colorclip_factor);
 /*
 temp = length(final_color);
 if( temp < u_colorclip_factor * 0.75)
 final_color = vec3(0.0);
 else if( temp < u_colorclip_factor)
 final_color *= clamp((temp - u_colorclip_factor * 0.75) / (u_colorclip_factor * 0.25),0.0,1.0);
 */
 #endif
 
 gl_FragColor = vec4(final_color, alpha); //regular color
 //gl_FragColor = vec4(1.0,0.0,1.0,1.0);
 //gl_FragColor = vec4(-E,1.0); //front vector
 //gl_FragColor = vec4(v_pos * 0.005,1.0); //pos vector
 //gl_FragColor = vec4(light,1.0);
 }