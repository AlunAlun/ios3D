//
//  Camera.h
//  ios3D
//
//  Created by Alun on 4/4/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import "Node.h"

@interface Camera : Node

@property(assign) GLKVector3 lookAt;
@property(assign) GLfloat clipNear;
@property(assign) GLfloat clipFar;
@property(assign) GLfloat fov;
	

@end
