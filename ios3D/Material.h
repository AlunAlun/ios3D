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
@property(strong) NSString *name;
@property GLKVector4 diffuse;
@property GLKVector4 ambient;
@property GLKVector4 specular;
@property GLfloat shininess;

-(id)initWithTexture:(NSString*)filename ofType:(NSString*)type;
-(void)loadTexture:(NSString*)filename ofType:(NSString*)type;

@end
