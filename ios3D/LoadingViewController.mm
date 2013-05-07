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
                      //@"USE_SPOT_LIGHT",
                      nil];
    GLuint shaderPhong  = [loader createProgramWithVertex:@"ShaderUberVertex" Fragment:@"ShaderUberFragment" Flags:flags];
    
    
    //Diffuse Texture
    flags = [[NSArray alloc] initWithObjects:
             @"USE_DIFFUSE_TEXTURE",
             //@"USE_SPOT_LIGHT",
             nil];
    GLuint shaderDiffuseTexture = [loader createProgramWithVertex:@"ShaderUberVertex" Fragment:@"ShaderUberFragment" Flags:flags];
    
    //Diffuse Detail Texture
    flags = [[NSArray alloc] initWithObjects:
             @"USE_DIFFUSE_TEXTURE",
             //@"USE_SPOT_LIGHT",
             @"USE_DETAIL_TEXTURE",
             nil];
    GLuint shaderDetailTexture = [loader createProgramWithVertex:@"ShaderUberVertex" Fragment:@"ShaderUberFragment" Flags:flags];
    
    
    //create nodes
    
    Camera *cam = [[Camera alloc] init];
    cam.name = @"Main Camera";
    cam.position = GLKVector3Make(0.0, 150.0, 250.0f);
    cam.lookAt = GLKVector3Make(0.0, 100.0, 0.0);
    cam.clipNear = 5.0;
    cam.clipFar = 1000.0;
    cam.aspectRatio = 45.0;
    
    Light *light = [[Light alloc] init];
    light.name = @"Light";
    light.position = GLKVector3Make(-300.0, 500.0, 150.0); // nice light
    light.direction = GLKVector3Make(1.0,-1.6,-0.8);
    //light.position = GLKVector3Make(0.0, 500.0, 0.0);
    //light.direction = GLKVector3Make(0.0,-1.0,0.0);
    light.spotCosCutoff = 0.93;
    light.intensity = 1.0;
    light.diffuseColor = GLKVector3Make(1.0, 1.0, 1.0);
    light.ambientColor = GLKVector3Make(1.0, 1.0, 1.0);
    light.specularColor = GLKVector3Make(1.0, 1.0, 1.0);
    
    
    Material *avatarMat = [[Material alloc] initWithProgram:shaderPhong];
    avatarMat.diffuse = GLKVector4Make(0.6, 0.6, 0.6, 1.0);
    avatarMat.ambient = GLKVector4Make(0.1, 0.1, 0.1, 1.0);
    avatarMat.specular = 1.0;
    avatarMat.shininess = 50.0;
    Mesh *avatarMesh = [ResourceManager WaveFrontOBJLoadMesh:@"avatar_girl.obj" withMaterial:avatarMat];
    avatarMesh.name = @"Avatar";
    //avatarMesh.rotationZ = 90.0;
     
     
     
     
    Material *shirtMat = [[Material alloc] initWithTexture:@"dress_top" ofType:@"jpg" andProgram:shaderDiffuseTexture];
    Mesh *shirtMesh = [ResourceManager WaveFrontOBJLoadMesh:@"tshirt.obj" withMaterial:shirtMat];
    shirtMesh.name = @"Shirt";
    //shirtMesh.position = GLKVector3Make(-50.0, 0.0, 50.0);
    
   
    Material *skirtMat = [[Material alloc] initWithTexture:@"dress_skirt" ofType:@"jpg" andProgram:shaderDetailTexture];
    [skirtMat loadDetailTexture:@"detail_jeans" ofType:@"png"];
    Mesh *skirtMesh = [ResourceManager WaveFrontOBJLoadMesh:@"skirt.obj" withMaterial:skirtMat];
    skirtMesh.name = @"Skirt";
     
    
    Material *floorMat = [[Material alloc] initWithProgram:shaderPhong];
    floorMat.diffuse = GLKVector4Make(0.6, 0.6, 0.6, 1.0);
    floorMat.ambient = GLKVector4Make(0.3, 0.3, 0.3, 1.0);
    floorMat.specular = 0.0;
    Mesh *floorMesh = [ResourceManager WaveFrontOBJLoadMesh:@"floor.obj" withMaterial:floorMat];
    floorMesh.scale = 10.0f;
    floorMesh.rotationX = 0.0;
    floorMesh.name = @"Floor";
     
    
    //Init scene and add objects to graph
    [ResourceManager resources].scene = [[Scene alloc] initWitName:@"Body Scene"];
    [[ResourceManager resources].scene addChild:cam];
    [[ResourceManager resources].scene addChild:light];
    [[ResourceManager resources].scene addChild:shirtMesh];
    
    [[ResourceManager resources].scene addChild:avatarMesh];
    //[avatarMesh addChild:shirtMesh];
    [avatarMesh addChild:skirtMesh];
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
