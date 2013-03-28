//
//  WaveFrontObject.m
//  ios3D
//
//  Created by Alun on 3/27/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import "WaveFrontObject.h"
#define BUFFER_OFFSET(i) ((char *)NULL + i)


@interface WaveFrontObject()
{
    GLuint _program;
    GLuint _verticesVBO;
    GLuint _indicesVBO;
    GLuint _VAO;

    GLuint _indexBufferSize;
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
		_program = program;
        
        //*************************
        //* Load file
        //*************************
		self.sourceObjFilePath = path;
		NSString *objData = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
		int vertexCount = 0, faceCount = 0, textureCoordsCount=0, groupCount = 0;
        
        //*************************
        //***** Iterate through file once to discover how many vertices, normals, and faces there are *****//
        //*************************
		
		NSArray *lines = [objData componentsSeparatedByString:@"\n"];
		BOOL firstTextureCoords = YES;
		NSMutableArray *vertexCombinations = [[NSMutableArray alloc] init];
        NSMutableArray *indexArray = [[NSMutableArray alloc] init];
  
		for (NSString * line in lines)
		{
			if ([line hasPrefix:@"v "])
				vertexCount++;
			else if ([line hasPrefix:@"vt "])
			{
				textureCoordsCount++;
				if (firstTextureCoords) // count to see how many texture coords there are
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
//TODO materials        self.materials = [OpenGLWaveFrontMaterial materialsFromMtlFile:mtlPath];
			}
			else if ([line hasPrefix:@"g"])
				groupCount++;
			else if ([line hasPrefix:@"f"])
			{
				faceCount++;
                //the line without the initial "f "
				NSString *faceLine = [line substringFromIndex:2];

				NSArray *faces = [faceLine componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				for (NSString *oneFace in faces)
				{
                    [indexArray addObject:oneFace]; // add all three
                    if (![vertexCombinations containsObject:oneFace])
						[vertexCombinations addObject:oneFace];
					               
					/* //********* DECOMMENT THIS IF WE WANT TO CALCULATE NORMALS OURSELVES *******
                    NSArray *faceParts = [oneFace componentsSeparatedByString:@"/"];
					NSString *faceKey = [NSString stringWithFormat:@"%@/%@", [faceParts objectAtIndex:0], ([faceParts count] > 1) ? [faceParts objectAtIndex:1] : 0];
					if (![vertexCombinations containsObject:faceKey])
						[vertexCombinations addObject:faceKey];
                    */
                     
				}
			}
			
		}
        NSLog(@"Verts: %i",vertexCount);
        NSLog(@"Textu: %i",textureCoordsCount);
        NSLog(@"Faces: %i",faceCount);
        NSLog(@"index: %i",[indexArray count]);
        
        //*************************
        //***** Fill arrays with data from file
        //*************************
        
        GLfloat AlunVertexData[vertexCount*3];
        GLfloat AlunNormalData[vertexCount*3];
        GLfloat AlunTexData[textureCoordsCount*2];
       
        
        //faces
        GLuint objFaceIndicesSize = faceCount*3;
        GLuint objFaceVertIndices[objFaceIndicesSize];
        //GLuint objFaceTextIndices[objFaceIndicesSize];
        

        
        int vertexCountx3 = 0;
        int normCountx3 = 0;
        int texCountx2 = 0;
        int faceCountx3 = 0;
        for (NSString * line in lines)
		{
            if ([line hasPrefix:@"v "])
			{
				NSString *lineTrunc = [line substringFromIndex:2];
				NSArray *lineVertices = [lineTrunc componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                
                AlunVertexData[vertexCountx3++] = [[lineVertices objectAtIndex:0] floatValue];
                AlunVertexData[vertexCountx3++] = [[lineVertices objectAtIndex:1] floatValue];
                AlunVertexData[vertexCountx3++] = [[lineVertices objectAtIndex:2] floatValue];
			}
            else if ([line hasPrefix: @"vn "])
			{
				NSString *lineTrunc = [line substringFromIndex:3];
				NSArray *lineNorms = [lineTrunc componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                AlunNormalData[normCountx3++] = [[lineNorms objectAtIndex:0] floatValue];
                AlunNormalData[normCountx3++] = [[lineNorms objectAtIndex:1] floatValue];
                AlunNormalData[normCountx3++] = [[lineNorms objectAtIndex:2] floatValue];
            }
            else if ([line hasPrefix: @"vt "])
			{
				NSString *lineTrunc = [line substringFromIndex:3];
				NSArray *lineCoords = [lineTrunc componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                AlunTexData[texCountx2++] = [[lineCoords objectAtIndex:0] floatValue];
                AlunTexData[texCountx2++] = [[lineCoords objectAtIndex:1] floatValue];
            }
            else if ([line hasPrefix:@"f "])
			{
				NSString *lineTrunc = [line substringFromIndex:2];
				NSArray *faces = [lineTrunc componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                
                for (NSString *oneFace in faces)
				{
                    //separate the face to get individual verts
					NSArray *faceParts = [oneFace componentsSeparatedByString:@"/"];
                    
                    //[mutDictionary setValue:[faceParts objectAtIndex:1] forKey:[faceParts objectAtIndex:0]];
                    
                    //first value is the face index
                    objFaceVertIndices[faceCountx3] = [[faceParts objectAtIndex:0] intValue]-1;
                    //TODO: Check to see if text inds and normal inds exist
                  //  objFaceTextIndices[faceCountx3] = [[faceParts objectAtIndex:1] intValue];
                    
                    //check if 
                    
                    
                    faceCountx3++;
                            
                }
                
            }
            
        }
        
        GLuint newDataBufferSize = [vertexCombinations count];
        GLfloat newDataBuffer[newDataBufferSize*8];
        int newCounter = 0;
        int buffPos = 0;
        for (int i = 0; i < [vertexCombinations count]; i++)
        {
            NSString *pair = [vertexCombinations objectAtIndex:i];
            NSArray *pairParts = [pair componentsSeparatedByString:@"/"];
            int currVertexPos = [[pairParts objectAtIndex:0] intValue]-1;
            int currTextPos = [[pairParts objectAtIndex:1] intValue]-1;
            
            //add three vert coords
            newDataBuffer[buffPos] = AlunVertexData[currVertexPos*3];
            newDataBuffer[buffPos+1] = AlunVertexData[currVertexPos*3+1];
            newDataBuffer[buffPos+2] = AlunVertexData[currVertexPos*3+2];
            //add three normal coords
            
            newDataBuffer[buffPos+3] = 1;
            newDataBuffer[buffPos+4] = 1;
            newDataBuffer[buffPos+5] = 1;
            //add three text coords
            newDataBuffer[buffPos+6] = AlunTexData[currTextPos*2];
            newDataBuffer[buffPos+7] = AlunTexData[currTextPos*2+1];
            
            buffPos+=8;
        }
        
       
        
        //create new indexBuffer
        GLuint newIndexBuffer[faceCount*3];

        for (int i = 0; i < faceCount*3; i+=3)
        {

            newIndexBuffer[i] = [vertexCombinations indexOfObject:[indexArray objectAtIndex:i]];
            newIndexBuffer[i+1] = [vertexCombinations indexOfObject:[indexArray objectAtIndex:i+1]];
            newIndexBuffer[i+2] = [vertexCombinations indexOfObject:[indexArray objectAtIndex:i+2]];

        }
        
                
        //TODO implement situation where there are no normals
        
        
        _indexBufferSize = faceCount*3;
        


        // Make the vertex buffer
        glGenBuffers( 1, &_verticesVBO );
        glBindBuffer( GL_ARRAY_BUFFER, _verticesVBO );
        //glBufferData( GL_ARRAY_BUFFER, sizeof(objDrawBuffer), objDrawBuffer, GL_STATIC_DRAW );
        glBufferData( GL_ARRAY_BUFFER, sizeof(newDataBuffer), newDataBuffer, GL_STATIC_DRAW );
        glBindBuffer( GL_ARRAY_BUFFER, 0 );
        
        // Make the indices buffer
        glGenBuffers( 1, &_indicesVBO );
        glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, _indicesVBO );
        glBufferData( GL_ELEMENT_ARRAY_BUFFER, sizeof(newIndexBuffer), newIndexBuffer, GL_STATIC_DRAW );
        glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, 0 );
        
        // Bind the attribute pointers to the VAO
        GLint attribute;
        GLsizei stride = sizeof(GLfloat) * 8; // 3 vert, 3 normal, 2 texture
        glGenVertexArraysOES( 1, &_VAO );
        glBindVertexArrayOES( _VAO );
        
        glBindBuffer( GL_ARRAY_BUFFER, _verticesVBO );
        
        //Vert positions
        attribute = glGetAttribLocation(_program, "VertexPosition");
        glEnableVertexAttribArray( attribute );
        glVertexAttribPointer( attribute, 3, GL_FLOAT, GL_FALSE, stride, NULL );
        
        // Give the normals to GL to pass them to the shader
        // We will have to add the VertexNormal attribute in the shader
        attribute = glGetAttribLocation(_program, "VertexNormal");
        glEnableVertexAttribArray( attribute );
        glVertexAttribPointer( attribute, 3, GL_FLOAT, GL_FALSE, stride, BUFFER_OFFSET( stride*3/8 ) );
        
        attribute = glGetAttribLocation(_program, "VertexTexCoord0");
        glEnableVertexAttribArray( attribute );
        glVertexAttribPointer( attribute, 2, GL_FLOAT, GL_FALSE, stride, BUFFER_OFFSET( stride*6/8 ) );
        
        glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, _indicesVBO );
        
        glBindVertexArrayOES( 0 );


    }
	return self;
}

- (void)renderWithMV:(GLKMatrix4)modelViewMatrix P:(GLKMatrix4)projectionMatrix
{
    [super renderWithMV:modelViewMatrix P:projectionMatrix];
    
    //apply all transformations
    modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, [self modelMatrix:YES]);
    
