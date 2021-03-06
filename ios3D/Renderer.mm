//
//  Renderer.m
//  ios3D
//
//  Created by Alun on 4/6/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import "Renderer.h"
#import "ResourceManager.h"
#import "Shader.h"

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
    bool _shouldSetUniforms;
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
        
        bool _shouldSetUniforms = true;
        
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
    //Shader *loader = [[Shader alloc] init];
    NSArray *flags = [[NSArray alloc] initWithObjects:nil];
    //_programScreenSpace  = [loader createProgramWithVertex:@"ShaderScreenSpaceVertex" Fragment:@"ShaderScreenSpaceFragment" Flags:flags];
    Shader *screenSpaceShader = [[Shader alloc] initProgramWithVertex:@"ShaderScreenSpaceVertex" Fragment:@"ShaderScreenSpaceFragment" Flags:flags];
    _programScreenSpace = screenSpaceShader.program;
    
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
    //Shader *loader = [[Shader alloc] init];
    NSArray *flags = [[NSArray alloc] initWithObjects:nil];
    //_programShadow  = [loader createProgramWithVertex:@"ShaderShadowMapVertex" Fragment:@"ShaderShadowMapFragment" Flags:flags];
    Shader *shadowShader = [[Shader alloc] initProgramWithVertex:@"ShaderShadowMapVertex" Fragment:@"ShaderShadowMapFragment" Flags:flags];
    _programShadow = shadowShader.program;
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




- (void)renderShadowPass
{
    Light *light = [[ResourceManager resources].scene getLight:0];
    
    GLKMatrix4 viewMatrixLight = GLKMatrix4MakeLookAt(light.position.x, light.position.y, light.position.z,
                                                      light.target.x, light.target.y, light.target.z,
                                                      0.0f, 1.0f, 0.0f);
    int lfsd2 = (int)light.frustrumSize/2;
    GLKMatrix4 projectionMatrixLight = GLKMatrix4MakeOrtho(-lfsd2,lfsd2,-lfsd2,lfsd2,light.near,light.far);
    //GLKMatrix4 projectionMatrixLight = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(light.angle), 1024/728, 200, 700);
    
    /* START RENDER TO TEXTURE */
    glViewport(0, 0, SHADOWMAP_RES, SHADOWMAP_RES);
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, _shadowMapFrameBuffer);
    ///glClearColor(1.0f, 1.0f, 1.0f, 1.0f); - says it's redundant
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
        //glDrawElements( GL_TRIANGLES, 3, GL_UNSIGNED_INT, NULL );
        
        //clear shit
        glBindVertexArrayOES( 0 );
    }
    
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, 0);
    /* END RENDER TO TEXTURE */

}

