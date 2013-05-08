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
#import "Camera.h"
#import "Light.h"


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
    
    //Straight phong
    NSArray *flags = [[NSArray alloc] initWithObjects:
                      //@"USE_HARD_SHADOWS",
                      @"USE_SOFT_SHADOWS",
                      //@"USE_SPOT_LIGHT",
                      nil];
    GLuint shaderPhong  = [loader createProgramWithVertex:@"ShaderUberVertex" Fragment:@"ShaderUberFragment" Flags:flags];
    
    
    //Diffuse Texture
    flags = [[NSArray alloc] initWithObjects:
             @"USE_DIFFUSE_TEXTURE",
             @"USE_SOFT_SHADOWS",
             //@"USE_HARD_SHADOWS",
             //@"USE_SPOT_LIGHT",
             nil];
    GLuint shaderDiffuseTexture = [loader createProgramWithVertex:@"ShaderUberVertex" Fragment:@"ShaderUberFragment" Flags:flags];
    
    //Diffuse Detail Texture
    flags = [[NSArray alloc] initWithObjects:
             @"USE_DIFFUSE_TEXTURE",
             //@"USE_HARD_SHADOWS",
             @"USE_SOFT_SHADOWS",
             //@"USE_SPOT_LIGHT",
             @"USE_DETAIL_TEXTURE",
             nil];
    GLuint shaderDetailTexture = [loader createProgramWithVertex:@"ShaderUberVertex" Fragment:@"ShaderUberFragment" Flags:flags];
    
    
    //create nodes
    
    Camera *cam = [[Camera alloc] init];
    cam.name = @"Main Camera";
    cam.position = GLKVector3Make(0.12079625762254009, 144.7904492272644, 250.54446586249261);
    cam.lookAt = GLKVector3Make(0.12079625762254009, 93.0266405, 1.359303318242133);
    cam.clipNear = 1.0;
    cam.clipFar = 1000.0;
    cam.fov = 45.0;
    
    Light *light = [[Light alloc] init];
    light.name = @"Light";
    light.position = GLKVector3Make(338, 455.5999999999999, 226); // nice light
    //light.direction = GLKVector3Make(1.0,-1.6,-0.8);
    //light.position = GLKVector3Make(0.0, 500.0, 0.0);
    //light.target = GLKVector3Make(0.0, 0.0, 0.0);
    //light.direction = GLKVector3Make(0.0,-1.0,0.0);
    light.near = 367;
    light.far = 670;
    light.spotCosCutoff = 0.93;
    light.intensity = 1.0;
    light.diffuseColor = GLKVector3Make(1.0, 1.0, 1.0);
    light.ambientColor = GLKVector3Make(1.0, 1.0, 1.0);
    light.specularColor = GLKVector3Make(1.0, 1.0, 1.0);
    
    
    Material *avatarMat = [[Material alloc] initWithProgram:shaderPhong];
    avatarMat.color = GLKVector4Make(0.0, 0.0, 0.0, 1.0);
    avatarMat.diffuse = GLKVector4Make(0.19, 0.15, 0.15, 1.0);
    avatarMat.ambient = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
    avatarMat.specular = 0.5;
    avatarMat.shininess = 1.0;
    Mesh *avatarMesh = [ResourceManager WaveFrontOBJLoadMesh:@"avatar_girl.obj" withMaterial:avatarMat];
    avatarMesh.name = @"Avatar";
    avatarMesh.rotation = GLKQuaternionMake(0, -0.46931692957878113, 0, -0.8830292820930481);
    //avatarMesh.rotationZ = 90.0;
     
     
     
     
    Material *shirtMat = [[Material alloc] initWithTexture:@"dress_top" ofType:@"jpg" andProgram:shaderDiffuseTexture];
    Mesh *shirtMesh = [ResourceManager WaveFrontOBJLoadMesh:@"tshirt.obj" withMaterial:shirtMat];
    shirtMesh.name = @"Shirt";
    shirtMat.ambient = GLKVector4Make(0.65, 0.65, 0.65, 1.0);
    shirtMat.diffuse = GLKVector4Make(0.7, 0.7, 0.7, 0.7);
    shirtMat.specular = 0.05;
    shirtMat.shininess = 4.0;

    
   
    Material *skirtMat = [[Material alloc] initWithTexture:@"dress_skirt" ofType:@"jpg" andProgram:shaderDetailTexture];
    [skirtMat loadDetailTexture:@"detail_jeans" ofType:@"png"];
    Mesh *skirtMesh = [ResourceManager WaveFrontOBJLoadMesh:@"skirt.obj" withMaterial:skirtMat];
    skirtMesh.name = @"Skirt";
    skirtMat.ambient = GLKVector4Make(0.65, 0.65, 0.65, 1.0);
    skirtMat.diffuse = GLKVector4Make(0.7, 0.7, 0.7, 0.7);
    skirtMat.specular = 0.05;
    skirtMat.shininess = 4.0;
    
    
    Material *floorMat = [[Material alloc] initWithProgram:shaderPhong];
    floorMat.diffuse = GLKVector4Make(0.65, 0.65, 0.65, 1.0);
    //floorMat.ambient = GLKVector4Make(0.1, 0.1, 0.1, 1.0);
    floorMat.ambient = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
    floorMat.specular = 0.1;
    floorMat.shininess = 10.0;
    Mesh *floorMesh = [ResourceManager WaveFrontOBJLoadMesh:@"floor.obj" withMaterial:floorMat];
    floorMesh.scale = 10.0f;
    floorMesh.name = @"Floor";
     
    
    //Init scene and add objects to graph
    [ResourceManager resources].scene = [[Scene alloc] initWitName:@"Body Scene"];
    [ResourceManager resources].scene.backgroundColor = GLKVector3Make(0.89, 0.89, 0.87);
    [[ResourceManager resources].scene addChild:cam];
    [[ResourceManager resources].scene addChild:light];
    [[ResourceManager resources].scene addChild:floorMesh];    
    [[ResourceManager resources].scene addChild:avatarMesh];
    //[[ResourceManager resources].scene addChild:shirtMesh];
    [avatarMesh addChild:shirtMesh];
    [avatarMesh addChild:skirtMesh];

     
    
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
