//
//  Material.m
//  ios3D
//
//  Created by Alun on 3/27/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import "Material.h"

@implementation Material
@synthesize texture = _texture;
@synthesize name = _name;
@synthesize diffuse = _diffuse;
@synthesize ambient = _ambient;
@synthesize specular = _specular;
@synthesize shininess = _shininess;

-(id)init
{
    if ((self = [super init])) {
        self.ambient = GLKVector4Make(0.8, 0.8, 0.8, 1.0);
        self.diffuse = GLKVector4Make(0.8, 0.8, 0.8, 1.0);
        self.specular = GLKVector4Make(0.0, 0.0, 0.0, 1.0);
        self.shininess = 65.0;
        [self loadTexture:@"white" ofType:@"png"];
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
        self.ambient = GLKVector4Make(0.8, 0.8, 0.8, 1.0);
        self.diffuse = GLKVector4Make(0.8, 0.8, 0.8, 1.0);
        self.specular = GLKVector4Make(0.0, 0.0, 0.0, 1.0);
        self.shininess = 65.0;
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

@end
