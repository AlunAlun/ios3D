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
#import "Shader.h"
#import "ResourceManager.h"
#import "Camera.h"
#import "Light.h"


#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) 

@interface LoadingViewController ()
{
    void (^_completionHandler)(int error);
    int _currentDownloadIndex;
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
	
    //Initialise EAGLContext
    [ResourceManager resources].context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (![EAGLContext setCurrentContext:[ResourceManager resources].context])
    {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
    
    _currentDownloadIndex = 0;
    //NSURL *jsonURL = [NSURL URLWithString:@"http://www.tamats.com/apps/webglstudio3/data/scenes/Lee.json"];
    
    dispatch_async(kBgQueue, ^{
        //NSData* data = [NSData dataWithContentsOfURL:jsonURL];
        NSString *path = [[NSBundle mainBundle] pathForResource:@"lee.json" ofType:@""];
        //NSString *path = [[NSBundle mainBundle] pathForResource:@"guitarAnnoted.json" ofType:@""];
        NSLog(@"%@", path);
        NSData *data = [NSData dataWithContentsOfFile:path];
        if (data == nil)
        {
            NSLog(@"No internet connection");
            exit(0);
        }
        [self performSelectorOnMainThread:@selector(downloadAssets:)
                               withObject:data waitUntilDone:YES];
    });
    
    
    
    /*
    [self loadJSONWithCompletionHandler:^(int result){
        // Prints 10
        if (result ==1)
            [self performSegueWithIdentifier:@"go3D" sender:self];
    }];
    */
    /*
    [self loadAssetsWithCompletionHandler:^(int result){
        if (result ==1)
            [self performSegueWithIdentifier:@"go3D" sender:self];
    }];
     */
     
}

- (void)downloadAssets:(NSData *)responseData {
    //parse out the json data
    NSError* error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:responseData
                          
                          options:kNilOptions
                          error:&error];
    
    //hard code server path - this should come from the JSON
    self.serverAssetPath = @"http://tamats.com/apps/webglstudio3/server/resources/";
    //add final dash if not present
    if (![self.serverAssetPath hasSuffix:@"/"])
        self.serverAssetPath = [self.serverAssetPath stringByAppendingString:@"/"];

    //init list to download
    NSMutableArray *listToDownload = [[NSMutableArray alloc] init];
    
    //create scene
    self.jsonScene = [[JSONScene alloc] init];
    self.jsonScene.cameras = [[NSMutableArray alloc] init];
    self.jsonScene.lights = [[NSMutableArray alloc] init];
    self.jsonScene.nodes = [[NSMutableArray alloc] init];
    [self.jsonScene loadScene:json];
    
    
    