-(void)setWebGLUniforms:(GLint)program index:(int)i proj:(GLKMatrix4)p
{
    Scene *scene = [ResourceManager resources].scene;
    Camera *cam = [scene getCamera:0];
    Light *light = [scene getLight:0];
    GLKVector3 lightDirection = GLKVector3Subtract(light.position, light.target);
    lightDirection = GLKVector3Normalize(lightDirection);
    
    GLKMatrix4 m = _instances[i].model;
    GLKMatrix4 v = GLKMatrix4MakeLookAt(cam.position.x, cam.position.y, cam.position.z,
                                                 cam.lookAt.x, cam.lookAt.y, cam.lookAt.z,
                                                 0.0f, 1.0f, 0.0f);
    GLKMatrix4 vp = GLKMatrix4Multiply(p, v);
    GLKMatrix4 mvp = GLKMatrix4Multiply(vp, m);
    
    GLint u;
    
    /*MATRICES & CAMERA*/
    
    u = glGetUniformLocation(program, "u_mvp");
    if(u!=-1) glUniformMatrix4fv(u, 1, GL_FALSE, mvp.m);
    
    u = glGetUniformLocation(program, "u_model");
    if(u!=-1) glUniformMatrix4fv(u, 1, GL_FALSE, m.m);
    
    u = glGetUniformLocation(program, "u_viewprojection");
    if(u!=-1) glUniformMatrix4fv(u, 1, GL_FALSE, vp.m);

    bool success;
    GLKMatrix4 normalModelMatrix4 = GLKMatrix4InvertAndTranspose(m, &success);
    if (success) {
        GLKMatrix3 normalModelMatrix3 = GLKMatrix4GetMatrix3(normalModelMatrix4);
        u = glGetUniformLocation(program, "u_normal_model");
        if(u!=-1) glUniformMatrix3fv(u, 1, GL_FALSE, normalModelMatrix3.m);
    }
    
    u = glGetUniformLocation(program, "u_camera_eye");
    if(u!=-1) glUniform3f(u, cam.position.x, cam.position.y, cam.position.z);
    u = glGetUniformLocation(program, "u_camera_planes");
    if(u!=-1) glUniform2f(u, cam.clipNear, cam.clipFar);
    
    /*MATERIAL*/
    
    u = glGetUniformLocation(program, "u_material_color");
    if(u!=-1)glUniform4f(u, _instances[i].mat.color.r, _instances[i].mat.color.g, _instances[i].mat.color.b, 1.0f);
    u = glGetUniformLocation(program, "u_ambient_color");
    if(u!=-1)glUniform3f(u, scene.ambient.r * _instances[i].mat.ambient.r,
                         scene.ambient.g * _instances[i].mat.ambient.g,
                         scene.ambient.b * _instances[i].mat.ambient.b);
    u = glGetUniformLocation(program, "u_diffuse_color");
    if(u!=-1)glUniform3f(u, _instances[i].mat.diffuse.r, _instances[i].mat.diffuse.g, _instances[i].mat.diffuse.b);
    u = glGetUniformLocation(program, "u_emissive_color");
    if(u!=-1)glUniform3f(u, _instances[i].mat.emissive.r, _instances[i].mat.emissive.g, _instances[i].mat.emissive.b);
    u = glGetUniformLocation(program, "u_specular");
    if(u!=-1) glUniform2f(u, _instances[i].mat.specular, _instances[i].mat.shininess);//??????????????????????????????
    u = glGetUniformLocation(program, "u_detail_info");
    if(u!=-1)glUniform3f(u, _instances[i].mat.detailInfo.r, _instances[i].mat.detailInfo.g, _instances[i].mat.detailInfo.b);
    u = glGetUniformLocation(program, "u_velvet_info");
    if(u!=-1)glUniform4f(u, _instances[i].mat.velvet.r, _instances[i].mat.velvet.g, _instances[i].mat.velvet.b,
                         _instances[i].mat.velvet_exp);
    u = glGetUniformLocation(program, "u_backlight_factor");
    if(u!=-1)glUniform1f(u, _instances[i].mat.backlightFactor);
    u = glGetUniformLocation(program, "u_normalmap_factor");
    if(u!=-1)glUniform1f(u, _instances[i].mat.normalMapFactor);
    

    
    u = glGetUniformLocation(program, "u_fog_info");
    if(u!=-1)glUniform3f(u, 0.0, 0.0, 0.0);
    u = glGetUniformLocation(program, "u_fog_color");
    if(u!=-1)glUniform3f(u, 0.0, 0.0, 0.0);

    
    /*LIGHT*/
    
    u = glGetUniformLocation(program, "u_light_pos");
    if(u!=-1)glUniform3f(u, light.position.x, light.position.y, light.position.z);
    u = glGetUniformLocation(program, "u_light_front");
    if(u!=-1)glUniform3f(u, lightDirection.x, lightDirection.y, lightDirection.z);
    u = glGetUniformLocation(program, "u_light_color");
    if(u!=-1)glUniform3f(u, light.diffuseColor.x, light.diffuseColor.y, light.diffuseColor.z);
    u = glGetUniformLocation(program, "u_light_angle");
    if(u!=-1)glUniform4f(u, light.near, light.far, light.angle, light.angle); //??????????????????????????????
    u = glGetUniformLocation(program, "u_light_att");
    if(u!=-1)glUniform2f(u, light.near, light.far); //??????????????????????????????
    //u = glGetUniformLocation(program, "u_brightness_factor");
    //if(u!=-1)glUniform1f(u, 1.5);

    //uniform float u_brightness_factor;
    //uniform float u_colorclip_factor;
    
    /*TEXTURES*/
    //color 0
    u = glGetUniformLocation(program, "color_texture");
    if(u!=-1)glUniform1i(u, 0); //Texture unit 0 is for base images.
    if (_instances[i].mat.texture != nil)
    {
        glActiveTexture(GL_TEXTURE0 + 0);
        glBindTexture(_instances[i].mat.texture.target, _instances[i].mat.texture.name);
        glDisable(GL_TEXTURE_2D);
    }
    //normal 1
    u = glGetUniformLocation(program, "normal_texture");
    if(u!=-1)glUniform1i(u, 1); 
    if (_instances[i].mat.textureNormal != nil)
    {
        glActiveTexture(GL_TEXTURE0 + 1);
        glBindTexture(_instances[i].mat.textureNormal.target, _instances[i].mat.textureNormal.name);
        glDisable(GL_TEXTURE_2D);
    }
    //specular 2
    u = glGetUniformLocation(program, "specular_texture");
    if(u!=-1)glUniform1i(u, 2);
    if (_instances[i].mat.textureSpecular != nil)
    {
        glActiveTexture(GL_TEXTURE0 + 2);
        glBindTexture(_instances[i].mat.textureSpecular.target, _instances[i].mat.textureSpecular.name);
        glDisable(GL_TEXTURE_2D);
    }
    //opacity 3
    u = glGetUniformLocation(program, "opacity_texture");
    if(u!=-1)glUniform1i(u, 3);
    if (_instances[i].mat.textureOpacity != nil)
    {
        glActiveTexture(GL_TEXTURE0 + 3);
        glBindTexture(_instances[i].mat.textureOpacity.target, _instances[i].mat.textureOpacity.name);
        glDisable(GL_TEXTURE_2D);
    }
    //ambient 4
    u = glGetUniformLocation(program, "ambient_texture");
    if(u!=-1)glUniform1i(u, 4);
    if (_instances[i].mat.textureAmbient != nil)
    {
        glActiveTexture(GL_TEXTURE0 + 4);
        glBindTexture(_instances[i].mat.textureAmbient.target, _instances[i].mat.textureAmbient.name);
        glDisable(GL_TEXTURE_2D);
    }
    //emissive 5
    u = glGetUniformLocation(program, "emissive_texture");
    if(u!=-1)glUniform1i(u, 5);
    if (_instances[i].mat.textureEmissive != nil)
    {
        glActiveTexture(GL_TEXTURE0 + 5);
        glBindTexture(_instances[i].mat.textureEmissive.target, _instances[i].mat.textureEmissive.name);
        glDisable(GL_TEXTURE_2D);
    }
    //emissive 6
    u = glGetUniformLocation(program, "detail_texture");
    if(u!=-1)glUniform1i(u, 6);
    if (_instances[i].mat.textureDetail != nil)
    {
        glActiveTexture(GL_TEXTURE0 + 6);
        glBindTexture(_instances[i].mat.textureDetail.target, _instances[i].mat.textureDetail.name);
        glDisable(GL_TEXTURE_2D);
    }
    //shadowmap
    u = glGetUniformLocation(program, "shadowMap");
    if(u!=-1)glUniform1i(u, 7);
    glActiveTexture(GL_TEXTURE0 + 7);
    glBindTexture(GL_TEXTURE_2D, _shadowMapTexture);
    glDisable(GL_TEXTURE_2D);
    
    _shouldSetUniforms = false;
    

    
    /*
    uniform mat3 u_texture_matrix;
    uniform mat4 u_lightMatrix;
    uniform vec4 u_clipping_plane;

    // need flag
    uniform sampler2D displacement_texture;
    uniform float u_displacementmap_factor;
    uniform sampler2D reflectivity_texture;
    uniform vec2 u_reflection_info;
    uniform sampler2D environment_texture;
    uniform samplerCube environment_cubemap;
    uniform sampler2D irradiance_texture;
    uniform samplerCube irradiance_cubemap;
    uniform sampler2D light_texture;
    uniform sampler2D depth_texture;
     
    //shadow
    uniform sampler2D shadowMap;
    uniform vec2 u_shadow_params; // (1.0/(texture_size), bias)
     */
    
}

