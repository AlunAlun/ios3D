//
//  Line.m
//  ios3D
//
//  Created by Alun on 7/25/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import "Line.h"
#import "ResourceManager.h"
#import "Renderer.h"


@implementation Line
{
    
    GLuint _program;
    GLuint _verticesVBO;
    GLuint _indicesVBO;
    GLuint _VAO;
    
    GLuint _indexBufferSize;
}

-(GLuint)getProgram{return _program;}
-(GLuint)getVerticesVBO{return _verticesVBO;}
-(GLuint)getVAO{return _VAO;}

-(id)initWithDataBuffer:(std::vector<GLfloat>)db material:(Material *)mat
{
    if ((self = [super init])) {
        
        //assign program
        self.material = mat;
        self.shader = mat.shader;
        _program = self.shader.program;
        
        
        //copy buffers into c arrays
        GLfloat dataBuffer[db.size()];
        for(int i=0;i<db.size();i++)
            dataBuffer[i] = db[i];
        
        
        // Have OpenGL generate a buffer name and store it in the buffer object array
        glGenBuffers(1, &_verticesVBO );
        glBindBuffer( GL_ARRAY_BUFFER, _verticesVBO ); //bind buffer to context
        glBufferData( GL_ARRAY_BUFFER, sizeof(dataBuffer), dataBuffer, GL_STATIC_DRAW );
        glBindBuffer( GL_ARRAY_BUFFER, 0 );
        
        glGenVertexArraysOES( 1, &_VAO );
        
    }
    return self;
}

- (void)renderWithModel:(GLKMatrix4)modelMatrix
{
    [super renderWithModel:modelMatrix];
    
    
    RenderInstance ri;
    ri.line = self;
    ri.mesh = nil;
    ri.mat = self.material;
    ri.model = GLKMatrix4Multiply([self getModelMatrix], modelMatrix);
    [[Renderer renderer] addInstance:ri];
    
    
}


@end
