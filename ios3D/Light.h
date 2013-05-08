//
//  Light.h
//  ios3D
//
//  Created by Alun on 4/5/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import "Node.h"

@interface Light : Node

@property(assign) GLKVector3 target;
@property(assign) GLfloat spotCosCutoff;
@property(assign) GLfloat intensity;
@property(assign) GLfloat near;
@property(assign) GLfloat far;
@property(assign) GLKVector3 diffuseColor;
@property(assign) GLKVector3 ambientColor;
@property(assign) GLKVector3 specularColor;

@end
