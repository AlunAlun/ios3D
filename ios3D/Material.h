//
//  Material.h
//  ios3D
//
//  Created by Alun on 3/27/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface Material : NSObject


@property(strong) GLKTextureInfo *texture;
@property(strong) GLKTextureInfo *textureDetail;
@property(strong) NSString *name;
@property (assign) GLuint program;
@property (assign) GLKVector4 color;
@property(assign) GLKVector4 diffuse;
@property(assign) GLKVector4 ambient;
@property(assign) float specular;
@property(assign) GLfloat shininess;

-(id)initWithTexture:(NSString*)filename ofType:(NSString*)type andProgram:(GLuint)program;
-(void)loadTexture:(NSString*)filename ofType:(NSString*)type;
-(void)loadDetailTexture:(NSString *)filename ofType:(NSString*)type;
-(id)initWithProgram:(GLuint)program;

@end
