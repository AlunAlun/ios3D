//
//  AssetsSingleton.m
//  ios3D
//
//  Created by Alun on 4/1/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import "ResourceManager.h"

#import <stdio.h>
#include <map>
#include <string>
#include <vector>

@implementation ResourceManager
@synthesize scene, materials, textures, totalTris, sceneNodes, context, sceneModelMatrix, screenWidth, screenHeight;

static ResourceManager *sharedAssetsSingleton = nil;    // static instance variable

+ (ResourceManager *)resources {
    if (sharedAssetsSingleton == nil) {
        sharedAssetsSingleton = [[super allocWithZone:NULL] init];
    }
    return sharedAssetsSingleton;
}

- (id)init {
    if ( (self = [super init]) ) {
        // your custom initialization
        self.materials = [[NSMutableArray alloc] init];
        self.textures = [[NSMutableArray alloc] init];
        self.sceneNodes = [[NSMutableArray alloc] init];
        self.sceneModelMatrix = GLKMatrix4Identity;
        totalTris = 0;
    }
    return self;
}

- (void)addSceneNode:(Node *)node{
    [self.sceneNodes addObject:node];
}

// Loops all nodes in current scene
-(Node*)getSceneNodeWithName:(NSString *)name
{
    for(Node *n in self.sceneNodes)
        if (n.name == name) return n;
    return nil;
}

