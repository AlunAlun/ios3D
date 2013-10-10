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
@property (nonatomic, strong) Shader *shader;
@property (assign) bool isAnnotation;
@property (assign) int annotationNumber;
@property (assign) GLKVector3 annotationEndPoint;

-(id)initWithDataBuffer:(std::vector<GLfloat>)db indexBuffer:(std::vector<GLuint>)ib material:(Material*)mat;
-(void)LoadWaveFrontOBJ:(NSString*)fileName;
-(void)setDataBuffers:(std::vector<GLfloat>)db indexBuffer:(std::vector<GLuint>)ib;
-(void)assignMaterial:(Material *)mat;

-(GLuint)getProgram;
-(GLuint)getVerticesVBO;
-(GLuint)getIndicesVBO;
-(GLuint)getVAO;
-(GLuint)getIndexBufferSize;


@end
