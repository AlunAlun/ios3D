//
//  WaveFrontObject.m
//  ios3D
//
//  Created by Alun on 3/27/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import "WaveFrontObject.h"
#import "AssetsSingleton.h"

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
@synthesize groups, dataBufferArray, indexBufferArray;

- (id)initWithPath:(NSString *)path program:(GLuint)program error:(NSError **)error;
{
	
	if ((self = [super init]))
	{
        NSLog(@"Loading obj: %@",path);
        
        
		_program = program;
        
        self.materialDefault = [[Material alloc] init];
        
        //**************************************************
        //* Load file
        //**************************************************
		self.sourceObjFilePath = path;
		NSString *objData = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
		int vertexCount = 0, normalCount = 0, faceCount = 0, textureCoordsCount=0, groupCount = 0, existMatFile = 0, quadTriError = 0;
        
        //**************************************************
        //***** Iterate through file once to discover how many vertices, normals, and faces there are *****//
        //**************************************************
		
		NSArray *lines = [objData componentsSeparatedByString:@"\n"];
		BOOL firstTextureCoords = YES;
		NSMutableArray *vertexCombinations = [[NSMutableArray alloc] init];
        NSMutableArray *indexArray = [[NSMutableArray alloc] init];
  
		for (NSString * line in lines)
		{
			if ([line hasPrefix:@"v "])
				vertexCount++;
            else if ([line hasPrefix:@"vn "])
				normalCount++;
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
                
                
                self.materials = [self getMaterials:mtlPath];
                existMatFile = 1;
			}
			else if ([line hasPrefix:@"g"])
				groupCount++;
			else if ([line hasPrefix:@"f"])
			{

				NSString *faceLine = [line substringFromIndex:2];
				NSArray *faces = [faceLine componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                
                if ([faces count] == 3){ //tris okay no problem
                    faceCount++;
                    for (NSString *oneFace in faces)
                    {
                        [indexArray addObject:oneFace]; // add all three
                        if (![vertexCombinations containsObject:oneFace])
                            [vertexCombinations addObject:oneFace];
                                       
                         
                    }
                }
                else if ([faces count] == 4) //make two tris from quad
                {
                    faceCount+=2;
                    [indexArray addObject:[faces objectAtIndex:0]]; // 0-1-2 0-2-3
                    [indexArray addObject:[faces objectAtIndex:1]];
                    [indexArray addObject:[faces objectAtIndex:2]];
                    
                    [indexArray addObject:[faces objectAtIndex:0]];
                    [indexArray addObject:[faces objectAtIndex:2]];
                    [indexArray addObject:[faces objectAtIndex:3]];
                    for (NSString *oneFace in faces)
                        if (![vertexCombinations containsObject:oneFace])
                            [vertexCombinations addObject:oneFace];
                }
                else quadTriError = 1;
			}
			
		}
        
        //**************************************************
        //***** Check to make sure file is valid and fix bugs
        //**************************************************
        //print some info to console
        NSLog(@"Vert Coords: %i",vertexCount);
        NSLog(@"Norm Coords: %i",normalCount);
        NSLog(@"Texture Coords: %i",textureCoordsCount);
        NSLog(@"Faces: %i",faceCount);
        NSLog(@"Index (should be faces*3): %i",[indexArray count]);
        NSLog(@"Unique Verts: %i",[vertexCombinations count]);
        
        [AssetsSingleton sharedAssets].totalTris+=faceCount;
        
        
        //handle case where there is no mat file
         if (existMatFile == 0)
         {
             self.materials = [self handleNoMaterialFile];
             NSLog(@"There was no material file found, setting default");
         }
        
        //throw errors
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        if (path == nil) // filename is wrong
        {
            [details setValue:@"Error in path to obj file" forKey:NSLocalizedDescriptionKey];
            *error = [NSError errorWithDomain:@"OBJ" code:001 userInfo:details];
            return nil;
        }
        else if (faceCount*3!=[indexArray count])
        {
            [details setValue:@"App doesn't support OBJ file which contains both quads and tris" forKey:NSLocalizedDescriptionKey];
            *error = [NSError errorWithDomain:@"OBJ" code:001 userInfo:details];
            return nil;
        }
        else if (quadTriError == 1)
        {
            [details setValue:@"OBJ file has neither quads nor tris" forKey:NSLocalizedDescriptionKey];
            *error = [NSError errorWithDomain:@"OBJ" code:001 userInfo:details];
            return nil;
        }
        else if (valuesPerCoord !=2)
        {
            [details setValue:@"App only supports UV texture coordinates in OBJ files - vt parameters have more than 2 values" forKey:NSLocalizedDescriptionKey];
            // populate the error object with the details
            *error = [NSError errorWithDomain:@"OBJ" code:002 userInfo:details];
            return nil;
        }


        
        
        
        
        //**************************************************
        //***** Fill arrays with data from file
        //**************************************************
        
        GLfloat RawVertexData[vertexCount*3];
        GLfloat RawNormalData[normalCount*3];
        GLfloat RawTextureData[textureCoordsCount*2];
               
        int vertexCountx3 = 0;
        int normCountx3 = 0;
        int texCountx2 = 0;
        
        for (NSString * line in lines)
		{
            if ([line hasPrefix:@"v "])
			{
				NSString *lineTrunc = [line substringFromIndex:2];
				NSArray *lineVertices = [lineTrunc componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

                RawVertexData[vertexCountx3] = [[lineVertices objectAtIndex:0] floatValue];
                RawVertexData[vertexCountx3+1] = [[lineVertices objectAtIndex:1] floatValue];
                RawVertexData[vertexCountx3+2] = [[lineVertices objectAtIndex:2] floatValue];
                vertexCountx3+=3;
			}
            
            else if ([line hasPrefix: @"vn "])
			{
				NSString *lineTrunc = [line substringFromIndex:3];
				NSArray *lineNorms = [lineTrunc componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                RawNormalData[normCountx3] = [[lineNorms objectAtIndex:0] floatValue];
                RawNormalData[normCountx3+1] = [[lineNorms objectAtIndex:1] floatValue];
                RawNormalData[normCountx3+2] = [[lineNorms objectAtIndex:2] floatValue];
                normCountx3+=3;

            }
            else if ([line hasPrefix: @"vt "])
			{
				NSString *lineTrunc = [line substringFromIndex:3];
				NSArray *lineCoords = [lineTrunc componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                RawTextureData[texCountx2++] = [[lineCoords objectAtIndex:0] floatValue];
                RawTextureData[texCountx2++] = [[lineCoords objectAtIndex:1] floatValue];
            }

            
        }

        
        //**************************************************
        //***** Fill arrays with data from file
        //**************************************************
    
        GLuint dataBufferSize = [vertexCombinations count];
        GLfloat dataBuffer[dataBufferSize*8];
        int buffPos = 0;
        for (int i = 0; i < [vertexCombinations count]; i++)
        {
            NSString *pair = [vertexCombinations objectAtIndex:i];
            NSArray *pairParts = [pair componentsSeparatedByString:@"/"];
            int currVertexPos = [[pairParts objectAtIndex:0] intValue]-1;
            int currTextPos = [[pairParts objectAtIndex:1] intValue]-1;
            int currNormalPos = [[pairParts objectAtIndex:2] intValue]-1;
            
            //add three vert coords
            dataBuffer[buffPos] = RawVertexData[currVertexPos*3];
            dataBuffer[buffPos+1] = RawVertexData[currVertexPos*3+1];
            dataBuffer[buffPos+2] = RawVertexData[currVertexPos*3+2];
            
            //add three normal coords
            dataBuffer[buffPos+3] = RawNormalData[currNormalPos*3];
            dataBuffer[buffPos+4] = RawNormalData[currNormalPos*3+1];;
            dataBuffer[buffPos+5] = RawNormalData[currNormalPos*3+2];;

            //add three text coords
            dataBuffer[buffPos+6] = RawTextureData[currTextPos*2];
            dataBuffer[buffPos+7] = (1-RawTextureData[currTextPos*2+1]);
            
            buffPos+=8;
        }
        
   
        //**************************************************
        //***** Create new index buffer by searching for i/j/k string
        //**************************************************
        
        GLuint indexBuffer[faceCount*3];
        _indexBufferSize = faceCount*3;

        NSTimeInterval bob = [NSDate timeIntervalSinceReferenceDate];

        for (int i = 0; i < faceCount*3; i+=3)
        {

            indexBuffer[i] = [vertexCombinations indexOfObject:[indexArray objectAtIndex:i]];
            indexBuffer[i+1] = [vertexCombinations indexOfObject:[indexArray objectAtIndex:i+1]];
            indexBuffer[i+2] = [vertexCombinations indexOfObject:[indexArray objectAtIndex:i+2]];

        }
        NSTimeInterval bab = [NSDate timeIntervalSinceReferenceDate] - bob;
        NSLog(@"Time to create index buffers %f", bab);
        
        //**************************************************
        //***** Expose buffers for further serialization
        //**************************************************
        self.dataBufferArray = [[NSMutableArray alloc] initWithCapacity:dataBufferSize*8];
        for (int i = 0; i < dataBufferSize*8; i++)
            [self.dataBufferArray addObject:[[NSNumber alloc] initWithFloat:dataBuffer[i]]];
        
        self.indexBufferArray = [[NSMutableArray alloc] initWithCapacity:faceCount*3];
        for (int i = 0; i < dataBufferSize*8; i++)
            [self.indexBufferArray addObject:[[NSNumber alloc] initWithFloat:indexBuffer[i]]];

        
//TODO implement situation where there are no normals
        
        
        //**************************************************
        //***** Fill OpenGL Buffers
        //**************************************************

        // Make the vertex buffer
        glGenBuffers( 1, &_verticesVBO );
        glBindBuffer( GL_ARRAY_BUFFER, _verticesVBO );
        glBufferData( GL_ARRAY_BUFFER, sizeof(dataBuffer), dataBuffer, GL_STATIC_DRAW );
        glBindBuffer( GL_ARRAY_BUFFER, 0 );
        
        // Make the indices buffer
        glGenBuffers( 1, &_indicesVBO );
        glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, _indicesVBO );
        glBufferData( GL_ELEMENT_ARRAY_BUFFER, sizeof(indexBuffer), indexBuffer, GL_STATIC_DRAW );
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
    GLKVector3 l = GLKVector3Make(100.0f , 300.0f, 300.0f);
    glUniform3f(matL, l.x, l.y, l.z);
    
    GLint lightIntensityUniform = glGetUniformLocation(_program, "LightIntensity");
    glUniform1f(lightIntensityUniform, 1.3);
    
    GLint diffuseUniform = glGetUniformLocation(_program, "matDiffuse");
    glUniform4f(diffuseUniform, self.materialDefault.diffuse.r, self.materialDefault.diffuse.g, self.materialDefault.diffuse.b, 1.0f);
    
    GLint ambientUniform = glGetUniformLocation(_program, "matAmbient");
    glUniform4f(ambientUniform, self.materialDefault.ambient.r, self.materialDefault.ambient.g, self.materialDefault.ambient.b, 1.0f);
    
    GLint specularUniform = glGetUniformLocation(_program, "matSpecular");
    glUniform4f(specularUniform, self.materialDefault.specular.r, self.materialDefault.specular.g, self.materialDefault.specular.b, 1.0f);
    
    GLint shininessUniform = glGetUniformLocation(_program, "matShininess");
    glUniform1f(shininessUniform, self.materialDefault.shininess);
    
    GLint baseImageLoc = glGetUniformLocation(_program, "TextureSampler");
    glUniform1i(baseImageLoc, 0); //Texture unit 0 is for base images.
    

    GLint detailImageLoc = glGetUniformLocation(_program, "DetailSampler");
    glUniform1i(detailImageLoc, 2); //Texture unit 0 is for base images.
    
    GLint detailBool = glGetUniformLocation(_program, "UseDetail");
    
    //texture
    glActiveTexture(GL_TEXTURE0 + 0);
    glBindTexture(self.materialDefault.texture.target, self.materialDefault.texture.name);
    
    
    if (self.materialDefault.textureDetail != nil)
    {
        glActiveTexture(GL_TEXTURE0 + 2);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
        glBindTexture(self.materialDefault.textureDetail.target, self.materialDefault.textureDetail.name);
        glUniform1i(detailBool,1);
    }
    else
        glUniform1i(detailBool,0);
    
    
    //glBindTexture(self.texture.target, self.texture.name);
    /*__block Material *m;
    [self.materials enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        m = obj;
    }];*/
    


    
    // Draw!
    glDrawElements( GL_TRIANGLES, _indexBufferSize, GL_UNSIGNED_INT, NULL );
    
    
}

- (NSMutableDictionary*)handleNoMaterialFile
{
    NSMutableDictionary *allMaterials = [[NSMutableDictionary alloc] init];
    
    //**************************************************
    //***** Set default material
    //**************************************************
    Material *defaultMat = [[Material alloc] init];
    defaultMat.name = @"default";
    [allMaterials setObject:defaultMat forKey:defaultMat.name];
    return allMaterials;
}


- (NSMutableDictionary*)getMaterials:(NSString*)fileName
{
    NSMutableDictionary *allMaterials = [[NSMutableDictionary alloc] init];
    
    //**************************************************
    //***** Set default material
    //**************************************************
    Material *defaultMat = [[Material alloc] init];
    defaultMat.name = @"default";
    [allMaterials setObject:defaultMat forKey:defaultMat.name];
    
    //**************************************************
    //***** Set default material
    //**************************************************
	NSString *mtlData = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:nil];
	NSArray *mtlLines = [mtlData componentsSeparatedByString:@"\n"];
	// Can't use fast enumeration here, need to manipulate line order
	for (int i = 0; i < [mtlLines count]; i++)
	{
        NSString *line = [mtlLines objectAtIndex:i];
		if ([line hasPrefix:@"newmtl"]) // Start of new material
		{
            // Determine start of next material
			int mtlEnd = -1;
			for (int j = i+1; j < [mtlLines count]; j++)
			{
				NSString *innerLine = [mtlLines objectAtIndex:j];
				if ([innerLine hasPrefix:@"newmtl"])
				{
					mtlEnd = j-1;
					
					break;
				}
                
			}
			if (mtlEnd == -1)
				mtlEnd = [mtlLines count]-1;
            
            //now parse current mtl
            Material *material = [[Material alloc] init];
            for (int j = i; j <= mtlEnd; j++)
			{
				NSString *parseLine = [mtlLines objectAtIndex:j];
                if ([parseLine hasPrefix:@"newmtl "])
					material.name = [parseLine substringFromIndex:7];
                else if ([parseLine hasPrefix:@"Ns "])
					material.shininess = [[parseLine substringFromIndex:3] floatValue];
				else if ([parseLine hasPrefix:@"Ka spectral"]) // Ignore, don't want consumed by next else
				{
					
				}
				else if ([parseLine hasPrefix:@"Ka "])  // CIEXYZ currently not supported, must be specified as RGB
				{
					NSArray *colorParts = [[parseLine substringFromIndex:3] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    material.ambient = GLKVector4Make([[colorParts objectAtIndex:0] floatValue], [[colorParts objectAtIndex:1] floatValue], [[colorParts objectAtIndex:2] floatValue], 1.0);
				}
				else if ([parseLine hasPrefix:@"Kd "])
				{
					NSArray *colorParts = [[parseLine substringFromIndex:3] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
					material.diffuse =  GLKVector4Make([[colorParts objectAtIndex:0] floatValue], [[colorParts objectAtIndex:1] floatValue], [[colorParts objectAtIndex:2] floatValue], 1.0);
				}
				else if ([parseLine hasPrefix:@"Ks "])
				{
					NSArray *colorParts = [[parseLine substringFromIndex:3] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
					material.specular =  GLKVector4Make([[colorParts objectAtIndex:0] floatValue], [[colorParts objectAtIndex:1] floatValue], [[colorParts objectAtIndex:2] floatValue], 1.0);
                }
                else if ([parseLine hasPrefix:@"map_Kd "])
				{
                    NSString *texName = [parseLine substringFromIndex:7];
					NSString *baseName = [[texName componentsSeparatedByString:@"."] objectAtIndex:0];
                    NSString *fileType = [[texName componentsSeparatedByString:@"."] objectAtIndex:1];
                    
                    [material loadTexture:baseName ofType:fileType];
                    //assign this material as the default
                    self.materialDefault = material;
                }
            }

            //add material to dictionary
            [allMaterials setObject:material forKey:material.name];
        }
    }

    return allMaterials;
}

- (Material*)getDefaultMaterial
{
    return [self.materials objectForKey:@"default"];
}

- (Material*)getMaterialCalled:(NSString*)matName
{
    return [self.materials objectForKey:@"default"];
}


@end
