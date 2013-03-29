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

-(id)init
{
    if ((self = [super init])) {

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
