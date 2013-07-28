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
@property(strong) NSString *name;
@property (assign) GLuint program;
@property (nonatomic, strong) Shader *shader;
@property (assign) GLKVector4 color;
@property(assign) GLKVector4 diffuse;
@property(assign) GLKVector3 ambient;
@property(assign) float specular;
@property(assign) GLfloat shininess;

-(id)initWithTexture:(NSString*)filename andShader:(Shader*)aShader;
-(void)loadTexture:(NSString*)filename ofType:(NSString*)type;
-(void)loadDetailTexture:(NSString *)filename ofType:(NSString*)type;
-(id)initWithProgram:(GLuint)program;
-(id)initWithShader:(Shader*)aShader;

@end
