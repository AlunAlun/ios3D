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
#define SHADOWMAP_RES 1024

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
    GLuint _shadowMapTexture, _shadowMapFrameBuffer;
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

- (id)init {
    if ( (self = [super init]) ) {
        
        //setup Render To Texture screen triangles
        [self setupScreenSpaceQuad];
        //setup Render To Texture Framebuffer and Texture
        [self setupShadowMapBufferAndTexture];
        
    }
    return self;
}

-(void)setupScreenSpaceQuad
{
    //Make Shader
    ShaderLoader *loader = [[ShaderLoader alloc] init];
    NSArray *flags = [[NSArray alloc] initWithObjects:nil];
    _programScreenSpace  = [loader createProgramWithVertex:@"ShaderScreenSpaceVertex" Fragment:@"ShaderScreenSpaceFragment" Flags:flags];
    
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

-(void)setupShadowMapBufferAndTexture
{
    //Make Shader
    ShaderLoader *loader = [[ShaderLoader alloc] init];
    NSArray *flags = [[NSArray alloc] initWithObjects:@"SHADOW_DEPTH32", nil];
    _programShadow  = [loader createProgramWithVertex:@"ShaderShadowMapVertex" Fragment:@"ShaderShadowMapFragment" Flags:flags];
    
    //create texture
    
    glGenTextures(1, &_shadowMapTexture);
    glBindTexture(GL_TEXTURE_2D, _shadowMapTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, SHADOWMAP_RES, SHADOWMAP_RES, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    
    
    // create framebuffer
    glGenFramebuffersOES(1, &_shadowMapFrameBuffer);//1
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, _shadowMapFrameBuffer);//2
    // attach renderbuffer
    glFramebufferTexture2DOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_TEXTURE_2D, _shadowMapTexture, 0);
    
    GLuint depthbuffer;
    glGenRenderbuffers(1, &depthbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, depthbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24_OES, SHADOWMAP_RES, SHADOWMAP_RES);
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthbuffer);
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER_OES);
    if(status != GL_FRAMEBUFFER_COMPLETE)
        NSLog(@"Framebuffer status: %x", (int)status);
    
    // unbind frame buffer
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, 0);
}




- (void)renderShadowPass:(GLKMatrix4)viewMatrixLight :(GLKMatrix4)projectionMatrixLight;
{
    /* START RENDER TO TEXTURE */
    glViewport(0, 0, SHADOWMAP_RES, SHADOWMAP_RES);
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, _shadowMapFrameBuffer);
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear( GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT );
    //glCullFace(GL_FRONT);
    
    
    /* BIND PROGRAM AND GET UNIFORMS */
    glUseProgram( _programShadow );
    GLint attribute;
    GLsizei stride = sizeof(GLfloat) * 8; // 3 vert, 3 normal, 2 texture
    attribute = glGetAttribLocation(_programShadow, "a_vertex");
    GLint matdepthMVP = glGetUniformLocation(_programShadow, "u_depthMVP");
    
    //DRAW INSTANCES
    for (int i = 0; i < _instances.size(); i++)
    {
        
        
        GLKMatrix4 modelMatrix = _instances[i].model;
        GLKMatrix4 modelViewMatrixLight = GLKMatrix4Multiply(viewMatrixLight, modelMatrix);
        
        GLuint _VAO = [_instances[i].mesh getVAO];
        GLuint _indexBufferSize = [_instances[i].mesh getIndexBufferSize];
        GLuint _verticesVBO = [_instances[i].mesh getVerticesVBO];
        GLuint _indicesVBO = [_instances[i].mesh getIndicesVBO];
        
        // Bind the VAO and the program
        glBindVertexArrayOES( _VAO );
        
        
        //Bind buffers
        glBindBuffer( GL_ARRAY_BUFFER, _verticesVBO );
        glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, _indicesVBO );
        
        /************** ATTRIBUTES **************/
        
        
        glEnableVertexAttribArray( attribute );
        glVertexAttribPointer( attribute, 3, GL_FLOAT, GL_FALSE, stride, NULL );
        
        /****** UNIFORMS ********/
        
        GLKMatrix4 depthMVPMatrix = GLKMatrix4Multiply(projectionMatrixLight, modelViewMatrixLight);
        glUniformMatrix4fv(matdepthMVP, 1, GL_FALSE, depthMVPMatrix.m);
        
        // Draw!
        glDrawElements( GL_TRIANGLES, _indexBufferSize, GL_UNSIGNED_INT, NULL );
        
        //clear shit
        glBindVertexArrayOES( 0 );
    }
    
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, 0);
    /* END RENDER TO TEXTURE */

}




