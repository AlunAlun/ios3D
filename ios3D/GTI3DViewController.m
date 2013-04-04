//
//  GTI3DViewController.m
//  ios3D
//
//  Created by Alun on 3/26/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#define BUFFER_OFFSET(i) ((char *)NULL + i)
#define ROTATETOUCHSENSITIVITY 0.005
#define PANTOUCHSENSITIVITY 0.1
#define ZOOMTOUCHSENSITIVITY 0.5

#import "GTI3DViewController.h"
#import "Node.h"
#import "Scene.h"
#import "SimpleCube.h"
#import "ControlPanel.h"
#import "AssetsSingleton.h"
#import "ShaderLoader.h"


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
    

    
    GLuint _shaderDetailTexture;
    GLuint _shaderTexture;
    GLuint _shaderPhong;

   
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
    
    BOOL _isPanel;

}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKTextureInfo *texture;
@property (strong) Node * currentScene;

@end

@implementation GTI3DViewController
@synthesize context = _context;
@synthesize texture = _texture;
@synthesize currentScene = _currentScene;
@synthesize controlPanel = _controlPanel;


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

-(GLuint)createProgramWithVertex:(NSString*)vertex Fragment:(NSString*)fragment
{
    // Compile both shaders
    GLuint vertexShader = [self compileShader:vertex withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:fragment withType:GL_FRAGMENT_SHADER];
    
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
    
    //_program = programHandle;
    return programHandle;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
   
	// Do any additional setup after loading the view, typically from a nib.
    // Create context
    //self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    self.context = [AssetsSingleton sharedAssets].context;
    if (!self.context) {
        NSLog(@"Failed to create ES context");
        exit(1);
    }
    

    
    // Initialize view
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    
    
    // Change the format of the depth renderbuffer
    // This value is None by default
    view.drawableDepthFormat = GLKViewDrawableDepthFormat16;
    view.drawableMultisample = GLKViewDrawableMultisample4X;
    
    // Enable face culling and depth test
    glEnable( GL_DEPTH_TEST );
    //glEnable( GL_CULL_FACE  );
    
    // Set up the viewport
    int width = view.bounds.size.width;
    int height = view.bounds.size.height;
    _screenWidth = width;
    _screenHeight = height;
    glViewport(0, 0, width, height);
    
    //compile shaders
    //ShaderLoader *loader = [[ShaderLoader alloc] init];
    //_shaderDetailTexture = [loader createProgramWithVertex:@"ShaderDetailTextureVertex" Fragment:@"ShaderDetailTextureFragment"];
    //_shaderPhong = [loader createProgramWithVertex:@"ShaderPhongVertex" Fragment:@"ShaderPhongFragment"];
    
    

    //setup matrices
    _modelViewMatrix = GLKMatrix4MakeLookAt(0.0f, 150.0f, 200.0f, 0.0f, 100.0f, 0.0f, 0.0f, 1.0f, 0.0f);
    _projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(45.0f), (float)width/(float)height, 100.0f, 1000.0f);
    


    
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
    NSError* error = nil;
    //self.currentScene = [[Scene alloc] initWithProgram:_shaderDetailTexture error:&error];

    self.currentScene = [AssetsSingleton sharedAssets].scene;
    
    if (!self.currentScene)
    {
        NSLog(@"%@", [error localizedDescription]);

        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle: @"D'oh!"
                              message: [error localizedDescription]
                              delegate: nil
                              cancelButtonTitle:@"Scene not initialised"
                              otherButtonTitles:nil];
        [alert show];

    }
    else{
        //add scene to singleton
        [AssetsSingleton sharedAssets].scene = (Scene*)self.currentScene;
        
        // panel stuff
        _isPanel = NO;

        
    }




}

// This is the selector/callback for gestures


-(void)ShowHidePanel
{

    if (!_isPanel)
    {
        [self.controlPanel drawTree];
        _isPanel = YES;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        [UIView setAnimationDuration:0.3];
        self.controlPanel.frame = CGRectMake(self.controlPanel.frame.origin.x-300,0,self.controlPanel.frame.size.width, self.controlPanel.frame.size.height);
        [UIView commitAnimations];
    }
    else{
        _isPanel = NO;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        [UIView setAnimationDuration:0.3];
        self.controlPanel.frame = CGRectMake(self.controlPanel.frame.origin.x+300,0,self.controlPanel.frame.size.width, self.controlPanel.frame.size.height);
        [UIView commitAnimations];
    }
}

-(void)Tapped:(UITapGestureRecognizer*)sender
{
    if ([(UITapGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded)
    {
        [self ShowHidePanel];
    }
}

-(void)Scale:(UITapGestureRecognizer*)sender
{
    

    CGFloat scale = _lastScale + (1.0 - [(UIPinchGestureRecognizer*)sender scale])*ZOOMTOUCHSENSITIVITY;

    float newScale = MAX(0.1, MIN(scale, 3));
    _projectionMatrix = GLKMatrix4MakePerspective(newScale*GLKMathDegreesToRadians(45.0f), (float)_screenWidth/(float)_screenHeight, 100.0f, 1000.0f);
    if([(UIPinchGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
		_lastScale = newScale;
		return;
	}
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
    //_modelViewMatrix = GLKMatrix4Translate(_modelViewMatrix, 0, (location.y-_yTouchLoc)*PANTOUCHSENSITIVITY, 0);
    GLKMatrix4 tm = GLKMatrix4Translate(GLKMatrix4Identity, 0, (_yTouchLoc-location.y)*PANTOUCHSENSITIVITY, 0);
    
    _modelViewMatrix = GLKMatrix4Multiply(tm, GLKMatrix4RotateY(_modelViewMatrix, (location.x-_xTouchLoc)*ROTATETOUCHSENSITIVITY));
    _xTouchLoc = location.x;
    _yTouchLoc = location.y;    	
}


- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    // Clear the screen
    glClearColor(0.9f, 0.9f, 0.9f, 1.0f);
    glClear( GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT );
    
    
    CFTimeInterval previousTimestamp = CFAbsoluteTimeGetCurrent();
    


    //parse the scene
    [self.currentScene renderWithMV:_modelViewMatrix P:_projectionMatrix];
        
    CFTimeInterval frameDuration = CFAbsoluteTimeGetCurrent() - previousTimestamp;
    self.performanceLabel.text = [NSString stringWithFormat:@"Frame duration: %f ms. Triangles: %i",
                                  frameDuration * 1000.0,
                                  [AssetsSingleton sharedAssets].totalTris];
    
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
    
    if (_shaderDetailTexture) {
        glDeleteProgram(_shaderDetailTexture);
        _shaderDetailTexture = 0;
    }
    
    if (_shaderTexture) {
        glDeleteProgram(_shaderTexture);
        _shaderTexture = 0;
    }
    
    if (_shaderPhong) {
        glDeleteProgram(_shaderPhong);
        _shaderPhong = 0;
    }
    

}

@end
