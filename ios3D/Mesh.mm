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
        attribute = glGetAttribLocation(_program, "a_vertex");
        glEnableVertexAttribArray( attribute );
        glVertexAttribPointer( attribute, 3, GL_FLOAT, GL_FALSE, stride, NULL );
        
        // Give the normals to GL to pass them to the shader
        // We will have to add the VertexNormal attribute in the shader
        attribute = glGetAttribLocation(_program, "a_normal");
        glEnableVertexAttribArray( attribute );
        glVertexAttribPointer( attribute, 3, GL_FLOAT, GL_FALSE, stride, BUFFER_OFFSET( stride*3/8 ) );

        //check we have a texture coord in our shader
        if((attribute = glGetAttribLocation(_program, "a_vertexTexCoord0")) != -1)
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

    GLKMatrix4 modelMatrix = [self modelMatrix:YES];
    
    RenderInstance ri;
    ri.mesh = self;
    ri.mat = self.material;
    ri.model = modelMatrix;
    [[Renderer renderer] addInstance:ri];
    
    /*
    //apply all transformations
    modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, modelMatrix);
    
    // Bind the VAO and the program
    glBindVertexArrayOES( _VAO );
   
    glUseProgram( _program );
    
    Light *light = [[ResourceManager resources].scene getLight:0];
    Camera *cam = [[ResourceManager resources].scene getCamera:0];
    
    GLKMatrix4 viewMatrix = GLKMatrix4MakeLookAt(cam.position.x, cam.position.y, cam.position.z,
                                                cam.lookAt.x, cam.lookAt.y, cam.lookAt.z,
                                                                        0.0f, 1.0f, 0.0f);
    
    GLint matM = glGetUniformLocation(_program, "u_m");
    glUniformMatrix4fv(matM, 1, GL_FALSE, modelMatrix.m);
    
    GLint matV = glGetUniformLocation(_program, "u_v");
    glUniformMatrix4fv(matV, 1, GL_FALSE, viewMatrix.m);
    
    GLint matMV = glGetUniformLocation(_program, "u_mv");
    glUniformMatrix4fv(matMV, 1, GL_FALSE, modelViewMatrix.m);
    
    GLint matP = glGetUniformLocation(_program, "u_p");
    glUniformMatrix4fv(matP, 1, GL_FALSE, projectionMatrix.m);
    
    bool success;
    GLKMatrix4 normalModelMatrix4 = GLKMatrix4InvertAndTranspose(modelMatrix, &success);
    if (success) {
        GLKMatrix3 normalModelMatrix3 = GLKMatrix4GetMatrix3(normalModelMatrix4);
        GLint matNm = glGetUniformLocation(_program, "u_normal_model");
        glUniformMatrix3fv(matNm, 1, GL_FALSE, normalModelMatrix3.m);
    }
    
    bool success2;
    GLKMatrix4 normalMatrix4 = GLKMatrix4InvertAndTranspose(modelViewMatrix, &success2);
    if (success2) {
        GLKMatrix3 normalMatrix3 = GLKMatrix4GetMatrix3(normalMatrix4);
        GLint matN = glGetUniformLocation(_program, "u_normal");
        glUniformMatrix3fv(matN, 1, GL_FALSE, normalMatrix3.m);
    }
    

    GLint uCam = glGetUniformLocation(_program, "u_camera_eye");
    glUniform3f(uCam, cam.position.x, cam.position.y, cam.position.z);
    
    GLint uL = glGetUniformLocation(_program, "u_light_pos");
    glUniform3f(uL, light.position.x, light.position.y, light.position.z);
    
    GLint uLc = glGetUniformLocation(_program, "u_light_color");
    glUniform3f(uLc, light.diffuseColor.x, light.diffuseColor.y, light.diffuseColor.z);
    
    GLint uSpot = glGetUniformLocation(_program, "u_light_dir");
    glUniform3f(uSpot, light.direction.x, light.direction.y, light.direction.z);
    
    GLint uSpotCut = glGetUniformLocation(_program, "u_light_spot_cutoff");
    glUniform1f(uSpotCut, light.spotCosCutoff);
    
    GLint u;
    
    u = glGetUniformLocation(_program, "u_light_intensity");
    if(u!=-1)glUniform1f(u, light.intensity);
    
    u = glGetUniformLocation(_program, "u_mat_diffuse");
    if(u!=-1)glUniform4f(u, self.material.diffuse.r, self.material.diffuse.g, self.material.diffuse.b, 1.0f);
    
    u = glGetUniformLocation(_program, "u_mat_ambient");
    if(u!=-1)glUniform4f(u, self.material.ambient.r, self.material.ambient.g, self.material.ambient.b, 1.0f);
    
    u = glGetUniformLocation(_program, "u_mat_specular");
    if(u!=-1)glUniform1f(u, self.material.specular);
    
    u = glGetUniformLocation(_program, "u_mat_shininess");
    if(u!=-1)glUniform1f(u, self.material.shininess);
    
    u = glGetUniformLocation(_program, "u_textureSampler");
    if(u!=-1)glUniform1i(u, 0); //Texture unit 0 is for base images.
    
    u = glGetUniformLocation(_program, "u_detailSampler");
    if(u!=-1)glUniform1i(u, 2); //Texture unit 2 is for detail images.
    
    GLint detailBool = glGetUniformLocation(_program, "u_useDetail");
    
    //texture
    if (self.material.texture != nil)
    {
        glActiveTexture(GL_TEXTURE0 + 0);
        glBindTexture(self.material.texture.target, self.material.texture.name);
    }
    
    if (self.material.textureDetail != nil)
    {
        glActiveTexture(GL_TEXTURE0 + 2);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
        glBindTexture(self.material.textureDetail.target, self.material.textureDetail.name);
        glUniform1i(detailBool,1);
    }
    else
        glUniform1i(detailBool,0);
    
    
    
    // Draw!
    glDrawElements( GL_TRIANGLES, _indexBufferSize, GL_UNSIGNED_INT, NULL );
    
    */
}

@end