-(void)setUniforms:(GLint)program index:(int)i proj:(GLKMatrix4)projection withLight:(int)l
{
    Scene *scene = [ResourceManager resources].scene;
    Light *light = [scene getLight:l];
    Light *light2 = [scene getLight:1];
    Camera *cam = [scene getCamera:0];
    
    GLKMatrix4 modelMatrix = _instances[i].model;
    GLKMatrix4 viewMatrix = GLKMatrix4MakeLookAt(cam.position.x, cam.position.y, cam.position.z,
                                                 cam.lookAt.x, cam.lookAt.y, cam.lookAt.z,
                                                 0.0f, 1.0f, 0.0f);

    GLKMatrix4 modelViewMatrix = GLKMatrix4Multiply(viewMatrix, modelMatrix);
    GLKMatrix4 viewProjectionMatrix = GLKMatrix4Multiply(projection, viewMatrix);
    GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4Multiply(viewProjectionMatrix, modelMatrix);
    GLKMatrix4 viewMatrixLight = GLKMatrix4MakeLookAt(light.position.x, light.position.y, light.position.z,
                                                      light.target.x, light.target.y, light.target.z,
                                                      0.0f, 1.0f, 0.0f);
    //GLKMatrix4 projectionMatrixLight = GLKMatrix4MakeOrtho(-100,150,-100,150,light.near,light.far);
    GLKMatrix4 projectionMatrixLight = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(light.angle), 1024/728, 200, 700);
    GLKVector3 lightDirection = GLKVector3Subtract(light.target, light.position);
    GLKVector3 light2Direction = GLKVector3Subtract(light2.target, light2.position);
    GLKMatrix4 modelViewMatrixLight = GLKMatrix4Multiply(viewMatrixLight, modelMatrix);
    GLKMatrix4 depthMVPMatrix = GLKMatrix4Multiply(projectionMatrixLight, modelViewMatrixLight);
    GLKMatrix4 biasMatrix = GLKMatrix4Make(
                                           0.5, 0.0, 0.0, 0.0,
                                           0.0, 0.5, 0.0, 0.0,
                                           0.0, 0.0, 0.5, 0.0,
                                           0.5, 0.5, 0.5, 1.0
                                           );
    GLKMatrix4 depthBiasMVP = GLKMatrix4Multiply(biasMatrix, depthMVPMatrix);
    
    GLint u;
    bool success;
    bool success2;
    
    //matrices
    u = glGetUniformLocation(program, "u_model");
    if(u!=-1)glUniformMatrix4fv(u, 1, GL_FALSE, modelMatrix.m);
    u = glGetUniformLocation(program, "u_v");
    if(u!=-1)glUniformMatrix4fv(u, 1, GL_FALSE, viewMatrix.m);
    u = glGetUniformLocation(program, "u_mv");
    if(u!=-1)glUniformMatrix4fv(u, 1, GL_FALSE, modelViewMatrix.m);
    u = glGetUniformLocation(program, "u_mvp");
    if(u!=-1)glUniformMatrix4fv(u, 1, GL_FALSE, modelViewProjectionMatrix.m);
    u = glGetUniformLocation(program, "u_p");
    if(u!=-1)glUniformMatrix4fv(u, 1, GL_FALSE, projection.m);
    u = glGetUniformLocation(program, "u_viewprojection");
    if(u!=-1)glUniformMatrix4fv(u, 1, GL_FALSE, viewProjectionMatrix.m);
    u = glGetUniformLocation(program, "u_depthBiasMVP");
    if(u!=-1)glUniformMatrix4fv(u, 1, GL_FALSE, depthBiasMVP.m);
    GLKMatrix4 normalModelMatrix4 = GLKMatrix4InvertAndTranspose(modelMatrix, &success);
    if (success) {
        GLKMatrix3 normalModelMatrix3 = GLKMatrix4GetMatrix3(normalModelMatrix4);
        u = glGetUniformLocation(program, "u_normal_model");
        if(u!=-1)glUniformMatrix3fv(u, 1, GL_FALSE, normalModelMatrix3.m);
    }
    GLKMatrix4 normalMatrix4 = GLKMatrix4InvertAndTranspose(modelViewMatrix, &success2);
    if (success2) {
        GLKMatrix3 normalMatrix3 = GLKMatrix4GetMatrix3(normalMatrix4);
        u = glGetUniformLocation(program, "u_normal");
        if(u!=-1)glUniformMatrix3fv(u, 1, GL_FALSE, normalMatrix3.m);
    }
    
    //camera
    u = glGetUniformLocation(program, "u_camera_eye");
    if(u!=-1)glUniform3f(u, cam.position.x, cam.position.y, cam.position.z);
    
    //light
    u = glGetUniformLocation(program, "u_light_pos");
    if(u!=-1)glUniform3f(u, light.position.x, light.position.y, light.position.z);
    u = glGetUniformLocation(program, "u_light_color");
    if(u!=-1)glUniform3f(u, light.diffuseColor.x, light.diffuseColor.y, light.diffuseColor.z);
    u = glGetUniformLocation(program, "u_light_dir");
    if(u!=-1)glUniform3f(u, lightDirection.x, lightDirection.y, lightDirection.z);
    u = glGetUniformLocation(program, "u_light_spot_cutoff");
    if(u!=-1)glUniform1f(u, light.spotCosCutoff);
    u = glGetUniformLocation(program, "u_light_intensity");
    if(u!=-1)glUniform1f(u, light.intensity);
    
    //light2
    u = glGetUniformLocation(program, "u_light2_pos");
    if(u!=-1)glUniform3f(u, light2.position.x, light2.position.y, light2.position.z);
    u = glGetUniformLocation(program, "u_light2_color");
    if(u!=-1)glUniform3f(u, light2.diffuseColor.x, light2.diffuseColor.y, light2.diffuseColor.z);
    u = glGetUniformLocation(program, "u_light2_dir");
    if(u!=-1)glUniform3f(u, light2Direction.x, light2Direction.y, light2Direction.z);
    u = glGetUniformLocation(program, "u_light2_spot_cutoff");
    if(u!=-1)glUniform1f(u, light2.spotCosCutoff);
    u = glGetUniformLocation(program, "u_light2_intensity");
    if(u!=-1)glUniform1f(u, light2.intensity);
    
    //material
    u = glGetUniformLocation(program, "u_material_color");
    if(u!=-1)glUniform4f(u, _instances[i].mat.color.r, _instances[i].mat.color.g, _instances[i].mat.color.b, 1.0f);
    u = glGetUniformLocation(program, "u_ambient_color");
    if(u!=-1)glUniform3f(u, scene.ambient.r * _instances[i].mat.ambient.r,
                         scene.ambient.g * _instances[i].mat.ambient.g,
                         scene.ambient.b * _instances[i].mat.ambient.b);
    u = glGetUniformLocation(program, "u_diffuse_color");
    if(u!=-1)glUniform3f(u, _instances[i].mat.diffuse.x, _instances[i].mat.diffuse.y, _instances[i].mat.diffuse.z);
    u = glGetUniformLocation(program, "u_velvet_info");
    if(u!=-1)glUniform4f(u, _instances[i].mat.velvet.x, _instances[i].mat.velvet.y, _instances[i].mat.velvet.z,
                         40.6);
    u = glGetUniformLocation(program, "u_mat_specular");
    if(u!=-1)glUniform1f(u, _instances[i].mat.specular);
    u = glGetUniformLocation(program, "u_mat_shininess");
    if(u!=-1)glUniform1f(u, _instances[i].mat.shininess);
    u = glGetUniformLocation(program, "color_texture");
    if(u!=-1)glUniform1i(u, 0); //Texture unit 0 is for base images.
    u = glGetUniformLocation(program, "detail_texture");
    if(u!=-1)glUniform1i(u, 1); //Texture unit 2 is for detail images.
    u = glGetUniformLocation(program, "specular_texture");
    if(u!=-1)glUniform1i(u, 2); //Texture unit 6 is for specular.
    u = glGetUniformLocation(program, "normal_texture");
    if(u!=-1)glUniform1i(u, 3); //Texture unit 8 is for normal.
    u = glGetUniformLocation(program, "u_shadowMap");
    if(u!=-1)glUniform1i(u, 4); //Texture unit 4 is for shadow maps.
    
    //texture
    if (_instances[i].mat.texture != nil)
    {
        glActiveTexture(GL_TEXTURE0 + 0);
        glBindTexture(_instances[i].mat.texture.target, _instances[i].mat.texture.name);
        glDisable(GL_TEXTURE_2D); 
    }
    
    if (_instances[i].mat.textureDetail != nil)
    {
        glActiveTexture(GL_TEXTURE0 + 1);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
        glBindTexture(_instances[i].mat.textureDetail.target, _instances[i].mat.textureDetail.name);
        glDisable(GL_TEXTURE_2D); 
    }
    
    if (_instances[i].mat.textureSpecular!= nil)
    {
        glActiveTexture(GL_TEXTURE0 + 2);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
        glBindTexture(_instances[i].mat.textureSpecular.target, _instances[i].mat.textureSpecular.name);
        glDisable(GL_TEXTURE_2D); 
    }
    if (_instances[i].mat.textureNormal!= nil)
    {
        glActiveTexture(GL_TEXTURE0 + 3);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
        glBindTexture(_instances[i].mat.textureNormal.target, _instances[i].mat.textureNormal.name);
        glDisable(GL_TEXTURE_2D); 
    }
    
    //shadowmap
    glActiveTexture(GL_TEXTURE0 + 4);
    glBindTexture(GL_TEXTURE_2D, _shadowMapTexture);
    glDisable(GL_TEXTURE_2D); 
    
    _shouldSetUniforms = false;
}