- (void)renderAllWithProjection:(GLKMatrix4)projection
{
    /*** GET LIGHTS AND CAMERAS FROM SCENE MANAGER ***/
    
    Light *light = [[ResourceManager resources].scene getLight:0];
    Camera *cam = [[ResourceManager resources].scene getCamera:0];
    
    /*** RENDER MATRICES ***/
    
    GLKMatrix4 viewMatrix = GLKMatrix4MakeLookAt(cam.position.x, cam.position.y, cam.position.z,
                                                 cam.lookAt.x, cam.lookAt.y, cam.lookAt.z,
                                                 0.0f, 1.0f, 0.0f);
    
    /*** SHADOW MATRICES ***/
    
    GLKVector3 lightDirection = GLKVector3Subtract(light.target, light.position);
    GLKMatrix4 viewMatrixLight = GLKMatrix4MakeLookAt(light.position.x, light.position.y, light.position.z,
                                                 light.target.x, light.target.y, light.target.z,
                                                 0.0f, 1.0f, 0.0f);
    GLKMatrix4 projectionMatrixLight = GLKMatrix4MakeOrtho(-100,150,-100,150,light.near,light.far);
    //projectionMatrixLight = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(45), 1024/728, 200, 700);
    
    /*** GENERAL FLAGS ***/
    
    glDisable(GL_DITHER);
    glDisable(GL_CULL_FACE);
    glEnable( GL_DEPTH_TEST );
    
    /*** SHADOW PASS ***/
    
    [self renderShadowPass:viewMatrixLight :projectionMatrixLight];
    
    
    /*** MAIN PASS ***/
    
     /* START SCREEN BUFFER */   
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, 1);
    glViewport(0, 0, [ResourceManager resources].screenWidth, [ResourceManager resources].screenHeight);
    GLKVector3 c = [ResourceManager resources].scene.backgroundColor;
    glClearColor(c.x, c.y, c.z, 1.0f);
    glClear( GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT );
   
    //DRAW INSTANCES
    for (int i = 0; i < _instances.size(); i++)
    {
        
        GLKMatrix4 modelMatrix = _instances[i].model;
        GLKMatrix4 modelViewMatrix = GLKMatrix4Multiply(viewMatrix, modelMatrix);
        
        GLKMatrix4 modelViewMatrixLight = GLKMatrix4Multiply(viewMatrixLight, modelMatrix);
        

        GLKMatrix4 depthMVPMatrix = GLKMatrix4Multiply(projectionMatrixLight, modelViewMatrixLight);
        
        GLKMatrix4 biasMatrix = GLKMatrix4Make(
                             0.5, 0.0, 0.0, 0.0,
                             0.0, 0.5, 0.0, 0.0,
                             0.0, 0.0, 0.5, 0.0,
                             0.5, 0.5, 0.5, 1.0
                             );
        GLKMatrix4 depthBiasMVP = GLKMatrix4Multiply(biasMatrix, depthMVPMatrix);

        /*** uncomment for DEPTH32 ***/
        //depthBiasMVP = depthMVPMatrix;

        GLuint _program = [_instances[i].mesh getProgram];
        GLuint _VAO = [_instances[i].mesh getVAO];
        GLuint _indexBufferSize = [_instances[i].mesh getIndexBufferSize];
        GLuint _verticesVBO = [_instances[i].mesh getVerticesVBO];
        GLuint _indicesVBO = [_instances[i].mesh getIndicesVBO];
        
        // Bind the VAO and the program
        glBindVertexArrayOES( _VAO );
        glUseProgram( _program);
        
        //Bind buffers
        glBindBuffer( GL_ARRAY_BUFFER, _verticesVBO );
        glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, _indicesVBO );
        
        /************** ATTRIBUTES **************/
        
        GLint attribute;
        GLsizei stride = sizeof(GLfloat) * 8; // 3 vert, 3 normal, 2 texture
        
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
          

        /****** UNIFORMS ********/

        

        GLint matM = glGetUniformLocation(_program, "u_m");
        glUniformMatrix4fv(matM, 1, GL_FALSE, modelMatrix.m);
        
        GLint matV = glGetUniformLocation(_program, "u_v");
        glUniformMatrix4fv(matV, 1, GL_FALSE, viewMatrix.m);
        
        GLint matMV = glGetUniformLocation(_program, "u_mv");
        glUniformMatrix4fv(matMV, 1, GL_FALSE, modelViewMatrix.m);
        
        GLint matP = glGetUniformLocation(_program, "u_p");
        glUniformMatrix4fv(matP, 1, GL_FALSE, projection.m);
        
        GLint matdepthMVP = glGetUniformLocation(_program, "u_depthBiasMVP");
        glUniformMatrix4fv(matdepthMVP, 1, GL_FALSE, depthBiasMVP.m);
        
        
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
        glUniform3f(uSpot, lightDirection.x, lightDirection.y, lightDirection.z);
        
        GLint uSpotCut = glGetUniformLocation(_program, "u_light_spot_cutoff");
        glUniform1f(uSpotCut, light.spotCosCutoff);
        
        GLint u;
        
        u = glGetUniformLocation(_program, "u_light_intensity");
        if(u!=-1)glUniform1f(u, light.intensity);
        
        u = glGetUniformLocation(_program, "u_mat_color");
        if(u!=-1)glUniform4f(u, _instances[i].mat.color.r, _instances[i].mat.color.g, _instances[i].mat.color.b, 1.0f);
        
        u = glGetUniformLocation(_program, "u_mat_diffuse");
        if(u!=-1)glUniform4f(u, _instances[i].mat.diffuse.r, _instances[i].mat.diffuse.g, _instances[i].mat.diffuse.b, 1.0f);
        
        u = glGetUniformLocation(_program, "u_mat_ambient");
        if(u!=-1)glUniform4f(u, _instances[i].mat.ambient.r, _instances[i].mat.ambient.g, _instances[i].mat.ambient.b, 1.0f);
        
        u = glGetUniformLocation(_program, "u_mat_specular");
        if(u!=-1)glUniform1f(u, _instances[i].mat.specular);
        
        u = glGetUniformLocation(_program, "u_mat_shininess");
        if(u!=-1)glUniform1f(u, _instances[i].mat.shininess);
        
        u = glGetUniformLocation(_program, "u_shadowMapSampler");
        if(u!=-1)glUniform1i(u, 0); //Texture unit 0 is for base images.
        
        u = glGetUniformLocation(_program, "u_detailSampler");
        if(u!=-1)glUniform1i(u, 2); //Texture unit 2 is for detail images.
        
        u = glGetUniformLocation(_program, "u_shadowMap");
        if(u!=-1)glUniform1i(u, 4); //Texture unit 4 is for shadow maps.
        
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
        
        //shadowmap
        glActiveTexture(GL_TEXTURE0 + 4);
        glBindTexture(GL_TEXTURE_2D, _shadowMapTexture);
        
    
        
        // Draw!
        glDrawElements( GL_TRIANGLES, _indexBufferSize, GL_UNSIGNED_INT, NULL );
        
        //clear shit
        glBindVertexArrayOES( 0 );
    }

    /*
    //DRAW SCREEN QUAD
    glBindVertexArrayOES( _VAOS );
    glUseProgram( _programScreenSpace );
    glActiveTexture(GL_TEXTURE0 + 0);
    glBindTexture(GL_TEXTURE_2D, _shadowMapTexture);
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
