//
//  ShaderLoader.h
//  ios3D
//
//  Created by Alun on 4/3/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ShaderLoader : NSObject

- (GLuint)compileShader:(NSString*)shaderName withType:(GLenum)shaderType Flags:(NSArray*)flags;
-(GLuint)createProgramWithVertex:(NSString*)vertex Fragment:(NSString*)fragment Flags:(NSArray*)flags;

@end
