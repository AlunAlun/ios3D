//
//  Material.m
//  ios3D
//
//  Created by Alun on 3/27/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import "Material.h"
#define DEFAULT_DIFFUSE 0.8
#define DEFAULT_AMBIENT 0.2
#define DEFAULT_SPECULAR 0.0
#define DEFAULT_SHININESS 30.0

@implementation Material
@synthesize texture = _texture;
@synthesize textureDetail = _textureDetail;
@synthesize name = _name;
@synthesize diffuse = _diffuse;
@synthesize ambient = _ambient;
@synthesize specular = _specular;
@synthesize shininess = _shininess;

-(id)init
{
    if ((self = [super init])) {
        self.name = @"WhiteTexture";
        self.diffuse = GLKVector4Make(DEFAULT_DIFFUSE, DEFAULT_DIFFUSE, DEFAULT_DIFFUSE, 1.0);
        self.ambient = GLKVector4Make(DEFAULT_AMBIENT, DEFAULT_AMBIENT, DEFAULT_AMBIENT, 1.0);
        self.specular = GLKVector4Make(DEFAULT_SPECULAR, DEFAULT_SPECULAR, DEFAULT_SPECULAR, 1.0);
        self.shininess = DEFAULT_SHININESS;
        [self loadTexture:@"white" ofType:@"png"];
        self.textureDetail = nil;
    }
    return self;
}

-(id)initWithTexture:(NSString*)filename ofType:(NSString*)type
{
    if ((self = [super init])) {
        //load texture
        NSError *error;
        NSString* filePath = [[NSBundle mainBundle] pathForResource:filename ofType:type];
        self.texture = [GLKTextureLoader textureWithContentsOfFile:filePath options:nil error:&error];
        if(error) {
            NSLog(@"Error loading texture from image: %@", error);
            exit(1);
        }
        self.name = filename;
        self.textureDetail = nil;
        self.diffuse = GLKVector4Make(DEFAULT_DIFFUSE, DEFAULT_DIFFUSE, DEFAULT_DIFFUSE, 1.0);
        self.ambient = GLKVector4Make(DEFAULT_AMBIENT, DEFAULT_AMBIENT, DEFAULT_AMBIENT, 1.0);
        self.specular = GLKVector4Make(DEFAULT_SPECULAR, DEFAULT_SPECULAR, DEFAULT_SPECULAR, 1.0);
        self.shininess = DEFAULT_SHININESS;
    }
    return self;
}

-(void)loadTexture:(NSString *)filename ofType:(NSString*)type
{
    //load texture
    NSError *error;
    NSString* filePath = [[NSBundle mainBundle] pathForResource:filename ofType:type];
    self.texture = [GLKTextureLoader textureWithContentsOfFile:filePath options:nil error:&error];
    if(error) {
        NSLog(@"Error loading texture from image: %@", error);
        exit(1);
    }    
}

-(void)loadDetailTexture:(NSString *)filename ofType:(NSString*)type
{
    NSError *error;
    NSString* filePath = [[NSBundle mainBundle] pathForResource:filename ofType:type];
    self.textureDetail = [GLKTextureLoader textureWithContentsOfFile:filePath options:nil error:&error];
    if(error) {
        NSLog(@"Error loading texture from image: %@", error);
        exit(1);
    }
}

@end