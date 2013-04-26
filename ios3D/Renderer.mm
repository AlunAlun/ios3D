//
//  Renderer.m
//  ios3D
//
//  Created by Alun on 4/6/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import "Renderer.h"
#import "ResourceManager.h"
#import "ShaderLoader.h"

#define BUFFER_OFFSET(i) ((char *)NULL + i)

GLfloat R2TVerts[32] =
{
    -1, -1, 0, 0, 0, -1, 0, 0,
    -1,  1, 0, 0, 0, -1, 0, 1,
    1,  1, 0, 0, 0, -1, 1, 1,
    1, -1, 0, 0, 0, -1, 1, 0
};

GLuint R2TInds[6] =
{
    0, 1, 2,
    2, 3, 0
};

@interface Renderer()
{
    GLuint _programScreenSpace;
    GLuint _programShadow;
    GLuint _verticesVBOS;
    GLuint _indicesVBOS;
    GLuint _VAOS;
    GLuint _texture, _framebuffer;
}

@end

@implementation Renderer



static Renderer *renderSingleton = nil;    // static instance variable

+ (Renderer *)renderer {
    if (renderSingleton == nil) {
        renderSingleton = [[super allocWithZone:NULL] init];
    }
    return renderSingleton;
}

-(void)setupR2TQuad
{
    ShaderLoader *loader = [[ShaderLoader alloc] init];
    NSArray *flags = [[NSArray alloc] initWithObjects:nil];
    
    _programScreenSpace  = [loader createProgramWithVertex:@"ShaderScreenSpaceVertex" Fragment:@"ShaderScreenSpaceFragment" Flags:flags];
    
    flags = [[NSArray alloc] initWithObjects:@"SHADOWMAP", nil];
    _programShadow  = [loader createProgramWithVertex:@"ShaderUberVertex" Fragment:@"ShaderUberFragment" Flags:flags];
    
    
    // Make the vertex buffer
    glGenBuffers( 1, &_verticesVBOS );
    glBindBuffer( GL_ARRAY_BUFFER, _verticesVBOS );
    glBufferData( GL_ARRAY_BUFFER, sizeof(R2TVerts), R2TVerts, GL_STATIC_DRAW );
    glBindBuffer( GL_ARRAY_BUFFER, 0 );
    
    // Make the indices buffer
    glGenBuffers( 1, &_indicesVBOS );
    glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, _indicesVBOS );
    glBufferData( GL_ELEMENT_ARRAY_BUFFER, sizeof(R2TInds), R2TInds, GL_STATIC_DRAW );
    glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, 0 );
    
    // Bind the attribute pointers to the VAO
    GLint attribute;
    GLsizei stride = sizeof(GLfloat) * 8; // 3 vert, 3 normal, 2 texture
    glGenVertexArraysOES( 1, &_VAOS );
    glBindVertexArrayOES( _VAOS );
    
    glBindBuffer( GL_ARRAY_BUFFER, _verticesVBOS );
    
    //Vert positions
    attribute = glGetAttribLocation(_programScreenSpace, "a_vertex");
    glEnableVertexAttribArray( attribute );
    glVertexAttribPointer( attribute, 3, GL_FLOAT, GL_FALSE, stride, NULL );
    
    glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, _indicesVBOS );
    
    glBindVertexArrayOES( 0 );
}

-(void)setupR2TBufferAndTexture
{
    //create texture
    
    glGenTextures(1, &_texture);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    //glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1024, 1024, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1024, 1024, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    
    
    // create framebuffer
    glGenFramebuffersOES(1, &_framebuffer);//1
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, _framebuffer);//2
    // attach renderbuffer
    //glFramebufferTexture2DOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_TEXTURE_2D, _texInfo.name, 0); //3
    glFramebufferTexture2DOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_TEXTURE_2D, _texture, 0);
    
    GLuint depthbuffer;
    glGenRenderbuffers(1, &depthbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, depthbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, 1024, 1024);
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthbuffer);
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER_OES);
    if(status != GL_FRAMEBUFFER_COMPLETE)
        NSLog(@"Framebuffer status: %x", (int)status);
    
    // unbind frame buffer
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, 0);
}

- (id)init {
    if ( (self = [super init]) ) {
        
        //setup Render To Texture screen triangles
        [self setupR2TQuad];
        //setup Render To Texture Framebuffer and Texture
        [self setupR2TBufferAndTexture];
        
        
        
    }
    return self;
}


