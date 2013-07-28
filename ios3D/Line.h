//
//  Line.h
//  ios3D
//
//  Created by Alun on 7/25/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import "Node.h"
#import "Material.h"
#import <stdio.h>
#include <vector>

@interface Line : Node

@property (nonatomic, strong) Material *material;
@property (nonatomic, strong) Shader *shader;

-(id)initWithDataBuffer:(std::vector<GLfloat>)db material:(Material*)mat;

-(GLuint)getProgram;
-(GLuint)getVerticesVBO;
-(GLuint)getVAO;

@end
