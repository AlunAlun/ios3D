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
#import "ResourceManager.h"
#import "ShaderLoader.h"
#import "Camera.h"
#import "ResourceManager.h"

@interface GTI3DViewController () {
    
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
@property (strong) Scene * currentScene;

@end

@implementation GTI3DViewController
@synthesize context = _context;
@synthesize texture = _texture;
@synthesize currentScene = _currentScene;
@synthesize controlPanel = _controlPanel;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //get current scene (called in render method)
    self.currentScene = [ResourceManager resources].scene;
    if (!self.currentScene) {NSLog(@"Scene not loaded properly");exit(1);}
   
    //get camera
    Camera *cam = [self.currentScene getCamera:0];
    if (!cam) {NSLog(@"No Camera defined in scene");exit(1);}
    
    //load context from Resource Manager
    self.context = [ResourceManager resources].context;
    if (!self.context) {NSLog(@"Failed to create ES context");exit(1);}
      
    // Initialize view
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    
    
    // Change the format of the depth renderbuffer
    // This value is None by default
    view.drawableDepthFormat = GLKViewDrawableDepthFormat16;
    //view.drawableMultisample = GLKViewDrawableMultisample4X;
    
    // Enable face culling and depth test
    glEnable( GL_DEPTH_TEST );
    //glEnable( GL_CULL_FACE  );
    //glCullFace(GL_BACK);



    
    
    // Set up the viewport
    int width = view.bounds.size.width;
    int height = view.bounds.size.height;
    _screenWidth = width;
    _screenHeight = height;
    glViewport(0, 0, width, height);
    
    //setup matrices
    GLKMatrix4 viewMatrix = GLKMatrix4MakeLookAt(cam.position.x, cam.position.y, cam.position.z,
                                            cam.lookAt.x, cam.lookAt.y, cam.lookAt.z,
                                            0.0f, 1.0f, 0.0f);
    
    _modelViewMatrix = GLKMatrix4Multiply(viewMatrix, [ResourceManager resources].sceneModelMatrix);
    _projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(cam.aspectRatio),
                                                  (float)width/(float)height,
                                                  cam.clipNear, cam.clipFar);
        
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
    _isPanel = NO;

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

    //translated
    GLKMatrix4 movedModel = GLKMatrix4Translate([ResourceManager resources].sceneModelMatrix, 0, (_yTouchLoc-location.y)*PANTOUCHSENSITIVITY, 0);
    
    //add rotation scene model
    GLKMatrix4 rotatedSceneModel = GLKMatrix4RotateY(movedModel, (location.x-_xTouchLoc)*ROTATETOUCHSENSITIVITY);

    //set
    [ResourceManager resources].sceneModelMatrix = rotatedSceneModel;
    
    //get view matrix - needs to be optimized!
    self.currentScene = [ResourceManager resources].scene;
    Camera *cam = [self.currentScene getCamera:0];
    GLKMatrix4 viewMatrix = GLKMatrix4MakeLookAt(cam.position.x, cam.position.y, cam.position.z,
                                                 cam.lookAt.x, cam.lookAt.y, cam.lookAt.z,
                                                 0.0f, 1.0f, 0.0f);
    
    //multiply for final matrix to be passed to renderer
    _modelViewMatrix = GLKMatrix4Multiply(viewMatrix, [ResourceManager resources].sceneModelMatrix);
    
    
    _xTouchLoc = location.x;
    _yTouchLoc = location.y;    	
}


- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    // Clear the screen
    glClearColor(0.9f, 0.9f, 0.9f, 1.0f);
    glClear( GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT );

    
    //time set
    CFTimeInterval previousTimestamp = CFAbsoluteTimeGetCurrent();
    
    //parse the scene
    [self.currentScene renderWithMV:_modelViewMatrix P:_projectionMatrix];
    
    //time measure
    CFTimeInterval frameDuration = CFAbsoluteTimeGetCurrent() - previousTimestamp;
    Node *f = [[ResourceManager resources].scene getChild:@"Floor"];
    
    self.performanceLabel.text = [NSString stringWithFormat:@" %f", f.position.y];
    /*
    [NSString stringWithFormat:@"Frame duration: %f ms. Triangles: %i",
                                  frameDuration * 1000.0,
                                  [ResourceManager resources].totalTris];
     */
    
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
    
    /*
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
     */

}

@end