    //light and camera
    NSArray* coreComponents = [json objectForKey:@"components"];
    for (NSArray *comp in coreComponents)
    {
        NSString *componentName = [comp objectAtIndex:0];
        if ([componentName isEqualToString:@"Light"])
        {
            NSDictionary *lightDetails = [comp objectAtIndex:1];
            if (![[lightDetails objectForKey:@"projective_texture"] isEqualToString:@""])
                [listToDownload addObject:[self.serverAssetPath stringByAppendingString:
                                           [lightDetails objectForKey:@"projective_texture"]]];
            //add light
            JSONComponentLight *currLight = [[JSONComponentLight alloc] init];
            [currLight loadLight:lightDetails];
            [self.jsonScene.lights addObject:currLight];
            
        }
        if ([componentName isEqualToString:@"Camera"])
        {
            NSDictionary *camDetails = [comp objectAtIndex:1];
            JSONComponentCamera *currCamera = [[JSONComponentCamera alloc] init];
            [currCamera loadCamera:camDetails];
            [self.jsonScene.cameras addObject:currCamera];
        }
    }
    //components
    NSArray* nodes = [json objectForKey:@"nodes"]; //2
    for (NSDictionary *node in nodes)
    {
        //init node
        JSONNode *currNode = [[JSONNode alloc] init];
        currNode.components = [[NSMutableArray alloc] init];
        
        currNode.ID = [node objectForKey:@"id"];
        
        //components
        NSArray *components = [node objectForKey:@"components"];
        for (NSArray *comp in components)
        {
            NSString *componentName = [comp objectAtIndex:0];
            if ([componentName isEqualToString:@"Transform"])
            {
                NSDictionary *transform = [comp objectAtIndex:1];
                //add
                JSONComponentTransform *currTransform= [[JSONComponentTransform alloc] init];
                currTransform.componentType = JSONComponentTypeTransform;
                [currTransform loadTransform:transform];
                [currNode.components addObject:currTransform];
            }
            if ([componentName isEqualToString:@"MeshRenderer"])
            {

                //get files to download
                NSDictionary *meshes = [comp objectAtIndex:1];
                if ([meshes objectForKey:@"mesh"] != nil)
                    [listToDownload addObject:[self.serverAssetPath stringByAppendingString:[meshes objectForKey:@"mesh"]]];
                if ([meshes objectForKey:@"lod_mesh"] != nil)
                    [listToDownload addObject:[self.serverAssetPath stringByAppendingString:[meshes objectForKey:@"lod_mesh"]]];
                
                //add
                JSONComponentMeshRenderer *currMesh= [[JSONComponentMeshRenderer alloc] init];
                currMesh.componentType = JSONComponentTypeMesh;
                currMesh.mesh = [meshes objectForKey:@"mesh"];
                currMesh.lod_mesh = [meshes objectForKey:@"lod_mesh"];
                [currNode.components addObject:currMesh];
                currNode.isMesh = true;
                
            }
            if ([componentName isEqualToString:@"Light"])
            {
                //get files to download
                NSDictionary *lightDetails = [comp objectAtIndex:1];
                if ([[lightDetails objectForKey:@"projective_texture"] isKindOfClass:[NSString class]] &&
                    [[lightDetails objectForKey:@"projective_texture"] length] != 0)
                {
                    [listToDownload addObject:[self.serverAssetPath stringByAppendingString:
                                               [lightDetails objectForKey:@"projective_texture"]]];
                }
                
                //add light to scene description
                JSONComponentLight *currLight = [[JSONComponentLight alloc] init];
                currLight.componentType = JSONComponentTypeLight;
                [currLight loadLight:lightDetails];
                
                //get transform for component
                NSDictionary *transform;
                bool gotTransform = false;
                for (NSArray *tcomp in components) {
                    NSString *componentName = [tcomp objectAtIndex:0];
                    if ([componentName isEqualToString:@"Transform"])
                    {
                        transform = [tcomp objectAtIndex:1];
                        gotTransform = true;
                    }
                }
                if (gotTransform) //overwrite position from light component
                    [currLight addTransformComponent:transform];
                
                

                NSLog(@"%f %f %f", currLight.position.x, currLight.position.y, currLight.position.z);
                [self.jsonScene.lights addObject:currLight];
                [currNode.components addObject:currLight];
                currNode.isLight = true;
                [self.jsonScene.lights addObject:currLight];
            }
            if ([componentName isEqualToString:@"AnnotationComponent"])
            {
                NSDictionary *annotations = [comp objectAtIndex:1];
                NSArray *notes = [annotations valueForKey:@"notes"];
                for (NSDictionary *aNote in notes)
                {
                    //add
                    JSONComponentAnnotation *currAnnotation= [[JSONComponentAnnotation alloc] init];
                    currAnnotation.componentType = JSONComponentTypeAnnotation;
                    [currAnnotation loadAnnotation:aNote];
                    [currNode.components addObject:currAnnotation];
                }
            }
        }
        //material
        NSDictionary *material = [node objectForKey:@"material"];
        JSONMaterial *currMaterial = [[JSONMaterial alloc] init];
        [currMaterial loadMaterial:material];
        currNode.material = currMaterial;
        
        NSDictionary *textures = [material objectForKey:@"textures"];
        for (NSString *texName in textures)
        {
            NSString *texFileName = [textures objectForKey:texName];
            if ([texFileName isKindOfClass:[NSString class]] &&
                [texFileName length] != 0)
            {
                //NSString *bob = [self.serverAssetPath stringByAppendingString:texFileName];
                NSString *bob = [NSString stringWithFormat:@"%@%@",self.serverAssetPath, texFileName];
                [listToDownload addObject:bob];
                NSLog(@"");
            }
        }
        [self.jsonScene.nodes addObject:currNode];
    }
    
