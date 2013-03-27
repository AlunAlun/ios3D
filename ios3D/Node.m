//
//  Node.m
//  ios3D
//
//  Created by Alun on 3/27/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import "Node.h"


@implementation Node
@synthesize position = _position;
@synthesize children = _children;
@synthesize rotation = _rotation;
@synthesize scale = _scale;

- (id)init {
    if ((self = [super init])) {
        self.children = [NSMutableArray array];
        self.scale = 1;
        self.position = GLKVector3Make(0,0,0);
    }
    return self;
}

- (void)renderWithModelViewMatrix:(GLKMatrix4)modelViewMatrix
{
    
}
- (void)update:(float)dt
{
    
}
- (GLKMatrix4) modelMatrix:(BOOL)renderingSelf
{
    //cargar identity matrix
    GLKMatrix4 modelMatrix = GLKMatrix4Identity;
    //trasladar a nuestro posicion
    modelMatrix = GLKMatrix4Translate(modelMatrix, self.position.x, self.position.y, 0);
    
    //aplicar rotacion
    float radians = GLKMathDegreesToRadians(self.rotation);
    modelMatrix = GLKMatrix4Rotate(modelMatrix, radians, 0, 0, 1);
    
    //aplicar scale
    modelMatrix = GLKMatrix4Scale(modelMatrix, self.scale, self.scale, 0);
    
    return modelMatrix;
}
- (void)addChild:(Node *)child
{
    
}
- (void)handleTouchDown:(CGPoint)touchLocation
{
    
}
- (void)handleTouchMoved:(CGPoint)touchLocation
{
    
}
- (void)handleTouchUp:(CGPoint)touchLocation{
    
}

@end
