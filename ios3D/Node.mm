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
@synthesize rotationX = _rotationX;
@synthesize rotationY = _rotationY;
@synthesize rotationZ = _rotationZ;
@synthesize rotation = _rotation;
@synthesize scale = _scale;
@synthesize name = _name;

- (id)init {
    if ((self = [super init])) {
        self.children = [NSMutableArray array];
        self.scale = 1.0;
        self.rotationX = 0;
        self.rotationY = 0;
        self.rotationZ = 0;
        self.position = GLKVector3Make(0,0,0);
        self.rotation = GLKQuaternionMake(0.0,0.0,0.0,1.0);
        self.name = @"node";
    }
    return self;
}

- (GLKMatrix4)getModelMatrix
{
    GLKMatrix4 modelMatrix = GLKMatrix4Identity;
    
    //translate
    modelMatrix = GLKMatrix4Translate(modelMatrix, self.position.x, self.position.y, self.position.z);
    
    //rotate
    float radians = GLKMathDegreesToRadians(self.rotationX);
    modelMatrix = GLKMatrix4RotateX(modelMatrix, radians);
    radians = GLKMathDegreesToRadians(self.rotationY);
    modelMatrix = GLKMatrix4RotateY(modelMatrix, radians);
    radians = GLKMathDegreesToRadians(self.rotationZ);
    modelMatrix = GLKMatrix4RotateZ(modelMatrix, radians);
    
    GLKMatrix4 rotMatrix = GLKMatrix4MakeWithQuaternion(self.rotation);
    modelMatrix = GLKMatrix4Multiply(rotMatrix, modelMatrix);

    //scale
    modelMatrix = GLKMatrix4Scale(modelMatrix, self.scale, self.scale, self.scale);
    return modelMatrix;
}

- (void)renderWithModel:(GLKMatrix4)modelMatrix
{
    //we're not rendering here because it will be subclassed
    // ALL SUBCLASSES MUST CALL [super renderWithModel]
    GLKMatrix4 childModelMatrix = GLKMatrix4Multiply(modelMatrix, [self getModelMatrix]);
    for (Node * node in self.children) {
        [node renderWithModel:childModelMatrix];
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

/*- (void)setRotation:(GLKQuaternion)rotVector
{
    self.rotationX = rotVector.x;
    self.rotationY = rotVector.y;
    self.rotationZ = rotVector.z;
}*/

- (void)dealloc
{

}

@end
