//
//  AssetsSingleton.h
//  ios3D
//
//  Created by Alun on 4/1/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Scene.h"
#import "Mesh.h"
#import "Material.h"


@interface ResourceManager : NSObject {
    // whatever instance vars you want
}

@property (nonatomic, strong) EAGLContext *context;
@property (assign) int screenWidth;
@property (assign) int screenHeight;
@property (nonatomic, strong) Scene *scene;
@property (nonatomic, strong) NSMutableArray *sceneNodes;
@property (nonatomic, strong) NSMutableArray *textures;
@property (nonatomic, strong) NSMutableArray *materials;
@property (assign) GLKMatrix4 sceneModelMatrix;
@property (assign) int totalTris;

+ (ResourceManager *)resources;   // class method to return the singleton object

- (void)addSceneNode:(Node*)node; 
- (Node*)getSceneNodeWithName:(NSString *)name;

+ (Mesh*)WaveFrontOBJLoadMesh:(NSString*)fileName withMaterial:(Material*)mat;

@end
