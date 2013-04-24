//
//  Renderer.h
//  ios3D
//
//  Created by Alun on 4/6/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "Material.h"
#import "Mesh.h"

#import <stdio.h>
#include <map>
#include <string>
#include <vector>


typedef struct
{
    Material *mat;
    GLKMatrix4 model;
    Mesh *mesh;
} RenderInstance;

@interface Renderer : NSObject {
    std::vector<RenderInstance> _instances;
}

+ (Renderer*)renderer;
- (void)renderAllWithMV:(GLKMatrix4)modelView P:(GLKMatrix4)projection;
- (void)addInstance:(RenderInstance)toAdd;
- (std::vector<RenderInstance>)getInstances;
- (void)clearInstances;
- (int)getNumInstances;

@end