    NSLog(@"Start downloading files...");
    
    
    [self downloadArray:@[listToDownload,@"empty"]];
       
    /*
            if ([componentName isEqualToString:@"Transform"])
     */

}

-(void)downloadArray:(NSArray*)wrapper
{
    NSArray *array = [wrapper objectAtIndex:0];
    //if second index of array is NSData, it is a file
    if ([[wrapper objectAtIndex:1] isKindOfClass:[NSData class]] )
    {
        NSData *urlData = [wrapper objectAtIndex:1];
        //get name of downloaded file
        int indexToSave = _currentDownloadIndex - 1;
        NSString *fileToSave = [[array objectAtIndex:indexToSave] lastPathComponent];
        NSLog(@"Downloaded %@", fileToSave);
        
        //get local directory
        NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString  *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory,fileToSave];
        [urlData writeToFile:filePath atomically:YES];

    }
    
    //if we have downloaded all files, carry on
    if (_currentDownloadIndex == [array count])
    {
        NSLog(@"...finished downloading files");
        //[self loadScene];
        [self loadJSONWithCompletionHandler:^(int result){
            if (result ==1)
                [self performSegueWithIdentifier:@"go3D" sender:self];
        }];
        return;
    }
    
    //get new file
    NSURL *fileURL = [NSURL URLWithString:[array objectAtIndex:_currentDownloadIndex]];
    //increment for next iteration
    _currentDownloadIndex++;
    
    //check if already exists
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* foofile = [documentsDirectory stringByAppendingPathComponent:[[array objectAtIndex:_currentDownloadIndex-1] lastPathComponent]];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:foofile];
    if (fileExists)
    {
        [self downloadArray:@[array,@"empty"]];
    }
    else
    {
        dispatch_async(kBgQueue, ^{
            NSData* data = [NSData dataWithContentsOfURL:fileURL];
            [self performSelectorOnMainThread:@selector(downloadArray:)
                                   withObject:@[array,data] waitUntilDone:YES];
        });
    }
}

