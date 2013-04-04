//
//  LoadingViewController.m
//  ios3D
//
//  Created by Alun on 4/3/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import "LoadingViewController.h"
#import "Material.h"
#import "WaveFrontObject.h"
#import "ShaderLoader.h"
#import "ResourceManager.h"


@interface LoadingViewController ()
{
    void (^_completionHandler)(int error);
}

@end

@implementation LoadingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

-(void)viewDidAppear:(BOOL)animated
{
	
    [self loadAssetsWithCompletionHandler:^(int result){
        // Prints 10
        if (result ==1)
            [self performSegueWithIdentifier:@"go3D" sender:self];
    }];

}

- (void) loadAssetsWithCompletionHandler:(void(^)(int))handler
{
    // NOTE: copying is very important if you'll call the callback asynchronously,
    // even with garbage collection!
    _completionHandler = [handler copy];
    
    
    //Initialise EAGLContext
    [ResourceManager resources].context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (![EAGLContext setCurrentContext:[ResourceManager resources].context])
    {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
    
    //Init Objects and Materials
    //Compile Shaders
    ShaderLoader *loader = [[ShaderLoader alloc] init];
    GLuint shaderDetailTexture = [loader createProgramWithVertex:@"ShaderDetailTextureVertex" Fragment:@"ShaderDetailTextureFragment"];
    GLuint shaderPhong = [loader createProgramWithVertex:@"ShaderPhongVertex" Fragment:@"ShaderPhongFragment"];
    
    
    //create nodes
    Material *avatarMat = [[Material alloc] initWithProgram:shaderPhong];
    Mesh *avatarMesh = [ResourceManager WaveFrontOBJLoadMesh:@"avatar_girl.obj" withMaterial:avatarMat];
    avatarMesh.name = @"Avatar";
    
    Material *shirtMat = [[Material alloc] initWithTexture:@"dress_top" ofType:@"jpg" andProgram:shaderDetailTexture];
    Mesh *shirtMesh = [ResourceManager WaveFrontOBJLoadMesh:@"tshirt.obj" withMaterial:shirtMat];
    shirtMesh.name = @"Shirt";
    
    Material *skirtMat = [[Material alloc] initWithTexture:@"dress_skirt" ofType:@"jpg" andProgram:shaderDetailTexture];
    [skirtMat loadDetailTexture:@"detail_jeans" ofType:@"png"];
    Mesh *skirtMesh = [ResourceManager WaveFrontOBJLoadMesh:@"skirt.obj" withMaterial:skirtMat];
    skirtMesh.name = @"Skirt";
    
    Material *floorMat = [[Material alloc] initWithProgram:shaderPhong];
    floorMat.ambient = GLKVector4Make(0.8, 0.8, 0.8, 1.0);
    Mesh *floorMesh = [ResourceManager WaveFrontOBJLoadMesh:@"floor.obj" withMaterial:floorMat];
    floorMesh.name = @"Floor";
    
    //Init scene and add objects to graph
    [ResourceManager resources].scene = [[Scene alloc] initWitName:@"Body Scene"];
    [[ResourceManager resources].scene addChild:avatarMesh];
    [[ResourceManager resources].scene addChild:shirtMesh];
    [[ResourceManager resources].scene addChild:skirtMesh];
    [[ResourceManager resources].scene addChild:floorMesh];
    
    // Call completion handler - this performs the segue and loads 3D view
    int result = 1;
    _completionHandler(result);
    
    // Clean up.
    _completionHandler = nil;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
