//
//  WaveFrontObject.h
//  ios3D
//
//  Created by Alun on 3/27/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import "Node.h"
#import "Material.h"

@interface WaveFrontObject : Node {
    NSString			*sourceObjFilePath;
    NSString			*sourceMtlFilePath;

    GLuint				numberOfVertices;
    GLfloat             vertices;
    GLuint				numberOfFaces;			// Total faces in all groups

    //Vector3D			*surfaceNormals;		// length = numberOfFaces
    //Vector3D			*vertexNormals;			// length = numberOfFaces (*3 vertices per triangle);

    //GLfloat				*textureCoords;
    GLubyte				valuesPerCoord;			// 1, 2, or 3, representing U, UV, or UVW mapping, could be 4 but OBJ doesn't support 4

    NSMutableDictionary		*materials;
    NSMutableArray		*groups;

}
@property (strong, nonatomic) NSString *sourceObjFilePath;
@property (strong, nonatomic) NSString *sourceMtlFilePath;
@property (strong, nonatomic) NSMutableDictionary *materials;
@property (strong, nonatomic) NSMutableArray *groups;
@property (strong, nonatomic) NSMutableArray *dataBufferArray;
@property (strong, nonatomic) NSMutableArray *indexBufferArray;

- (id)initWithPath:(NSString *)path program:(GLuint)program error:(NSError**)error;
- (Material*)getDefaultMaterial;
- (Material*)getMaterialCalled:(NSString*)matName;
- (void)setProgram:(GLuint)program;


@end