- (void)renderAllWithProjection:(GLKMatrix4)projection
{
    /*** GENERAL FLAGS ***/
    //glDisable(GL_DITHER);
    //glDisable(GL_CULL_FACE);
    glEnable( GL_DEPTH_TEST );
    
    /*** SHADOW PASS ***/
    [self renderShadowPass];
    
    /*** MAIN PASS ***/
    // START SCREEN BUFFER 
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, 1);
    glViewport(0, 0, [ResourceManager resources].screenWidth, [ResourceManager resources].screenHeight);
    GLKVector3 c = [ResourceManager resources].scene.backgroundColor;
    glClearColor(c.x, c.y, c.z, 1.0f);
    glClear( GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT );

    //DRAW INSTANCES
    for (int i = 0; i < _instances.size(); i++)
    {
        Shader *currShader = _instances[i].mesh.shader;
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
        GLsizei stride = sizeof(GLfloat) * 8; // 3 vert, 3 normal, 2 texture
        glEnableVertexAttribArray( a_vertex );
        glVertexAttribPointer( a_vertex, 3, GL_FLOAT, GL_FALSE, stride, NULL );
        glEnableVertexAttribArray( a_normal );
        glVertexAttribPointer( a_normal, 3, GL_FLOAT, GL_FALSE, stride, BUFFER_OFFSET( stride*3/8 ) );
        glEnableVertexAttribArray( a_coords );
        glVertexAttribPointer( a_coords, 2, GL_FLOAT, GL_FALSE, stride, BUFFER_OFFSET( stride*6/8 ) );

        /****** UNIFORMS ********/
        //if (!_shouldSetUniforms)
           // [self setWebGLUniforms:_program index:i proj:projection];
    


        if (_instances[i].mesh.material.drawLines)
        {
            glUseProgram( currShader.program);
            [self setUniforms:currShader.program index:i proj:projection withLight:0];
            //drawLines
            glDrawElements( GL_LINE_LOOP, _indexBufferSize, GL_UNSIGNED_INT, NULL );
            if (_instances[i].mesh.isAnnotation)
                //draw annotation
                [self drawAnnotationFromInstance:_instances[i] withProjection:projection];


        }
        else
        {
            glUseProgram( currShader.program);
            [self setUniforms:currShader.program index:i proj:projection withLight:0];
            //[self setWebGLUniforms:currShader.program index:i proj:projection];
            glDrawElements( GL_TRIANGLES, _indexBufferSize, GL_UNSIGNED_INT, NULL );
        }
            

        
        //clear shit
        glBindVertexArrayOES( 0 );
    }

    if ([ResourceManager resources].showShadowBuffer)
    {
        //DRAW SCREEN QUAD
        glBindVertexArrayOES( _VAOS );
        glUseProgram( _programScreenSpace );
        glActiveTexture(GL_TEXTURE0 + 0);
        glBindTexture(GL_TEXTURE_2D, _shadowMapTexture);
        glDrawElements( GL_TRIANGLES, sizeof(R2TInds)/sizeof(GLuint), GL_UNSIGNED_INT, NULL );
    }
    
    
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, 0);
    
    
    /* END SCREEN BUFFER */   
     
    
}

