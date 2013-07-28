precision highp float;
 attribute vec3 a_vertex;
 
 #ifndef NO_NORMALS
 attribute vec3 a_normal;
 #endif
 
 #ifndef NO_COORDS
 attribute vec2 a_coord;
 #endif
 
 #ifdef USE_COLOR_STREAM
 attribute vec4 a_color;
 varying vec4 v_color;
 #endif
 
 #ifdef USE_TANGENT_STREAM
 attribute vec3 a_tangent;
 #endif
 
 uniform mat4 u_mvp;
 uniform mat4 u_model;
 uniform mat4 u_viewprojection;
 uniform mat4 u_normal_model;
 
 uniform mat3 u_texture_matrix; //matrix to modify uvs
 varying vec2 v_uvs_transformed;
 
 varying vec3 v_pos;
 varying vec3 v_normal;
 varying vec3 v_tangent;
 varying vec2 v_uvs;
 
 varying vec4 v_screenpos; //used for projective textures
 uniform vec3 u_camera_eye;
 
 #if defined(USE_SHADOW_MAP) || defined(USE_PROJECTIVE_LIGHT)
 uniform mat4 u_lightMatrix;
 varying vec4 v_light_coord;
 #endif
 
 void main() {
 #ifdef NO_NORMALS
 v_normal = vec3(0.,1.,0.);
 #else
 v_normal = (u_normal_model * vec4(a_normal,1.0)).xyz;
 #endif
 
 #ifndef USE_TANGENT_STREAM
 v_tangent = vec3(1.,0.,0.);
 #else
 v_tangent = (u_normal_model * vec4(a_tangent,1.0)).xyz;
 #endif
 
 #ifdef USE_COLOR_STREAM
 v_color = a_color;
 #endif
 
 //mat4 mvp = (u_viewprojection * u_model);
 gl_Position = u_mvp * vec4(a_vertex,1.0);
 v_screenpos = gl_Position;
 v_pos = (u_model * vec4(a_vertex,1.0)).xyz;
 
 
 #ifdef NO_COORDS
 v_uvs = vec2(0.5,0.5);
 #else
 v_uvs = a_coord;
 #endif
 
 v_uvs_transformed = (u_texture_matrix * vec3(v_uvs,1.0)).xy;
 
 #if defined(USE_SHADOW_MAP) || defined(USE_PROJECTIVE_LIGHT)
 v_light_coord = (u_lightMatrix) * vec4(a_vertex,1.0);
 #endif
 
 gl_PointSize = 1000.0 / length(u_camera_eye - v_pos); 
 }