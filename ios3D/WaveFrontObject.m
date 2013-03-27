//
//  WaveFrontObject.m
//  ios3D
//
//  Created by Alun on 3/27/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import "WaveFrontObject.h"

@interface WaveFrontObject()
{
    GLuint _program;
    GLuint _verticesVBO;
    GLuint _indicesVBO;
    GLuint _VAO;
}

@property (strong) GLKTextureInfo * texture;

@end

@implementation WaveFrontObject
@synthesize sourceObjFilePath;
@synthesize sourceMtlFilePath;
@synthesize materials;
@synthesize groups;

- (id)initWithPath:(NSString *)path program:(GLuint)program;
{
	
	if ((self = [super init]))
	{
		self.groups = [NSMutableArray array];
		
		self.sourceObjFilePath = path;
		NSString *objData = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
		int vertexCount = 0, faceCount = 0, textureCoordsCount=0, groupCount = 0;
		// Iterate through file once to discover how many vertices, normals, and faces there are
		NSArray *lines = [objData componentsSeparatedByString:@"\n"];
		BOOL firstTextureCoords = YES;
		NSMutableArray *vertexCombinations = [[NSMutableArray alloc] init];
		for (NSString * line in lines)
		{
			if ([line hasPrefix:@"v "])
				vertexCount++;
			else if ([line hasPrefix:@"vt "])
			{
				textureCoordsCount++;
				if (firstTextureCoords)
				{
					firstTextureCoords = NO;
					NSString *texLine = [line substringFromIndex:3];
					NSArray *texParts = [texLine componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
					valuesPerCoord = [texParts count];
				}
			}
			else if ([line hasPrefix:@"m"])
			{
				NSString *truncLine = [line substringFromIndex:7];
				self.sourceMtlFilePath = truncLine;
				NSString *mtlPath = [[NSBundle mainBundle] pathForResource:[[truncLine lastPathComponent] stringByDeletingPathExtension] ofType:[truncLine pathExtension]];
//TODO materials				self.materials = [OpenGLWaveFrontMaterial materialsFromMtlFile:mtlPath];
			}
			else if ([line hasPrefix:@"g"])
				groupCount++;
			else if ([line hasPrefix:@"f"])
			{
				faceCount++;
				NSString *faceLine = [line substringFromIndex:2];
				NSArray *faces = [faceLine componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				for (NSString *oneFace in faces)
				{
					NSArray *faceParts = [oneFace componentsSeparatedByString:@"/"];
					
					NSString *faceKey = [NSString stringWithFormat:@"%@/%@", [faceParts objectAtIndex:0], ([faceParts count] > 1) ? [faceParts objectAtIndex:1] : 0];
					if (![vertexCombinations containsObject:faceKey])
						[vertexCombinations addObject:faceKey];
				}
			}
			
		}
        NSLog(@"%i",vertexCount);
        /*
		vertices = malloc(sizeof(Vertex3D) *  [vertexCombinations count]);
		GLfloat *allTextureCoords = malloc(sizeof(GLfloat) *  textureCoordsCount * valuesPerCoord);
		textureCoords = (textureCoordsCount > 0) ?  malloc(sizeof(GLfloat) * valuesPerCoord * [vertexCombinations count]) : NULL;
		// Store the counts
		numberOfFaces = faceCount;
		numberOfVertices = [vertexCombinations count];
		GLuint allTextureCoordsCount = 0;
		textureCoordsCount = 0;
		GLuint groupFaceCount = 0;
		GLuint groupCoordCount = 0;
		// Reuse our count variables for second time through
		vertexCount = 0;
		faceCount = 0;
		OpenGLWaveFrontGroup *currentGroup = nil;
		NSUInteger lineNum = 0;
		BOOL usingGroups = YES;
		
		VertexTextureIndex *rootNode = nil;
		for (NSString * line in lines)
		{
			if ([line hasPrefix:@"v "])
			{
				NSString *lineTrunc = [line substringFromIndex:2];
				NSArray *lineVertices = [lineTrunc componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				vertices[vertexCount].x = [[lineVertices objectAtIndex:0] floatValue];
				vertices[vertexCount].y = [[lineVertices objectAtIndex:1] floatValue];
				vertices[vertexCount].z = [[lineVertices objectAtIndex:2] floatValue];
				// Ignore weight if it exists..
				vertexCount++;
			}
			else if ([line hasPrefix: @"vt "])
			{
				NSString *lineTrunc = [line substringFromIndex:3];
				NSArray *lineCoords = [lineTrunc componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				//int coordCount = 1;
				for (NSString *oneCoord in lineCoords)
				{
                    //					if (valuesPerCoord == 2 /* using UV Mapping * && coordCount++ == 1 /* is U value *)
                    //						allTextureCoords[allTextureCoordsCount] = CONVERT_UV_U_TO_ST_S([oneCoord floatValue]);
                    //					else
                    allTextureCoords[allTextureCoordsCount] = [oneCoord floatValue];
					//NSLog(@"Setting allTextureCoords[%d] to %f", allTextureCoordsCount, [oneCoord floatValue]);
					allTextureCoordsCount++;
				}
				
				// Ignore weight if it exists..
				textureCoordsCount++;
			}
			else if ([line hasPrefix:@"g "])
			{
				NSString *groupName = [line substringFromIndex:2];
				NSUInteger counter = lineNum+1;
				NSUInteger currentGroupFaceCount = 0;
				NSString *materialName = nil;
				while (counter < [lines count])
				{
					NSString *nextLine = [lines objectAtIndex:counter++];
					if ([nextLine hasPrefix:@"usemtl "])
						materialName = [nextLine substringFromIndex:7];
					else if ([nextLine hasPrefix:@"f "])
					{
						// TODO: Loook for quads and double-increment
						currentGroupFaceCount ++;
					}
					else if ([nextLine hasPrefix:@"g "])
						break;
				}
				
				OpenGLWaveFrontMaterial *material = [materials objectForKey:materialName] ;
				if (material == nil)
					material = [OpenGLWaveFrontMaterial defaultMaterial];
				
				currentGroup = [[OpenGLWaveFrontGroup alloc] initWithName:groupName
															numberOfFaces:currentGroupFaceCount
																 material:material];
				[groups addObject:currentGroup];
				[currentGroup release];
				groupFaceCount = 0;
				groupCoordCount = 0;
			}
			else if ([line hasPrefix:@"usemtl "])
			{
				NSString *materialKey = [line substringFromIndex:7];
				currentGroup.material = [materials objectForKey:materialKey];
			}
			else if ([line hasPrefix:@"f "])
			{
				NSString *lineTrunc = [line substringFromIndex:2];
				NSArray *faceIndexGroups = [lineTrunc componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				
				// If no groups in file, create one group that has all the vertices and uses the default material
				if (currentGroup == nil)
				{
					OpenGLWaveFrontMaterial *tempMaterial = nil;
					NSArray *materialKeys = [materials allKeys];
					if ([materialKeys count] == 2)
					{
						// 2 means there's one in file, plus default
						for (NSString *key in materialKeys)
							if (![key isEqualToString:@"default"])
								tempMaterial = [materials objectForKey:key];
					}
					if (tempMaterial == nil)
						tempMaterial = [OpenGLWaveFrontMaterial defaultMaterial];
					
					currentGroup = [[OpenGLWaveFrontGroup alloc] initWithName:@"default"
																numberOfFaces:numberOfFaces
																	 material:tempMaterial];
					[groups addObject:currentGroup];
					[currentGroup release];
					usingGroups = NO;
				}
				
				// TODO: Look for quads and build two triangles
				
				NSArray *vertex1Parts = [[faceIndexGroups objectAtIndex:0] componentsSeparatedByString:@"/"];
				GLuint vertex1Index = [[vertex1Parts objectAtIndex:kGroupIndexVertex] intValue]-1;
				GLuint vertex1TextureIndex = 0;
				if ([vertex1Parts count] > 1)
					vertex1TextureIndex = [[vertex1Parts objectAtIndex:kGroupIndexTextureCoordIndex] intValue]-1;
				if (rootNode == NULL)
					rootNode =  VertexTextureIndexMake(vertex1Index, vertex1TextureIndex, UINT_MAX);
				
				processOneVertex(rootNode, vertex1Index, vertex1TextureIndex, &vertexCount, vertices, allTextureCoords, textureCoords, valuesPerCoord, &(currentGroup.faces[groupFaceCount].v1));
				NSArray *vertex2Parts = [[faceIndexGroups objectAtIndex:1] componentsSeparatedByString:@"/"];
				processOneVertex(rootNode, [[vertex2Parts objectAtIndex:kGroupIndexVertex] intValue]-1, [vertex2Parts count] > 1 ? [[vertex2Parts objectAtIndex:kGroupIndexTextureCoordIndex] intValue]-1 : 0, &vertexCount, vertices, allTextureCoords, textureCoords, valuesPerCoord, &currentGroup.faces[groupFaceCount].v2);
				NSArray *vertex3Parts = [[faceIndexGroups objectAtIndex:2] componentsSeparatedByString:@"/"];
				processOneVertex(rootNode, [[vertex3Parts objectAtIndex:kGroupIndexVertex] intValue]-1, [vertex3Parts count] > 1 ? [[vertex3Parts objectAtIndex:kGroupIndexTextureCoordIndex] intValue]-1 : 0, &vertexCount, vertices, allTextureCoords, textureCoords, valuesPerCoord, &currentGroup.faces[groupFaceCount].v3);
				
				faceCount++;
				groupFaceCount++;
			}
			lineNum++;
			
		}
		//NSLog(@"Final vertex count: %d", vertexCount);
		
		[self calculateNormals];
		if (allTextureCoords)
			free(allTextureCoords);
		[vertexCombinations release];
		VertexTextureIndexFree(rootNode);
         */
	}
	return self;
}


@end