+ (Mesh*)WaveFrontOBJLoadMesh:(NSString*)fileName withMaterial:(Material*)mat
{
    NSLog(@"Loading %@",fileName);
    
    //init vars
    int vertexCount = 0, normalCount = 0, faceCount = 0, textureCoordsCount=0, quadTriError = 0, mapCounter = 0;
    GLubyte valuesPerCoord; BOOL firstTextureCoords = YES;
    std::map <std::string, int> mapVertexCombinations; //hashtable for reverse lookup speed
    std::vector<std::string> vecVertexCombinations; //vector for forward lookup speed
    std::vector<std::string> vecIndexArray; //store all face infices

    //get data
    NSString *baseName = [[fileName componentsSeparatedByString:@"."] objectAtIndex:0];
    NSString *fileType = [[fileName componentsSeparatedByString:@"."] objectAtIndex:1];
    NSString *path = [[NSBundle mainBundle] pathForResource:baseName ofType:fileType];
    NSString *objData = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];

    //first loop
    NSArray *lines = [objData componentsSeparatedByString:@"\n"];
    for (NSString * line in lines)
    {

        if ([line hasPrefix:@"v "]) vertexCount++;
        else if ([line hasPrefix:@"vn "]) normalCount++;
        else if ([line hasPrefix:@"vt "])
        {
            textureCoordsCount++;
            if (firstTextureCoords) // count to see how many texture coords there
            {
                firstTextureCoords = NO;
                NSString *texLine = [line substringFromIndex:3];
                NSArray *texParts = [texLine componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                valuesPerCoord = [texParts count];
            }
        }
        else if ([line hasPrefix:@"f"])
        {
            NSString *faceLine = [line substringFromIndex:2];
            NSArray *faces = [faceLine componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if ([faces count] == 3){ //tris okay no problem
                faceCount++;
                for (NSString *oneFace in faces)
                {
                    //not tested!!!!
                    vecIndexArray.push_back([oneFace cStringUsingEncoding:NSUTF8StringEncoding]);
                    std::map<std::string,int>::iterator it = mapVertexCombinations.find([oneFace cStringUsingEncoding:NSUTF8StringEncoding]);
                    if (it == mapVertexCombinations.end())
                    {
                        mapVertexCombinations[[oneFace cStringUsingEncoding:NSUTF8StringEncoding]] = mapCounter;
                        vecVertexCombinations.push_back([oneFace cStringUsingEncoding:NSUTF8StringEncoding]);
                    }
                    mapCounter++;        
                }
            }
            else if ([faces count] == 4) //make two tris from quad
            {
                faceCount+=2;
                // 0-1-2 0-2-3
                vecIndexArray.push_back([[faces objectAtIndex:0] cStringUsingEncoding:NSUTF8StringEncoding]);
                vecIndexArray.push_back([[faces objectAtIndex:1] cStringUsingEncoding:NSUTF8StringEncoding]);
                vecIndexArray.push_back([[faces objectAtIndex:2] cStringUsingEncoding:NSUTF8StringEncoding]);
                vecIndexArray.push_back([[faces objectAtIndex:0] cStringUsingEncoding:NSUTF8StringEncoding]);
                vecIndexArray.push_back([[faces objectAtIndex:2] cStringUsingEncoding:NSUTF8StringEncoding]);
                vecIndexArray.push_back([[faces objectAtIndex:3] cStringUsingEncoding:NSUTF8StringEncoding]);
                for (NSString *oneFace in faces)
                {
                    std::map<std::string,int>::iterator it = mapVertexCombinations.find([oneFace cStringUsingEncoding:NSUTF8StringEncoding]);
                    if (it == mapVertexCombinations.end())
                    {
                        mapVertexCombinations[[oneFace cStringUsingEncoding:NSUTF8StringEncoding]] = mapCounter;
                        mapCounter++;
                        vecVertexCombinations.push_back([oneFace cStringUsingEncoding:NSUTF8StringEncoding]);
                    }
                }
            }
            else quadTriError = 1;
        }
    }
       
    //initialise raw data arrays
    GLfloat RawVertexData[vertexCount*3];
    GLfloat RawNormalData[normalCount*3];
    GLfloat RawTextureData[textureCoordsCount*2];
    int vertexCountx3 = 0;
    int normCountx3 = 0;
    int texCountx2 = 0;
    
    //second loop
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
    
    //Fill final data arrays
    GLuint dataBufferSize = mapVertexCombinations.size();
    GLfloat dataBuffer[dataBufferSize*8];
    int buffPos = 0;
    for (int i = 0; i<vecVertexCombinations.size(); i++)
    {
        
        const char *key = "bob";
        std::string currFace = vecVertexCombinations[i];
        std::map<std::string,int>::iterator it = mapVertexCombinations.find(currFace);
        
        if (it != mapVertexCombinations.end())
            key = it->first.c_str();
        
        NSString *pair = [NSString stringWithCString:key encoding:NSUTF8StringEncoding];
        NSArray *pairParts = [pair componentsSeparatedByString:@"/"];
        int currVertexPos = [[pairParts objectAtIndex:0] intValue]-1; // we substract one because file string is not 0-based
        int currTextPos = [[pairParts objectAtIndex:1] intValue]-1;
        int currNormalPos = [[pairParts objectAtIndex:2] intValue]-1;
        
        //add three vert coords
        dataBuffer[buffPos] = RawVertexData[currVertexPos*3];
        dataBuffer[buffPos+1] = RawVertexData[currVertexPos*3+1];
        dataBuffer[buffPos+2] = RawVertexData[currVertexPos*3+2];
        
        //add three normal coords
        dataBuffer[buffPos+3] = RawNormalData[currNormalPos*3];
        dataBuffer[buffPos+4] = RawNormalData[currNormalPos*3+1];
        dataBuffer[buffPos+5] = RawNormalData[currNormalPos*3+2];
        
        //add three text coords
        dataBuffer[buffPos+6] = RawTextureData[currTextPos*2];
        dataBuffer[buffPos+7] = (1-RawTextureData[currTextPos*2+1]);
        
        buffPos+=8;
    }
    
    //  Create new index buffer by searching for i/j/k string
    GLuint indexBuffer[faceCount*3];
    GLuint indexBufferSize = faceCount*3;

    for (int i = 0; i < faceCount*3; i+=3)
    {
        
        std::map<std::string,int>::iterator it = mapVertexCombinations.find(vecIndexArray[i]);
        if (it != mapVertexCombinations.end())
            indexBuffer[i] = it->second;
        
        it = mapVertexCombinations.find(vecIndexArray[i+1]);
        if (it != mapVertexCombinations.end())
            indexBuffer[i+1] = it->second;
        
        it = mapVertexCombinations.find(vecIndexArray[i+2]);
        if (it != mapVertexCombinations.end())
            indexBuffer[i+2] = it->second;
    }
    
    //push constructed buffers into stl vectors for ease of transport
    GLuint dbSize =dataBufferSize*8;
    std::vector<GLfloat> vecData;
    for(int i=0;i<dbSize;i++)
        vecData.push_back(dataBuffer[i]);
    
    std::vector<GLuint> vecIndex;
    for(int i=0;i<indexBufferSize;i++)
        vecIndex.push_back(indexBuffer[i]);
    
    //increment total tri count
    [ResourceManager resources].totalTris+=faceCount;
    //create new mesh object
    return [[Mesh alloc] initWithDataBuffer:vecData indexBuffer:vecIndex material:mat];
}

@end