- (void) loadJSONWithCompletionHandler:(void(^)(int))handler
{
    NSLog(@"Start load scene");
    //this copy is v important cos its async
    _completionHandler = [handler copy];

    //Diffuse Texture
    NSArray *flags = [[NSArray alloc] initWithObjects:
             @"USE_DIFFUSE_TEXTURE",
             @"USE_SPECULAR_TEXTURE",
             @"USE_VELVET",
             @"LIGHT2",
             @"LIGHT2_LINEAR_ATTENUATION",
             @"USE_NORMAL_TEXTURE",
             nil];
    Shader *shaderDiffuseTexture = [[Shader alloc] initProgramWithVertex:@"ShaderUberVertex" Fragment:@"ShaderUberFragment" Flags:flags];
    
    //Diffuse Texture
    flags = [[NSArray alloc] initWithObjects:
                      @"DRAW_LINES",
                      nil];
    Shader *shaderLine = [[Shader alloc] initProgramWithVertex:@"ShaderUberVertex" Fragment:@"ShaderUberFragment" Flags:flags];
    
    //WebGL Texture
    flags = [[NSArray alloc] initWithObjects:
             @"USE_COLOR_TEXTURE uvs_0",
             //@"USE_NORMAL_TEXTURE uvs_0",
             //@"USE_NORMALMAP_FACTOR",
             //@"USE_SPECULAR_TEXTURE uvs_0",
             @"USE_DIFFUSE_LIGHT uvs_0",
             @"USE_SPECULAR_LIGHT uvs_0",
             //@"USE_VELVET",
             @"FIRST_PASS",
             //@"USE_SPECULAR_ONTOP",
             //@"USE_LINEAR_ATTENUATION",
             	@"USE_DIRECTIONAL_LIGHT",
             nil];
    Shader *shaderWebGL = [[Shader alloc] initProgramWithVertex:@"webGLVertexShader" Fragment:@"webGLPixelShader" Flags:flags];

    JSONComponentCamera *jCam = [self.jsonScene.cameras objectAtIndex:0];
    Camera *cam = [[Camera alloc] init];
    cam.name = @"Main Camera";
    cam.position = jCam.eye;
    cam.lookAt = jCam.center;
    cam.clipNear = jCam.near;
    cam.clipFar = jCam.far;
    cam.fov = jCam.fov;
    
    JSONComponentLight *jLight = [self.jsonScene.lights objectAtIndex:0];
    Light *light = [[Light alloc] init];
    light.name = @"Light";
    light.position = jLight.position;
    light.near = jLight.near; 
    light.far = jLight.far;
    light.spotCosCutoff = 0.93;
    light.intensity = jLight.intensity;
    light.diffuseColor = jLight.color;
    light.angle = jLight.angle;
    light.frustrumSize = jLight.frustrum_size;
    
    jLight = [self.jsonScene.lights objectAtIndex:1];
    Light *light2 = [[Light alloc] init];
    light2.name = @"Light2";
    light2.position = jLight.position;
    light2.near = jLight.near;
    light2.far = jLight.far;
    light2.spotCosCutoff = 0.93;
    light2.intensity = jLight.intensity;
    light2.diffuseColor = jLight.color;
    light2.angle = jLight.angle;

    //Line Material
    Material *lineMat = [[Material alloc] initWithShader:shaderLine];
    lineMat.drawLines = true;
  
    //get paths to local storage
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSError *error;
    
    //create scene

    [ResourceManager resources].scene = [[Scene alloc] initWitName:@"Lee Scene"];
    [ResourceManager resources].scene.backgroundColor = self.jsonScene.background_color;
    [ResourceManager resources].scene.ambient = self.jsonScene.ambient_color;
    [[ResourceManager resources].scene addChild:cam];
    [[ResourceManager resources].scene addChild:light];
    [[ResourceManager resources].scene addChild:light2];

    int annotationCounter = 0;

 
    //parse nodes and add to scene
    for (JSONNode *node in self.jsonScene.nodes)
    {
        if (node.isMesh)
        {
            Material *currMat = [[Material alloc] initWithShader:shaderDiffuseTexture];
           
            //color texture
            NSString  *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory,
                                   [node.material.texture_color lastPathComponent]];

            currMat.texture = [GLKTextureLoader textureWithContentsOfFile:filePath options:nil error:&error];
            NSLog(@"%@", [error localizedDescription]);
            //normal texture
            filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory,
                        [node.material.texture_normal lastPathComponent]];
            currMat.textureNormal = [GLKTextureLoader textureWithContentsOfFile:filePath options:nil error:&error];
            
            //specular texture
            filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory,
                                   [node.material.texture_specular lastPathComponent]];
            currMat.textureSpecular = [GLKTextureLoader textureWithContentsOfFile:filePath options:nil error:&error];
            //irradiance texture
            
            //other material properties
            currMat.ambient = GLKVector3Make(node.material.ambient.x, node.material.ambient.y, node.material.ambient.z);
            currMat.color = GLKVector4Make(node.material.color.x, node.material.color.y, node.material.color.z, 1.0);
            currMat.diffuse = GLKVector4Make(node.material.diffuse.x, node.material.diffuse.y, node.material.diffuse.z, 1.0);
            currMat.emissive = GLKVector3Make(node.material.emissive.x, node.material.emissive.y, node.material.emissive.z);
            currMat.specular = node.material.specular_factor;
            currMat.shininess = node.material.specular_gloss;
            currMat.velvet = node.material.velvet;
            currMat.velvet_exp = node.material.velvet_exp;
            currMat.detailInfo = node.material.detail;
            currMat.backlightFactor = node.material.backlight_factor;
            currMat.normalMapFactor = node.material.normalmap_factor;
            currMat.brightnessFactor = 1.0;
            currMat.lightOffset = 0.0;
            currMat.colorclipFactor = 0.0;
            
            //load mesh
            Mesh *currMesh = [[Mesh alloc] init];
            for (JSONComponent *comp in node.components)
            {
                //assign mesh
                if (comp.componentType == JSONComponentTypeMesh)
                {

                    //get local path
                    JSONComponentMeshRenderer *jMesh = (JSONComponentMeshRenderer*)comp;
                    NSString *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory,[jMesh.mesh lastPathComponent]];
                    //load mesh
                    [currMesh LoadWaveFrontOBJ:filePath];
                    [currMesh assignMaterial:currMat];

                }
                //assign transform
                if (comp.componentType == JSONComponentTypeTransform)
                {
                    JSONComponentTransform *jTransform = (JSONComponentTransform*)comp;
                    currMesh.scale = jTransform.scale.x;
                    currMesh.rotation = jTransform.rotation;
                    currMesh.position = jTransform.position;
                }
                //check components
                if (comp.componentType == JSONComponentTypeAnnotation)
                {
                    JSONComponentAnnotation *jAnnotation = (JSONComponentAnnotation*)comp;
                    float scale = 1.0;
                    GLKVector3 transform = GLKVector3Make(0.0,0.0,0.0);
                    //search for transform
                    for (JSONComponent *comp in node.components)
                        if (comp.componentType == JSONComponentTypeTransform)
                        {
                            JSONComponentTransform *jTransform = (JSONComponentTransform*)comp;
                            scale = jTransform.scale.x;
                            transform = jTransform.position;
                        }
                    //make mesh line
                    std::vector<GLfloat> lineVecs;
                    lineVecs.push_back(jAnnotation.startPosition.x*scale+transform.x);
                    lineVecs.push_back(jAnnotation.startPosition.y*scale+transform.y);
                    lineVecs.push_back(jAnnotation.startPosition.z*scale+transform.z);
                    lineVecs.push_back(0.0); lineVecs.push_back(0.0); lineVecs.push_back(0.0);
                    lineVecs.push_back(0.0); lineVecs.push_back(0.0);
                    lineVecs.push_back(jAnnotation.endPosition.x*scale+transform.x);
                    lineVecs.push_back(jAnnotation.endPosition.y*scale+transform.y);
                    lineVecs.push_back(jAnnotation.endPosition.z*scale+transform.z);
                    lineVecs.push_back(0.0); lineVecs.push_back(0.0); lineVecs.push_back(0.0);
                    lineVecs.push_back(0.0); lineVecs.push_back(0.0);
                    std::vector<GLuint> lineInds;
                    lineInds.push_back(0); lineInds.push_back(1);
                    
                    //Make annotation labels
                    CGSize s = [jAnnotation.text sizeWithFont:[UIFont systemFontOfSize:12] constrainedToSize:CGSizeMake(1024.0, 768.0) lineBreakMode:NSLineBreakByWordWrapping];
                    UILabel *newLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, s.width, s.height)];
                    [newLabel setText:jAnnotation.text];
                    newLabel.backgroundColor = [UIColor clearColor];
                    newLabel.textColor = [UIColor whiteColor];
                    [newLabel setFont:[UIFont systemFontOfSize:12]];
                    newLabel.numberOfLines = 0;
                    
                    //add to scene - will be added to view in 3D view controller
                    [[ResourceManager resources].scene.annotationLabels addObject:newLabel];
                    

                    //add mesh to scene graph
                    Mesh *newAnnotation = [[Mesh alloc] initWithDataBuffer:lineVecs indexBuffer:lineInds material:lineMat];
                    newAnnotation.isAnnotation = true;
                    newAnnotation.annotationNumber = annotationCounter;
                    newAnnotation.annotationEndPoint = GLKVector3Make(jAnnotation.endPosition.x*scale+transform.x,
                                                                      jAnnotation.endPosition.y*scale+transform.y,
                                                                      jAnnotation.endPosition.z*scale+transform.z);
                    annotationCounter++;
                    [[ResourceManager resources].scene addChild:newAnnotation];
                }
                
            }
            [[ResourceManager resources].scene addChild:currMesh];
            
        }
    }
    

    // Call completion handler - this performs the segue and loads 3D view
    int result = 1;
    _completionHandler(result);
    _completionHandler = nil;
}