- (void)drawAnnotationFromInstance:(RenderInstance)instance withProjection:(GLKMatrix4)p
{
    UILabel *currAnnotation = [[ResourceManager resources].scene.annotationLabels objectAtIndex:instance.mesh.annotationNumber];
    
    
    //get screen position of annotation
    Camera *cam = [[ResourceManager resources].scene getCamera:0];
    GLKMatrix4 v = GLKMatrix4MakeLookAt(cam.position.x, cam.position.y, cam.position.z,
                                        cam.lookAt.x, cam.lookAt.y, cam.lookAt.z,
                                        0.0f, 1.0f, 0.0f);
    GLKMatrix4 mv = GLKMatrix4Multiply(v, instance.model);
    GLKMatrix4 mvp = GLKMatrix4Multiply(p, mv);
    //transform to clipping coordinates
    GLKVector3 cv = instance.mesh.annotationEndPoint;
    GLKVector4 cc = GLKMatrix4MultiplyVector4(mvp, GLKVector4Make(cv.x, cv.y, cv.z, 1.0));
    GLKVector4 ccW = GLKVector4Make(cc.x/cc.w,cc.y/cc.w,cc.z/cc.w,cc.w/cc.w);
    int winX = (int) ((( ccW.x + 1 ) / 2.0) * 1024.0 );
    int winY = (int) ((( 1 - ccW.y ) / 2.0) * 768.0 );
    CGRect frame = currAnnotation.frame;
    frame.origin.x = winX-frame.size.width/2;
    frame.origin.y = winY-2;
    currAnnotation.frame = frame;
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
