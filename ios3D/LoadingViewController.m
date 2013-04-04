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
#import "AssetsSingleton.h"


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
    
  /*  UIActivityIndicatorView *_spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [_spinner setCenter:CGPointMake(mainScreenFrame.size.height/3.0f*1.85f, mainScreenFrame.size.width/10.0f*7.55f)];
    [_imageView addSubview:_spinner];
    [_spinner startAnimating];*/
    
    

    
   
    

        
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
    [AssetsSingleton sharedAssets].context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (![EAGLContext setCurrentContext:[AssetsSingleton sharedAssets].context])
    {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
    
    //Init Objects and Materials
    //Compile Shaders
    ShaderLoader *loader = [[ShaderLoader alloc] init];
    GLuint shaderDetailTexture = [loader createProgramWithVertex:@"ShaderDetailTextureVertex" Fragment:@"ShaderDetailTextureFragment"];
    GLuint shaderPhong = [loader createProgramWithVertex:@"ShaderPhongVertex" Fragment:@"ShaderPhongFragment"];
    
    
    NSError* error = nil;
    WaveFrontObject *avatarOBJ = [self addChildOBJ:@"avatar_girl.obj" withProgram:shaderPhong error:&error];
    //if (!avatarOBJ ) return nil;
    avatarOBJ.name = @"Avatar";
    Material *avatarMat = [[Material alloc] init];
    avatarOBJ.materialDefault = avatarMat;
    
    WaveFrontObject *skirtOBJ = [self addChildOBJ:@"skirt.obj"  withProgram:shaderDetailTexture error:&error];
    //if (!skirtOBJ ) return nil;
    skirtOBJ.name = @"Skirt";
    Material *skirtMat = [[Material alloc] initWithTexture:@"dress_skirt" ofType:@"jpg"];
    skirtMat.program = shaderDetailTexture;
    [skirtMat loadDetailTexture:@"detail_jeans" ofType:@"png"];
    skirtOBJ.materialDefault = skirtMat;
    
    WaveFrontObject *shirtOBJ = [self addChildOBJ:@"tshirt.obj"  withProgram:shaderDetailTexture error:&error];
    //if (!shirtOBJ ) return nil;
    shirtOBJ.name = @"Shirt";
    Material *shirtMat = [[Material alloc] initWithTexture:@"dress_top" ofType:@"jpg"];
    shirtOBJ.materialDefault = shirtMat;
    
    WaveFrontObject *floorOBJ = [self addChildOBJ:@"floor.obj"  withProgram:shaderDetailTexture error:&error];
    //if (!floorOBJ ) return nil;
    floorOBJ.name = @"Floor";
    Material *floorMat = [[Material alloc] init];
    floorMat.ambient = GLKVector4Make(0.8, 0.8, 0.8, 1.0);
    [floorMat loadDetailTexture:@"white" ofType:@"png"];
    floorOBJ.materialDefault = floorMat;
    
    //Init scene and add objects to graph
    [AssetsSingleton sharedAssets].scene = [[Scene alloc] initWitName:@"Body Scene"];
    [[AssetsSingleton sharedAssets].scene addChild:avatarOBJ];
    [[AssetsSingleton sharedAssets].scene addChild:shirtOBJ];
    [[AssetsSingleton sharedAssets].scene addChild:skirtOBJ];
    [[AssetsSingleton sharedAssets].scene addChild:floorOBJ];
    
    
    
    
    int result = 1;
    
    // Call completion handler.
    _completionHandler(result);
    
    // Clean up.
    _completionHandler = nil;
}

-(WaveFrontObject*)addChildOBJ:(NSString*)fileName withProgram:(GLuint)program error:(NSError**)error
{
    NSString *baseName = [[fileName componentsSeparatedByString:@"."] objectAtIndex:0];
    NSString *fileType = [[fileName componentsSeparatedByString:@"."] objectAtIndex:1];
    NSString *path = [[NSBundle mainBundle] pathForResource:baseName ofType:fileType];
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    if (path == nil)
    {
        [details setValue:[NSString stringWithFormat:@"Couldn't find file %@",fileName] forKey:NSLocalizedDescriptionKey] ;
        *error = [NSError errorWithDomain:@"OBJ" code:001 userInfo:details];
        return nil;
    }
    
    WaveFrontObject *theObject = [[WaveFrontObject alloc] initWithPath:path program:program error:error];
    
    if (!theObject) {
        // inspect error
        //NSLog(@"%@", [errorr localizedDescription]);
        return false;
    }
    else 
        return theObject;
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
