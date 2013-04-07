//
//  SimpleCube.m
//  ios3D
//
//  Created by Alun on 3/27/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import "SimpleCube.h"
#define BUFFER_OFFSET(i) ((char *)NULL + i)

/*
GLfloat CcubeVertexData[64] =
{
    1.169504f, -1.209790f, -1.182525f, 0.000000f, 0.000000f, 1.000000f, 0.000000f, 1.000000f,
    1.169504f, -1.209790f, 0.817475f, 0.000000f, 0.000000f, 1.000000f, 0.000000f, 1.000000f,
    -0.830496f, -1.209790f, 0.817475f, 0.000000f, 0.000000f, 1.000000f, 0.000000f, 1.000000f,
    -0.830496f, -1.209790f, -1.182526f, 0.000000f, 0.000000f, 1.000000f, 0.000000f, 1.000000f,
    1.169504f, 0.790210f, -1.182525f, 0.000000f, 0.000000f, 1.000000f, 0.000000f, 1.000000f,
    1.169503f, 0.790210f, 0.817475f, 0.000000f, 0.000000f, 1.000000f, 0.000000f, 1.000000f,
    -0.830496f, 0.790210f, 0.817474f, 0.000000f, 0.000000f, 1.000000f, 0.000000f, 1.000000f,
    -0.830496f, 0.790210f, -1.182525f, 0.000000f, 0.000000f, 1.000000f, 0.000000f, 1.000000f
};
*/

GLfloat CcubeVertexData[192] =
{
    // right 0
    0.5f, -0.5f, -0.5f,    1.0f, 0.0f, 0.0f,   1.0f, 0.0f,
    0.5f,  0.5f, -0.5f,    1.0f, 0.0f, 0.0f,   1.0f, 1.0f,
    0.5f,  0.5f,  0.5f,    1.0f, 0.0f, 0.0f,   0.0f, 1.0f,
    0.5f, -0.5f,  0.5f,    1.0f, 0.0f, 0.0f,   0.0f, 0.0f,
    
    // top 4
    0.5f,  0.5f, -0.5f,    0.0f, 1.0f, 0.0f,   1.0f, 1.0f,
    -0.5f,  0.5f, -0.5f,    0.0f, 1.0f, 0.0f,   0.0f, 1.0f,
    -0.5f,  0.5f,  0.5f,    0.0f, 1.0f, 0.0f,   0.0f, 0.0f,
    0.5f,  0.5f,  0.5f,    0.0f, 1.0f, 0.0f,   1.0f, 0.0f,
    
    // left 8
    -0.5f,  0.5f, -0.5f,    -1.0f, 0.0f, 0.0f,  0.0f, 1.0f,
    -0.5f, -0.5f, -0.5f,    -1.0f, 0.0f, 0.0f,  0.0f, 0.0f,
    -0.5f, -0.5f,  0.5f,    -1.0f, 0.0f, 0.0f,  1.0f, 0.0f,
    -0.5f,  0.5f,  0.5f,    -1.0f, 0.0f, 0.0f,  1.0f, 1.0f,
    
    // bottom 12
    -0.5f, -0.5f, -0.5f,    0.0f, -1.0f, 0.0f,  0.0f, 0.0f,
    0.5f, -0.5f, -0.5f,    0.0f, -1.0f, 0.0f,  0.0f, 0.0f,
    0.5f, -0.5f,  0.5f,    0.0f, -1.0f, 0.0f,  0.0f, 0.0f,
    -0.5f, -0.5f,  0.5f,    0.0f, -1.0f, 0.0f,  0.0f, 0.0f,
    
    // front 16
    0.5f,  0.5f,  0.5f,    0.0f, 0.0f, 1.0f,   1.0f, 1.0f,
    -0.5f,  0.5f,  0.5f,    0.0f, 0.0f, 1.0f,   0.0f, 1.0f,
    -0.5f, -0.5f,  0.5f,    0.0f, 0.0f, 1.0f,   0.0f, 0.0f,
    0.5f, -0.5f,  0.5f,    0.0f, 0.0f, 1.0f,   1.0f, 0.0f,
    
    // back 20
    0.5f,  0.5f, -0.5f,    0.0f, 0.0f, -1.0f,  0.0f, 1.0f,
    0.5f, -0.5f, -0.5f,    0.0f, 0.0f, -1.0f,  0.0f, 0.0f,
    -0.5f, -0.5f, -0.5f,    0.0f, 0.0f, -1.0f,  1.0f, 0.0f,
    -0.5f,  0.5f, -0.5f,    0.0f, 0.0f, -1.0f,  1.0f, 1.0f,
};

