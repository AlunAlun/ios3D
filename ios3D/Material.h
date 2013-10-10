//
//  Material.h
//  ios3D
//
//  Created by Alun on 3/27/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "Shader.h"

@interface Material : NSObject


@property(strong) GLKTextureInfo *texture;
@property(strong) GLKTextureInfo *textureDetail;
@property(strong) GLKTextureInfo *textureSpecular;
@property(strong) GLKTextureInfo *textureNormal;
@property(strong) GLKTextureInfo *textureOpacity;
@property(strong) GLKTextureInfo *textureAmbient;
@property(strong) GLKTextureInfo *textureEmissive;
@property(strong) NSString *name;
@property (assign) GLuint program;
@property (nonatomic, strong) Shader *shader;
@property (assign) GLKVector4 color;
@property(assign) GLKVector4 diffuse;
@property(assign) GLKVector3 ambient;
@property(assign) GLKVector3 emissive;
@property(assign) GLKVector3 velvet;
@property(assign) GLKVector3 detailInfo;
@property(assign) float velvet_exp;
@property(assign) float specular;
@property(assign) GLfloat shininess;
@property(assign) float backlightFactor;
@property(assign) float normalMapFactor;
@property(assign) float brightnessFactor;
@property(assign) float colorclipFactor;
@property(assign) float lightOffset;

@property(assign) bool drawLines;

-(id)initWithTexture:(NSString*)filename andShader:(Shader*)aShader;
-(void)loadTexture:(NSString*)filename ofType:(NSString*)type;
-(void)loadDetailTexture:(NSString *)filename ofType:(NSString*)type;
-(id)initWithProgram:(GLuint)program;
-(id)initWithShader:(Shader*)aShader;

@end
