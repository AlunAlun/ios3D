//
//  GTI3DViewController.m
//  ios3D
//
//  Created by Alun on 3/26/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#define VERTEX_SHADER @"vertex"
#define FRAGMENT_SHADER @"fragment"
#define BUFFER_OFFSET(i) ((char *)NULL + i)
#define TOUCHSENSITIVITY 200

#import "GTI3DViewController.h"
#import "Node.h"
#import "Scene.h"
#import "SimpleCube.h"

GLfloat CubeVertexData[192] =
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

GLuint CubeIndicesData[36] =
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

typedef struct
{
    char* Name;
    GLint Location;
}Uniform;

typedef struct
{
    int NumberOfUniforms;
    Uniform* Uniform;
    
}UniformInfo;

@interface GTI3DViewController () {
    

    
    GLuint _program;
    Uniform *_uniformArray;
    GLint _uniformArraySize;
   
    GLuint _verticesVBO;
    GLuint _indicesVBO;
    GLuint _VAO;
    
    GLKMatrix4 _projectionMatrix;
    GLKMatrix4 _modelViewMatrix;
    
    int _screenWidth;
    int _screenHeight;
    
    float _cursor;
    BOOL _autoRotate;
    BOOL _isDragging;
    float _xTouchLoc;
    float _yTouchLoc;
    float _lastScale;

}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKTextureInfo *texture;
@property (strong) Node * currentScene;

@end

@implementation GTI3DViewController
@synthesize context = _context;
@synthesize texture = _texture;
@synthesize currentScene = _currentScene;


- (GLuint)compileShader:(NSString*)shaderName withType:(GLenum)shaderType
{
    // Load the shader in memory
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"glsl"];
    NSError *error;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if(!shaderString)
    {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    
    // Create the shader inside openGL
    GLuint shaderHandle = glCreateShader(shaderType);
    
    // Give that shader the source code loaded in memory
    const char *shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = [shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    // Compile the source code
    glCompileShader(shaderHandle);
    
    // Get the error messages in case the compiling has failed
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLint logLength;
        glGetShaderiv(shaderHandle, GL_INFO_LOG_LENGTH, &logLength);
        if(logLength > 0)
        {
            GLchar *log = (GLchar *)malloc(logLength);
            glGetShaderInfoLog(shaderHandle, logLength, &logLength, log);
            NSLog(@"Shader compile log:\n%s", log);
            free(log);
        }
        exit(1);
    }
    
    return shaderHandle;
}

-(void)createProgram
{
    // Compile both shaders
    GLuint vertexShader = [self compileShader:VERTEX_SHADER withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:FRAGMENT_SHADER withType:GL_FRAGMENT_SHADER];
    
    // Create the program in openGL, attach the shaders and link them
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    
    // Get the error message in case the linking has failed
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE)
    {
        GLint logLength;
        glGetProgramiv(programHandle, GL_INFO_LOG_LENGTH, &logLength);
        if(logLength > 0)
        {
            GLchar *log = (GLchar *)malloc(logLength);
            glGetProgramInfoLog(programHandle, logLength, &logLength, log);
            NSLog(@"Program link log:\n%s", log);
            free(log);
        }
        exit(1);
    }
    
    _program = programHandle;
}

