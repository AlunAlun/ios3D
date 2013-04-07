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
@synthesize name = _name;

- (id)init {
    if ((self = [super init])) {
        self.children = [NSMutableArray array];
        self.scale = 1.0;
        self.rotation = 0;
        self.position = GLKVector3Make(0,0,0);
        self.name = @"node";
    }
    return self;
}

- (void)renderWithMV:(GLKMatrix4)modelViewMatrix P:(GLKMatrix4)projectionMatrix;
{
    //we're not rendering here because it will be subclassed
    // ALL SUBCLASSES MUST CALL [super renderWithMV P]
    
    //move this node to it's stored position
    GLKMatrix4 childModelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, [self modelMatrix:NO]);
    //vamos a renderizar todos los hijos
    for (Node * node in self.children) {
        [node renderWithMV:childModelViewMatrix P:projectionMatrix];
    }
}

- (void)update:(float)dt
{
    
}
- (GLKMatrix4) modelMatrix:(BOOL)renderingSelf
{
    //cargar identity matrix
    GLKMatrix4 modelMatrix = GLKMatrix4Identity;

    //trasladar a nuestro posicion
    modelMatrix = GLKMatrix4Translate(modelMatrix, self.position.x, self.position.y, self.position.z );
    
    //aplicar rotacion
    //float radians = GLKMathDegreesToRadians(self.rotation);
    //modelMatrix = GLKMatrix4Rotate(modelMatrix, radians, 0, 0, 1);
    
    //aplicar scale
    modelMatrix = GLKMatrix4Scale(modelMatrix, self.scale, self.scale, self.scale);
    
    return modelMatrix;
}
- (void)addChild:(Node *)child
{
    [self.children addObject:child];
}
- (void)handleTouchDown:(CGPoint)touchLocation
{
    
}
- (void)handleTouchMoved:(CGPoint)touchLocation
{
    
}
- (void)handleTouchUp:(CGPoint)touchLocation{
    
}

- (void)dealloc
{

}

@end