/*
GLuint CcubeIndicesData[36] =
{
    4,  0,  7,
    0,  3,  7,
    2,  6,  7,
    2,  7,  3,
    1,  5,  2,
    5,  6,  2,
    0,  4,  1,
    4,  5,  1,
    4,  7,  6,
    4,  6,  5,
    0,  1,  2, 
    0,  2,  3
};
*/

GLuint CcubeIndicesData[36] =
{
    // right
    0, 1, 2,        2, 3, 0,
    
    // top
    4, 5, 6,        6, 7, 4,
    
    // left
    8, 9, 10,       10, 11, 8,
    
    // bottom
    12, 13, 14,     14, 15, 12,
    
    // front
    16, 17, 18,     18, 19, 16,
    
    // back
    20, 21, 22,     22, 23, 20
};

 
@interface SimpleCube()
{
    GLuint _program;
    GLuint _verticesVBO;
    GLuint _indicesVBO;
    GLuint _VAO;
}

@property (strong) GLKTextureInfo * texture;

@end

@implementation SimpleCube
@synthesize texture = _textureInfo;

/*
- (id)initWithFile:(NSString *)fileName program:(GLuint)program
{
    if ((self = [super init])) {
        _program = program;
        
        //load texture
        NSError *error;
        NSString* filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"pvr"];
        self.texture = [GLKTextureLoader textureWithContentsOfFile:filePath options:nil error:&error];
        if(error) {
            NSLog(@"Error loading texture from image: %@", error);
            exit(1);
        }
        
        [self setupBuffers];

    }
    return self;
}
 */

- (id)initWithProgram:(GLuint)program
{
    if ((self = [super init])) {
        _program = program;
        self.material = [[Material alloc] init];
        
        [self setupBuffers];
        
    }
    return self;
}

-(void)setupBuffers
{
    // Make the vertex buffer
    glGenBuffers( 1, &_verticesVBO );
    glBindBuffer( GL_ARRAY_BUFFER, _verticesVBO );
    glBufferData( GL_ARRAY_BUFFER, sizeof(CcubeVertexData), CcubeVertexData, GL_STATIC_DRAW );
    glBindBuffer( GL_ARRAY_BUFFER, 0 );
    
    // Make the indices buffer
    glGenBuffers( 1, &_indicesVBO );
    glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, _indicesVBO );
    glBufferData( GL_ELEMENT_ARRAY_BUFFER, sizeof(CcubeIndicesData), CcubeIndicesData, GL_STATIC_DRAW );
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
    
    attribute = glGetAttribLocation(_program, "VertexTexCoord0");
    glEnableVertexAttribArray( attribute );
    glVertexAttribPointer( attribute, 2, GL_FLOAT, GL_FALSE, stride, BUFFER_OFFSET( stride*6/8 ) );
    
    glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, _indicesVBO );
    
    glBindVertexArrayOES( 0 );
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
    
    GLint lightIntensityUniform = glGetUniformLocation(_program, "LightIntensity");
    glUniform1f(lightIntensityUniform, 1.3);
    
    GLint diffuseUniform = glGetUniformLocation(_program, "matDiffuse");
    glUniform4f(diffuseUniform, self.material.diffuse.r, self.material.diffuse.g, self.material.diffuse.b, 1.0f);
    
    GLint ambientUniform = glGetUniformLocation(_program, "matAmbient");
    glUniform4f(ambientUniform, self.material.ambient.r, self.material.ambient.g, self.material.ambient.b, 1.0f);
    
    GLint specularUniform = glGetUniformLocation(_program, "matSpecular");
    glUniform1f(specularUniform, self.material.specular);
    
    GLint shininessUniform = glGetUniformLocation(_program, "matShininess");
    glUniform1f(shininessUniform, self.material.shininess);
    
    GLint baseImageLoc = glGetUniformLocation(_program, "TextureSampler");
    glUniform1i(baseImageLoc, 0); //Texture unit 0 is for base images.
    
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, 1.0f);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    //texture
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(self.material.texture.target, self.material.texture.name);
    
    // Draw!
    glDrawElements( GL_TRIANGLES, sizeof(CcubeIndicesData)/sizeof(GLuint), GL_UNSIGNED_INT, NULL );

}

@end
