//
//  ShaderLoader.h
//  ios3D
//
//  Created by Alun on 4/3/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    a_vertex,
    a_normal,
    a_coords,
} ShaderAttributes;

typedef enum {
    u_m,
    u_v,
    u_mv,
    u_p,
    u_depthBiasMVP,
    u_normal_model,
    u_camera_eye,
    u_light_pos,
    u_light_color,
    u_light_dir,
    u_light_intensity,
    u_mat_color,
    u_mat_diffuse,
    u_mat_ambient,
    u_mat_specular,
    u_mat_shininess,
    u_shadowMap,
    u_depthMVP,
    u_detailSampler
} GeneralShaderUniforms;

typedef enum {
    uShad_depthMVP
} ShadowShaderUniforms;

typedef enum {
    uScreen_textureSampler
} ScreenShaderUniforms;

@interface Shader : NSObject

@property (assign) GLint program;
@property (assign) GLint programMultiPass;
@property (assign) bool uniformsSet;
@property (nonatomic, readonly) GLuint *uniforms;

- (GLuint)compileShader:(NSString*)shaderName withType:(GLenum)shaderType Flags:(NSArray*)flags;
-(id)initProgramWithVertex:(NSString*)vertex Fragment:(NSString*)fragment Flags:(NSArray*)flags; // Uniforms:(NSArray*)theUniforms;

@end
