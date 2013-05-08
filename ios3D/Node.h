//
//  Node.h
//  ios3D
//
//  Created by Alun on 3/27/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "Material.h"

@interface Node : NSObject

@property (assign) GLKVector3 position;
@property (strong) NSMutableArray * children;
@property (assign) float rotationX;
@property (assign) float rotationY;
@property (assign) float rotationZ;
@property (assign) GLKQuaternion rotation;
@property (assign) float scale;
@property (strong) NSString *name;


- (void)renderWithModel:(GLKMatrix4)modelMatrix;
- (GLKMatrix4)getModelMatrix;

- (void)renderWithMV:(GLKMatrix4)modelViewMatrix P:(GLKMatrix4)projectionMatrix;
- (void)update:(float)dt;
- (GLKMatrix4) modelMatrix:(BOOL)renderingSelf;
- (void)addChild:(Node *)child;
- (void)handleTouchDown:(CGPoint)touchLocation;
- (void)handleTouchMoved:(CGPoint)touchLocation;
- (void)handleTouchUp:(CGPoint)touchLocation;


@end