    // Bind the VAO and the program
    glBindVertexArrayOES( _VAO );
    glUseProgram( _program );
    
    
    GLint matMV = glGetUniformLocation(_program, "ModelViewMatrix");
    glUniformMatrix4fv(matMV, 1, GL_FALSE, modelViewMatrix.m);
    
    GLint matP = glGetUniformLocation(_program, "ProjectionMatrix");
    glUniformMatrix4fv(matP, 1, GL_FALSE, projectionMatrix.m);
    
    bool success;
    GLKMatrix4 normalMatrix4 = GLKMatrix4InvertAndTranspose(modelViewMatrix, &success);
    if (success) {
        GLKMatrix3 normalMatrix3 = GLKMatrix4GetMatrix3(normalMatrix4);
        GLint matN = glGetUniformLocation(_program, "NormalMatrix");
        glUniformMatrix3fv(matN, 1, GL_FALSE, normalMatrix3.m);
    }
    
    GLint matL = glGetUniformLocation(_program, "LightPosition");
    GLKVector3 l = GLKVector3Make(0.0f , 0.0f, 0.0f);
    glUniformMatrix4fv(matL, 1, GL_FALSE, l.v);
    
    //texture
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(self.texture.target, self.texture.name);
    
    // Draw!
    glDrawElements( GL_TRIANGLES, _indexBufferSize, GL_UNSIGNED_INT, NULL );
    
}


@end
