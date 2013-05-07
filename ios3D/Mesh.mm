	//
//  Mesh.m
//  ios3D
//
//  Created by Alun on 4/4/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import "Mesh.h"
#import "ResourceManager.h"
#import "Light.h"
#import "Renderer.h"


#define BUFFER_OFFSET(i) ((char *)NULL + i)

@implementation Mesh
{
    GLuint _program;
    GLuint _verticesVBO;
    GLuint _indicesVBO;
    GLuint _VAO;
    
    GLuint _indexBufferSize;
}

@synthesize material;

-(GLuint)getProgram{return _program;}
-(GLuint)getVerticesVBO{return _verticesVBO;}
-(GLuint)getIndicesVBO{return _indicesVBO;}
-(GLuint)getVAO{return _VAO;}
-(GLuint)getIndexBufferSize{return _indexBufferSize;}

-(id)initWithDataBuffer:(std::vector<GLfloat>)db indexBuffer:(std::vector<GLuint>)ib material:(Material *)mat;
{
    if ((self = [super init])) {
        
        //assign program
        self.material = mat;
        _program = mat.program;
        
        
        //copy buffers into c arrays
        GLfloat dataBuffer[db.size()];
        for(int i=0;i<db.size();i++)
            dataBuffer[i] = db[i];

        GLuint indexBuffer[ib.size()];
        for(int i=0;i<ib.size();i++)
            indexBuffer[i] = ib[i];

        _indexBufferSize = ib.size();
                
        // Make the vertex buffer

        glGenBuffers( 1, &_verticesVBO ); //generate a valid name for buffer
        glBindBuffer( GL_ARRAY_BUFFER, _verticesVBO ); //bind buffer to context
        //load onto graphics card memory - we can delete dataBuffer forthwith, if we want!
        glBufferData( GL_ARRAY_BUFFER, sizeof(dataBuffer), dataBuffer, GL_STATIC_DRAW ); 
        glBindBuffer( GL_ARRAY_BUFFER, 0 );
        
        // Make the indices buffer
        glGenBuffers( 1, &_indicesVBO );
        glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, _indicesVBO );
        glBufferData( GL_ELEMENT_ARRAY_BUFFER, sizeof(indexBuffer), indexBuffer, GL_STATIC_DRAW );
        glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, 0 );
        
        //Generate the Vertex array at address of _VAO
        glGenVertexArraysOES( 1, &_VAO );

    }
    return self;
}

- (void)renderWithModel:(GLKMatrix4)modelMatrix
{
    [super renderWithModel:modelMatrix];
    
    
    RenderInstance ri;
    ri.mesh = self;
    ri.mat = self.material;
    ri.model = GLKMatrix4Multiply([self getModelMatrix], modelMatrix);
    [[Renderer renderer] addInstance:ri];
    

}

@end