-(void)getUniforms
{
    GLint maxUniformLength;
    GLint numberOfUniforms;
    char *uniformName;
    
    // Get the number of uniforms and the max length of their names
    glGetProgramiv(_program, GL_ACTIVE_UNIFORMS, &numberOfUniforms);
    glGetProgramiv(_program, GL_ACTIVE_UNIFORM_MAX_LENGTH, &maxUniformLength);
    
    _uniformArray = malloc(numberOfUniforms * sizeof(Uniform));
    _uniformArraySize = numberOfUniforms;
    
    for(int i = 0; i < numberOfUniforms; i++)
    {
        GLint size;
        GLenum type;
        GLint location;
        // Get the Uniform Info
        uniformName = malloc(sizeof(char) * maxUniformLength);
        glGetActiveUniform(_program, i, maxUniformLength, NULL, &size, &type, uniformName);
        _uniformArray[i].Name = uniformName;
        // Get the uniform location
        location = glGetUniformLocation(_program, uniformName);
        _uniformArray[i].Location = location;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    // Create context
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context) {
        NSLog(@"Failed to create ES context");
        exit(1);
    }
    
    if (![EAGLContext setCurrentContext:self.context])
    {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
    
    // Initialize view
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    
    
    // Change the format of the depth renderbuffer
    // This value is None by default
    view.drawableDepthFormat = GLKViewDrawableDepthFormat16;
    
    // Enable face culling and depth test
    glEnable( GL_DEPTH_TEST );
    glEnable( GL_CULL_FACE  );
    
    // Set up the viewport
    int width = view.bounds.size.width;
    int height = view.bounds.size.height;
    _screenWidth = width;
    _screenHeight = height;
    glViewport(0, 0, width, height);
    
    
    [self createProgram];
    [self getUniforms];
    
    _modelViewMatrix = GLKMatrix4MakeLookAt(2.0f, 2.0f, 4.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f);
    _projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(45.0f), (float)width/(float)height, 0.01f, 100.0f);
      
    
    //gestures/input
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(Tapped:)];
    tap.numberOfTapsRequired = 2;
    [view addGestureRecognizer:tap];
    
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(Scale:)];
	[view addGestureRecognizer:pinchRecognizer];
    
    _isDragging = false;	
    _xTouchLoc = -1.0f;
    _yTouchLoc = -1.0f;
    
    _lastScale = 1.0f;
    
 
    //cargar la unica escena que hemos creado hasta ahora
    self.currentScene = [[Scene alloc] initWithProgram:_program];
    //self.cube = [[SimpleCube alloc] initWithFile:@"SquareTexture" program:_program];
}

// This is the selector/callback for gestures

-(void)Tapped:(UITapGestureRecognizer*)sender
{
    if(sender.state == UIGestureRecognizerStateEnded)
    {
        _autoRotate = !_autoRotate;
        if (_autoRotate) {
            _cursor = 0.05;
        }
        else
        {
            _cursor = 0;
        }
    }
}

-(void)Scale:(UITapGestureRecognizer*)sender
{
    if([(UIPinchGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        
		_lastScale = 1.0;
		return;
	}
    CGFloat scale = 1.0 - (_lastScale - [(UIPinchGestureRecognizer*)sender scale]);

    float newScale = MAX(0.3, MIN(GLKMathDegreesToRadians(45.0f)*scale, 3));
    _projectionMatrix = GLKMatrix4MakePerspective(newScale, (float)_screenWidth/(float)_screenHeight, 0.01f, 100.0f);
     
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint location = [touch locationInView:touch.view];
    _xTouchLoc = location.x;
    _yTouchLoc = location.y;
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint location = [touch locationInView:touch.view];
    _modelViewMatrix = GLKMatrix4RotateY(_modelViewMatrix, (location.x-_xTouchLoc)/TOUCHSENSITIVITY);
    _xTouchLoc = location.x;
    _yTouchLoc = location.y;    	
}


- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    // Clear the screen
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear( GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT );
    
    //parse the scene
    [self.currentScene renderWithMV:_modelViewMatrix P:_projectionMatrix];
    

    
}

- (void)update
{
    //_modelViewMatrix = GLKMatrix4RotateY(_modelViewMatrix, _cursor);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_verticesVBO);
    glDeleteBuffers(1, &_indicesVBO);
    glDeleteVertexArraysOES(1, &_VAO);
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
    
    for (int i = 0; i < _uniformArraySize; i++) {
        free(_uniformArray[i].Name);
    }
    free(_uniformArray);
    
    self.context = nil;
    self.texture = nil;
}

@end