/*
 *
 * STATIC SCENE NOT LOADED FROM NET
 *
 */


- (void) loadAssetsWithCompletionHandler:(void(^)(int))handler
{
    // NOTE: copying is very important if you'll call the callback asynchronously,
    // even with garbage collection!
    _completionHandler = [handler copy];
    
    

    
    //Init Objects and Materials
    //Compile Shaders
    //Shader *loader = [[Shader alloc] init];
    

    

    
    //Straight phong
    NSArray *flags = [[NSArray alloc] initWithObjects:
                      @"USE_HARD_SHADOWS",
                      //@"USE_SOFT_SHADOWS",
                      //@"USE_SPOT_LIGHT",
                      nil];
    Shader *shaderPhong = [[Shader alloc] initProgramWithVertex:@"ShaderUberVertex" Fragment:@"ShaderUberFragment" Flags:flags];
    //GLuint shaderPhong  = [loader createProgramWithVertex:@"ShaderUberVertex" Fragment:@"ShaderUberFragment" Flags:flags];
    
    
    //Diffuse Texture
    flags = [[NSArray alloc] initWithObjects:
             @"USE_DIFFUSE_TEXTURE",
             //@"USE_SOFT_SHADOWS",
             //@"USE_HARD_SHADOWS",
             //@"USE_SPOT_LIGHT",
             nil];
    //GLuint shaderDiffuseTexture = [loader createProgramWithVertex:@"ShaderUberVertex" Fragment:@"ShaderUberFragment" Flags:flags];
    Shader *shaderDiffuseTexture = [[Shader alloc] initProgramWithVertex:@"ShaderUberVertex" Fragment:@"ShaderUberFragment" Flags:flags];
    
    //Diffuse Detail Texture
    flags = [[NSArray alloc] initWithObjects:
             @"USE_DIFFUSE_TEXTURE",
             //@"USE_HARD_SHADOWS",
             //@"USE_SOFT_SHADOWS",
             //@"USE_SPOT_LIGHT",
             @"USE_DETAIL_TEXTURE",
             nil];
    //GLuint shaderDetailTexture = [loader createProgramWithVertex:@"ShaderUberVertex" Fragment:@"ShaderUberFragment" Flags:flags];
    Shader *shaderDetailTexture = [[Shader alloc] initProgramWithVertex:@"ShaderUberVertex" Fragment:@"ShaderUberFragment" Flags:flags];
    
    
    //create nodes
    
    Camera *cam = [[Camera alloc] init];
    cam.name = @"Main Camera";
    cam.position = GLKVector3Make(0.12079625762254009, 144.7904492272644, 250.54446586249261);
    cam.lookAt = GLKVector3Make(0.12079625762254009, 133.0266405, 1.359303318242133);
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

    
    /*
    Material *avatarMat = [[Material alloc] initWithShader:shaderPhong];
    avatarMat.color = GLKVector4Make(0.0, 0.0, 0.0, 1.0);
    avatarMat.diffuse = GLKVector4Make(0.19, 0.15, 0.15, 1.0);
    avatarMat.ambient = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
    avatarMat.specular = 0.5;
    avatarMat.shininess = 1.0;
    Mesh *avatarMesh = [ResourceManager WaveFrontOBJLoadMesh:@"avatar_girl.obj" withMaterial:avatarMat];
    avatarMesh.name = @"Avatar";
    avatarMesh.rotation = GLKQuaternionMake(0, -0.46931692957878113, 0, -0.8830292820930481);
    avatarMesh.scale = 1.0;
    //avatarMesh.rotationZ = 90.0;
     
     
     
     
    
    Material *shirtMat = [[Material alloc] initWithTexture:@"dress_top" ofType:@"jpg" andShader:shaderDiffuseTexture];
    Mesh *shirtMesh = [ResourceManager WaveFrontOBJLoadMesh:@"tshirt.obj" withMaterial:shirtMat];
    shirtMesh.name = @"Shirt";
    shirtMat.ambient = GLKVector4Make(0.65, 0.65, 0.65, 1.0);
    shirtMat.diffuse = GLKVector4Make(0.7, 0.7, 0.7, 0.7);
    shirtMat.specular = 0.05;
    shirtMat.shininess = 4.0;

    
   
    Material *skirtMat = [[Material alloc] initWithTexture:@"dress_skirt" ofType:@"jpg" andShader:shaderDetailTexture];
    [skirtMat loadDetailTexture:@"detail_jeans" ofType:@"png"];
    Mesh *skirtMesh = [ResourceManager WaveFrontOBJLoadMesh:@"skirt.obj" withMaterial:skirtMat];
    skirtMesh.name = @"Skirt";
    skirtMat.ambient = GLKVector4Make(0.65, 0.65, 0.65, 1.0);
    skirtMat.diffuse = GLKVector4Make(0.7, 0.7, 0.7, 0.7);
    skirtMat.specular = 0.05;
    skirtMat.shininess = 4.0;
    */
    
    Material *floorMat = [[Material alloc] initWithShader:shaderPhong];
    floorMat.diffuse = GLKVector4Make(0.65, 0.65, 0.65, 1.0);
    //floorMat.ambient = GLKVector4Make(0.1, 0.1, 0.1, 1.0);
    floorMat.ambient = GLKVector3Make(1.0, 1.0, 1.0);
    floorMat.specular = 0.1;
    floorMat.shininess = 10.0;
    Mesh *floorMesh = [ResourceManager WaveFrontOBJLoadMesh:@"floor.obj" withMaterial:floorMat];
    floorMesh.scale = 10.0f;
    floorMesh.name = @"Floor";
     
    /*
    //Init scene and add objects to graph
    [ResourceManager resources].scene = [[Scene alloc] initWitName:@"Body Scene"];
    [ResourceManager resources].scene.backgroundColor = GLKVector3Make(0.89, 0.89, 0.87);
    [[ResourceManager resources].scene addChild:cam];
    [[ResourceManager resources].scene addChild:light];
    //[[ResourceManager resources].scene addChild:floorMesh];
    [[ResourceManager resources].scene addChild:avatarMesh];
    //[[ResourceManager resources].scene addChild:shirtMesh];
    [avatarMesh addChild:shirtMesh];
    //[avatarMesh addChild:skirtMesh];
     */


 
    
    Material *leeMat = [[Material alloc] initWithTexture:@"Lee.jpg" andShader:shaderDiffuseTexture];
    Mesh *leeMesh = [ResourceManager WaveFrontOBJLoadMesh:@"Lee.obj" withMaterial:leeMat];
    leeMesh.name = @"Lee";
    leeMat.ambient = GLKVector3Make(0.65, 0.65, 0.65);
    leeMat.diffuse = GLKVector4Make(0.7, 0.7, 0.7, 0.7);
    leeMat.specular = 0.05;
    leeMat.shininess = 4.0;
    
    cam.lookAt = GLKVector3Make(0.0, 0.0, 0.0);
    [ResourceManager resources].scene = [[Scene alloc] initWitName:@"Lee Scene"];
    [ResourceManager resources].scene.backgroundColor = GLKVector3Make(0.0, 0.0, 0.0);
    [[ResourceManager resources].scene addChild:cam];
    [[ResourceManager resources].scene addChild:light];
    [[ResourceManager resources].scene addChild:leeMesh];
    //[[ResourceManager resources].scene addChild:floorMesh];
    
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
