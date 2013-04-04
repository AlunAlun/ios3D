	//
//  Mesh.m
//  ios3D
//
//  Created by Alun on 4/4/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import "Mesh.h"


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

-(id)initWithDataBuffer:(std::vector<GLfloat>)db indexBuffer:(std::vector<GLuint>)ib material:(Material *)mat;
{
    if ((self = [super init])) {
        
        self.material = mat;
        self.materialDefault = mat;
        _program = mat.program;
        
        GLfloat dataBuffer[db.size()];
        for(int i=0;i<db.size();i++)
        {
            dataBuffer[i] = db[i];

        }


        GLuint indexBuffer[ib.size()];

        for(int i=0;i<ib.size();i++)
        {
          indexBuffer[i] = ib[i];

        }
        _indexBufferSize = ib.size();
        
        
        // **************************************************
        // ***** Fill OpenGL Buffers
        // **************************************************
        
        // Make the vertex buffer

        glGenBuffers( 1, &_verticesVBO );
        glBindBuffer( GL_ARRAY_BUFFER, _verticesVBO );
        glBufferData( GL_ARRAY_BUFFER, sizeof(dataBuffer), dataBuffer, GL_STATIC_DRAW );
        glBindBuffer( GL_ARRAY_BUFFER, 0 );
        
        // Make the indices buffer
        glGenBuffers( 1, &_indicesVBO );
        glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, _indicesVBO );
        glBufferData( GL_ELEMENT_ARRAY_BUFFER, sizeof(indexBuffer), indexBuffer, GL_STATIC_DRAW );
        glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, 0 );
        
        // Bind the attribute pointers to the VAO
        GLint attribute;
        GLsizei stride = sizeof(GLfloat) * 8; // 3 vert, 3 normal, 2 texture
        glGenVertexArraysOES( 1, &_VAO );
        glBindVertexArrayOES( _VAO );
        
        glBindBuffer( GL_ARRAY_BUFFER, _verticesVBO );
        
        //Vert positions
        attribute = glGetAttribLocation(_program, "VertexPosition");
        glEnableVertexAttribArray( attribute );
        glVertexAttribPointer( attribute, 3, GL_FLOAT, GL_FALSE, stride, NULL );
        
        // Give the normals to GL to pass them to the shader
        // We will have to add the VertexNormal attribute in the shader
        attribute = glGetAttribLocation(_program, "VertexNormal");
        glEnableVertexAttribArray( attribute );
        glVertexAttribPointer( attribute, 3, GL_FLOAT, GL_FALSE, stride, BUFFER_OFFSET( stride*3/8 ) );

        //check we have a texture coord in our shader
        if((attribute = glGetAttribLocation(_program, "VertexTexCoord0")) != -1)
        {
            glEnableVertexAttribArray( attribute );
            glVertexAttribPointer( attribute, 2, GL_FLOAT, GL_FALSE, stride, BUFFER_OFFSET( stride*6/8 ) );
        }
        
        glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, _indicesVBO );
        
        glBindVertexArrayOES( 0 );
         

    }
    return self;
}

- (void)renderWithMV:(GLKMatrix4)modelViewMatrix P:(GLKMatrix4)projectionMatrix
{
    [super renderWithMV:modelViewMatrix P:projectionMatrix];

    //apply all transformations
    modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, [self modelMatrix:YES]);
    
    // Bind the VAO and the program
    glBindVertexArrayOES( _VAO );

    glUseProgram( _program );
    
    
    GLint matMV = glGetUniformLocation(_program, "ModelViewMatrix");
    glUniformMatrix4fv(matMV, 1, GL_FALSE, modelViewMatrix.m);
    
    GLint matP = glGetUniformLocation(_program, "ProjectionMatrix");
    glUniformMatrix4fv(matP, 1, GL_FALSE, projectionMatrix.m);
    
    bool success;
    GLKMatrix4 normalMatrix4 = GLKMatrix4InvertAndTranspose(modelViewMatrix, &success);
    if (success) {
        GLKMatrix3 normalMatrix3 = GLKMatrix4GetMatrix3(normalMatrix4);
        GLint matN = glGetUniformLocation(_program, "NormalMatrix");
        glUniformMatrix3fv(matN, 1, GL_FALSE, normalMatrix3.m);
    }
    
    
    GLint matL = glGetUniformLocation(_program, "LightPosition");
    GLKVector3 l = GLKVector3Make(100.0f , 300.0f, 300.0f);
    glUniform3f(matL, l.x, l.y, l.z);
    
    GLint u;
    
    u = glGetUniformLocation(_program, "LightIntensity");
    if(u!=-1)glUniform1f(u, 1.3);
    
    u = glGetUniformLocation(_program, "matDiffuse");
    if(u!=-1)glUniform4f(u, self.materialDefault.diffuse.r, self.materialDefault.diffuse.g, self.materialDefault.diffuse.b, 1.0f);
    
    u = glGetUniformLocation(_program, "matAmbient");
    if(u!=-1)glUniform4f(u, self.materialDefault.ambient.r, self.materialDefault.ambient.g, self.materialDefault.ambient.b, 1.0f);
    
    u = glGetUniformLocation(_program, "matSpecular");
    if(u!=-1)glUniform4f(u, self.materialDefault.specular.r, self.materialDefault.specular.g, self.materialDefault.specular.b, 1.0f);
    
    u = glGetUniformLocation(_program, "matShininess");
    if(u!=-1)glUniform1f(u, self.materialDefault.shininess);
    
    u = glGetUniformLocation(_program, "TextureSampler");
    if(u!=-1)glUniform1i(u, 0); //Texture unit 0 is for base images.
    
    u = glGetUniformLocation(_program, "DetailSampler");
    if(u!=-1)glUniform1i(u, 2); //Texture unit 2 is for detail images.
    
    GLint detailBool = glGetUniformLocation(_program, "UseDetail");
    
    //texture
    if (self.materialDefault.texture != nil)
    {
        glActiveTexture(GL_TEXTURE0 + 0);
        glBindTexture(self.materialDefault.texture.target, self.materialDefault.texture.name);
    }
    
    if (self.materialDefault.textureDetail != nil)
    {
        glActiveTexture(GL_TEXTURE0 + 2);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
        glBindTexture(self.materialDefault.textureDetail.target, self.materialDefault.textureDetail.name);
        glUniform1i(detailBool,1);
    }
    else
        glUniform1i(detailBool,0);
    
    
    // Draw!
    glDrawElements( GL_TRIANGLES, _indexBufferSize, GL_UNSIGNED_INT, NULL );
    
    
}

@end