- (void)renderAllWithProjection:(GLKMatrix4)projection
{
    
    Light *light = [[ResourceManager resources].scene getLight:0];
    Camera *cam = [[ResourceManager resources].scene getCamera:0];
    
    GLKMatrix4 viewMatrix = GLKMatrix4MakeLookAt(cam.position.x, cam.position.y, cam.position.z,
                                                 cam.lookAt.x, cam.lookAt.y, cam.lookAt.z,
                                                 0.0f, 1.0f, 0.0f);
    
    GLKVector3 lightLookAt = GLKVector3Add(light.position, light.direction);
    
    GLKMatrix4 viewMatrixLight = GLKMatrix4MakeLookAt(light.position.x, light.position.y, light.position.z,
                                                 lightLookAt.x, lightLookAt.y, lightLookAt.z,
                                                 0.0f, 1.0f, 0.0f);
    
    
    /* START RENDER TO TEXTURE */
    glViewport(0, 0, 1024, 1024);
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, _framebuffer);
    glClearColor(0.9f, 0.9f, 0.9f, 1.0f);
    glClear( GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT );
    
    for (int i = 0; i < _instances.size(); i++)
    {
        viewMatrix = viewMatrixLight;
        GLKMatrix4 modelMatrix = _instances[i].model;
        GLKMatrix4 modelViewMatrix = GLKMatrix4Multiply(viewMatrix, modelMatrix);
        
        projection = GLKMatrix4MakeOrtho(-100,100,-100,100,0,600);
        
        GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4Multiply(projection, modelViewMatrix);
        
        GLuint _program = [_instances[i].mesh getProgram];
        GLuint _VAO = [_instances[i].mesh getVAO];
        GLuint _indexBufferSize = [_instances[i].mesh getIndexBufferSize];
        
        // Bind the VAO and the program
        glBindVertexArrayOES( _VAO );
        	
        //glUseProgram( _program );
        glUseProgram( _programShadow );
     
        GLint matM = glGetUniformLocation(_program, "u_m");
        glUniformMatrix4fv(matM, 1, GL_FALSE, modelMatrix.m);
        
        GLint matV = glGetUniformLocation(_program, "u_v");
        glUniformMatrix4fv(matV, 1, GL_FALSE, viewMatrix.m);
        
        GLint matMV = glGetUniformLocation(_program, "u_mv");
        glUniformMatrix4fv(matMV, 1, GL_FALSE, modelViewMatrix.m);
        
        GLint matdepthP = glGetUniformLocation(_program, "u_depthP");
        glUniformMatrix4fv(matdepthP, 1, GL_FALSE, projection.m);
        
        GLint matP = glGetUniformLocation(_program, "u_p");
        glUniformMatrix4fv(matP, 1, GL_FALSE, projection.m);
        
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
        if(u!=-1)glUniform4f(u, _instances[i].mat.diffuse.r, _instances[i].mat.diffuse.g, _instances[i].mat.diffuse.b, 1.0f);
        
        u = glGetUniformLocation(_program, "u_mat_ambient");
        if(u!=-1)glUniform4f(u, _instances[i].mat.ambient.r, _instances[i].mat.ambient.g, _instances[i].mat.ambient.b, 1.0f);
        
        u = glGetUniformLocation(_program, "u_mat_specular");
        if(u!=-1)glUniform1f(u, _instances[i].mat.specular);
        
        u = glGetUniformLocation(_program, "u_mat_shininess");
        if(u!=-1)glUniform1f(u, _instances[i].mat.shininess);
        
        u = glGetUniformLocation(_program, "u_textureSampler");
        if(u!=-1)glUniform1i(u, 0); //Texture unit 0 is for base images.
        
        u = glGetUniformLocation(_program, "u_detailSampler");
        if(u!=-1)glUniform1i(u, 2); //Texture unit 2 is for detail images.
        
        GLint detailBool = glGetUniformLocation(_program, "u_useDetail");
        
        //texture
        if (_instances[i].mat.texture != nil)
        {
            glActiveTexture(GL_TEXTURE0 + 0);
            glBindTexture(_instances[i].mat.texture.target, _instances[i].mat.texture.name);
        }
        
        if (_instances[i].mat.textureDetail != nil)
        {
            glActiveTexture(GL_TEXTURE0 + 2);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
            glBindTexture(_instances[i].mat.textureDetail.target, _instances[i].mat.textureDetail.name);
            glUniform1i(detailBool,1);
        }
        else
            glUniform1i(detailBool,0);
        
        // Draw!
        glDrawElements( GL_TRIANGLES, _indexBufferSize, GL_UNSIGNED_INT, NULL );
    }
    

    glBindFramebufferOES(GL_FRAMEBUFFER_OES, 0);
    /* END RENDER TO TEXTURE */
   
     /* START SCREEN BUFFER */   
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, 1);
    glViewport(0, 0, 1024, 768);
    
    //DRAW INSTANCES
    for (int i = 0; i < _instances.size(); i++)
    {
        GLKMatrix4 modelMatrix = _instances[i].model;
        GLKMatrix4 modelViewMatrix = GLKMatrix4Multiply(viewMatrix, modelMatrix);
        
        GLuint _program = [_instances[i].mesh getProgram];
        GLuint _VAO = [_instances[i].mesh getVAO];
        GLuint _indexBufferSize = [_instances[i].mesh getIndexBufferSize];
        
        // Bind the VAO and the program
        glBindVertexArrayOES( _VAO );
        
        glUseProgram( _program );
        
        GLint matM = glGetUniformLocation(_program, "u_m");
        glUniformMatrix4fv(matM, 1, GL_FALSE, modelMatrix.m);
        
        GLint matV = glGetUniformLocation(_program, "u_v");
        glUniformMatrix4fv(matV, 1, GL_FALSE, viewMatrix.m);
        
        GLint matMV = glGetUniformLocation(_program, "u_mv");
        glUniformMatrix4fv(matMV, 1, GL_FALSE, modelViewMatrix.m);
        
        GLint matP = glGetUniformLocation(_program, "u_p");
        glUniformMatrix4fv(matP, 1, GL_FALSE, projection.m);
        
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
        if(u!=-1)glUniform4f(u, _instances[i].mat.diffuse.r, _instances[i].mat.diffuse.g, _instances[i].mat.diffuse.b, 1.0f);
        
        u = glGetUniformLocation(_program, "u_mat_ambient");
        if(u!=-1)glUniform4f(u, _instances[i].mat.ambient.r, _instances[i].mat.ambient.g, _instances[i].mat.ambient.b, 1.0f);
        
        u = glGetUniformLocation(_program, "u_mat_specular");
        if(u!=-1)glUniform1f(u, _instances[i].mat.specular);
        
        u = glGetUniformLocation(_program, "u_mat_shininess");
        if(u!=-1)glUniform1f(u, _instances[i].mat.shininess);
        
        u = glGetUniformLocation(_program, "u_textureSampler");
        if(u!=-1)glUniform1i(u, 0); //Texture unit 0 is for base images.
        
        u = glGetUniformLocation(_program, "u_detailSampler");
        if(u!=-1)glUniform1i(u, 2); //Texture unit 2 is for detail images.
        
        GLint detailBool = glGetUniformLocation(_program, "u_useDetail");
        
        //texture
        if (_instances[i].mat.texture != nil)
        {
            glActiveTexture(GL_TEXTURE0 + 0);
            glBindTexture(_instances[i].mat.texture.target, _instances[i].mat.texture.name);
        }
        
        if (_instances[i].mat.textureDetail != nil)
        {
            glActiveTexture(GL_TEXTURE0 + 2);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
            glBindTexture(_instances[i].mat.textureDetail.target, _instances[i].mat.textureDetail.name);
            glUniform1i(detailBool,1);
        }
        else
            glUniform1i(detailBool,0);
        
        // Draw!
        glDrawElements( GL_TRIANGLES, _indexBufferSize, GL_UNSIGNED_INT, NULL );
    }

    //DRAW SCREEN QUAD
    glBindVertexArrayOES( _VAOS );
    glUseProgram( _programScreenSpace );
    glActiveTexture(GL_TEXTURE0 + 0);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glDrawElements( GL_TRIANGLES, sizeof(R2TInds)/sizeof(GLuint), GL_UNSIGNED_INT, NULL );
    
    
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, 0);
    /* END SCREEN BUFFER */   
     
     
     
     
    
}

- (void)addInstance:(RenderInstance)toAdd
{
    _instances.push_back(toAdd);
}

- (std::vector<RenderInstance>)getInstances
{
    return _instances;
}

- (void)clearInstances
{
    _instances.clear();
}

- (int)getNumInstances
{
    return _instances.size();
}

@end
