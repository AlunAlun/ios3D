//
//  SimpleCube.h
//  ios3D
//
//  Created by Alun on 3/27/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import "Node.h"
#import "Material.h"

@interface SimpleCube : Node

@property (strong, nonatomic) Material *material;

- (id)initWithProgram:(GLuint)program;
//- (id)initWithMaterial:(Material *)mat program:(GLuint)program;

@end
