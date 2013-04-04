//
//  Mesh.h
//  ios3D
//
//  Created by Alun on 4/4/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//
#import "Node.h"
#import "Material.h"
#import <stdio.h>
#include <vector>

@interface Mesh : Node

@property (nonatomic, strong) Material *material;


-(id)initWithDataBuffer:(std::vector<GLfloat>)db indexBuffer:(std::vector<GLuint>)ib material:(Material*)mat;


@end
