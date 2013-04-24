//
//  Renderer.m
//  ios3D
//
//  Created by Alun on 4/6/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import "Renderer.h"
#import "ResourceManager.h"




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
