#import "JSONLoaders.h"


@implementation JSONNode



@end

@implementation JSONComponent
@end


@implementation JSONComponentTransform
-(void)loadTransform:(NSDictionary *)input
{
    NSArray *posArray = [input valueForKey:@"position"];
    self.position = GLKVector3Make([[posArray objectAtIndex:0] floatValue],
                             [[posArray objectAtIndex:1] floatValue],
                             [[posArray objectAtIndex:2] floatValue]);
    
    NSArray *rotArray = [input valueForKey:@"rotation"];
    self.rotation = GLKQuaternionMake([[rotArray objectAtIndex:0] floatValue],
                                   [[rotArray objectAtIndex:1] floatValue],
                                   [[rotArray objectAtIndex:2] floatValue],
                                   [[rotArray objectAtIndex:3] floatValue]);
    
    NSArray *scaleArray = [input valueForKey:@"scale"];
    self.scale = GLKVector3Make([[scaleArray objectAtIndex:0] floatValue],
                                   [[scaleArray objectAtIndex:1] floatValue],
                                   [[scaleArray objectAtIndex:2] floatValue]);
}
@end

@implementation JSONComponentMeshRenderer

@end

@implementation JSONComponentCamera
-(void)loadCamera:(NSDictionary *)input
{
    NSArray *upArray = [input valueForKey:@"up"];
    self.up = GLKVector3Make([[upArray objectAtIndex:0] floatValue],
                                   [[upArray objectAtIndex:1] floatValue],
                                   [[upArray objectAtIndex:2] floatValue]);
    
    self.type = [[input valueForKey:@"type"] intValue];
    
    NSArray *centerArray = [input valueForKey:@"center"];
    self.center = GLKVector3Make([[centerArray objectAtIndex:0] floatValue],
                             [[centerArray objectAtIndex:1] floatValue],
                             [[centerArray objectAtIndex:2] floatValue]);
    
    self.near = [[input valueForKey:@"near"] floatValue];
    self.aspect = [[input valueForKey:@"aspect"] floatValue];
    self.fov = [[input valueForKey:@"fov"] floatValue];
    self.frustrum_size = [[input valueForKey:@"frustrum_size"] floatValue];
    
    NSArray *eyeArray = [input valueForKey:@"eye"];
    self.eye = GLKVector3Make([[eyeArray objectAtIndex:0] floatValue],
                                 [[eyeArray objectAtIndex:1] floatValue],
                                 [[eyeArray objectAtIndex:2] floatValue]);
    
    self.far = [[input valueForKey:@"far"] floatValue];

}
@end

@implementation JSONComponentLight
-(void)loadLight:(NSDictionary *)input
{
    self.projective_texture = [input valueForKey:@"projective_texture"];
    
    NSArray *positionArray = [input valueForKey:@"position"];
    self.position = GLKVector3Make([[positionArray objectAtIndex:0] floatValue],
                                [[positionArray objectAtIndex:1] floatValue],
                                [[positionArray objectAtIndex:2] floatValue]);
    
    NSArray *upArray = [input valueForKey:@"up"];
    self.up = GLKVector3Make([[upArray objectAtIndex:0] floatValue],
                                   [[upArray objectAtIndex:1] floatValue],
                                   [[upArray objectAtIndex:2] floatValue]);
    
    self.range_attenuation = [[input valueForKey:@"range_attenuation"] boolValue];
    self.spot_cone = [[input valueForKey:@"spot_cone"] boolValue];
    self.att_start= [[input valueForKey:@"att_start"] floatValue];
    
    NSArray *colorArray = [input valueForKey:@"color"];
    self.color = GLKVector3Make([[colorArray objectAtIndex:0] floatValue],
                             [[colorArray objectAtIndex:1] floatValue],
                             [[colorArray objectAtIndex:2] floatValue]);
    
    self.intensity = [[input valueForKey:@"intensity"] floatValue];
    self.type = [[input valueForKey:@"type"] intValue];
    self.shadow_bias = [[input valueForKey:@"shadow_bias"] floatValue];
    self.linear_attenuation = [[input valueForKey:@"linear_attenuation"] boolValue];
    self.shadowmap_resolution = [[input valueForKey:@"shadowmap_resolution"] intValue];
    
    NSArray *targetArray = [input valueForKey:@"target"];
    self.target = GLKVector3Make([[targetArray objectAtIndex:0] floatValue],
                                [[targetArray objectAtIndex:1] floatValue],
                                [[targetArray objectAtIndex:2] floatValue]);
    
    self.enabled = [[input valueForKey:@"enabled"] boolValue];
    self.near = [[input valueForKey:@"near"] floatValue];
    self.frustrum_size = [[input valueForKey:@"frustrum_size"] floatValue];
    self.target_in_world_coords = [[input valueForKey:@"target_in_world_coords"] boolValue];
    self.att_end = [[input valueForKey:@"att_end"] floatValue];
    self.cast_shadows = [[input valueForKey:@"cast_shadows"] boolValue];
    self.angle_end = [[input valueForKey:@"angle_end"] floatValue];
    self.use_diffuse = [[input valueForKey:@"use_diffuse"] boolValue];
    self.use_specular = [[input valueForKey:@"use_specular"] boolValue];
    self.angle = [[input valueForKey:@"angle"] floatValue];
    self.offset = [[input valueForKey:@"offset"] floatValue];
    self.far = [[input valueForKey:@"far"] floatValue];

}
-(void)addTransformComponent:(NSDictionary *)input
{
    NSArray *posArray = [input valueForKey:@"position"];
    self.position = GLKVector3Make([[posArray objectAtIndex:0] floatValue],
                                   [[posArray objectAtIndex:1] floatValue],
                                   [[posArray objectAtIndex:2] floatValue]);
}
@end

@implementation JSONMaterial
-(void)loadMaterial:(NSDictionary *)input
{
    
    //textures
    NSDictionary *textures = [input valueForKey:@"textures"];
    self.texture_color = [textures valueForKey:@"color"];
    self.texture_irradiance = [textures valueForKey:@"irradiance"];
    self.texture_normal = [textures valueForKey:@"normal"];
    self.texture_specular = [textures valueForKey:@"specular"];

    self.alpha = [[input valueForKey:@"alpha"] floatValue];
    self.velvet_exp= [[input valueForKey:@"velvet_exp"] floatValue];
    
    NSArray *colorArray = [input valueForKey:@"color"];
    self.color = GLKVector3Make([[colorArray objectAtIndex:0] floatValue],
                                [[colorArray objectAtIndex:1] floatValue],
                                [[colorArray objectAtIndex:2] floatValue]);
    
    self.extra_factor = [[input valueForKey:@"extra_factor"] floatValue];
    self.velvet_additive = [[input valueForKey:@"extra_factor"] boolValue];
    self.reflection_factor = [[input valueForKey:@"reflection_factor"] floatValue];
    
    NSArray *velvetArray = [input valueForKey:@"velvet"];
    self.velvet = GLKVector3Make([[velvetArray objectAtIndex:0] floatValue],
                                [[velvetArray objectAtIndex:1] floatValue],
                                [[velvetArray objectAtIndex:2] floatValue]);
    
    NSArray *uvsMatrixArray = [input valueForKey:@"uvs_matrix"];
    self.uvs_matrix = GLKVector4Make([[uvsMatrixArray objectAtIndex:0] floatValue],
                                 [[uvsMatrixArray objectAtIndex:1] floatValue],
                                 [[uvsMatrixArray objectAtIndex:2] floatValue],
                                 [[uvsMatrixArray objectAtIndex:3] floatValue]);
    
    self.specular_gloss = [[input valueForKey:@"specular_gloss"] floatValue];
    self.reflection_fresnel = [[input valueForKey:@"reflection_fresnel"] floatValue];
    
    NSString *blendingValue = (NSString*)[input valueForKey:@"blending"];
    self.blending = MaterialBlendingNormal;
    if ([blendingValue isEqualToString:@"additive"]) self.blending = MaterialBlendingAdditive;
    
    self.backlight_factor = [[input valueForKey:@"backlight_factor"] floatValue];
    self.specular_factor = [[input valueForKey:@"specular_factor"] floatValue];
    self.normalmap_factor = [[input valueForKey:@"normalmap_factor"] floatValue];
    self.specular_ontop = [[input valueForKey:@"specular_ontop"] boolValue];
    
    NSArray *emissiveArray = [input valueForKey:@"emissive"];
    self.emissive = GLKVector3Make([[emissiveArray objectAtIndex:0] floatValue],
                                 [[emissiveArray objectAtIndex:1] floatValue],
                                 [[emissiveArray objectAtIndex:2] floatValue]);
    
    NSArray *ambientArray = [input valueForKey:@"ambient"];
    self.ambient = GLKVector3Make([[ambientArray objectAtIndex:0] floatValue],
                                   [[ambientArray objectAtIndex:1] floatValue],
                                   [[ambientArray objectAtIndex:2] floatValue]);
    
    NSArray *diffuseArray = [input valueForKey:@"diffuse"];
    self.diffuse = GLKVector3Make([[diffuseArray objectAtIndex:0] floatValue],
                                  [[diffuseArray objectAtIndex:1] floatValue],
                                  [[diffuseArray objectAtIndex:2] floatValue]);
    
    NSArray *detailArray = [input valueForKey:@"detail"];
    self.detail = GLKVector3Make([[detailArray objectAtIndex:0] floatValue],
                                  [[detailArray objectAtIndex:1] floatValue],
                                  [[detailArray objectAtIndex:2] floatValue]);
    
    NSArray *extraColorArray = [input valueForKey:@"extra_color"];
    self.extra_color = GLKVector3Make([[extraColorArray objectAtIndex:0] floatValue],
                                 [[extraColorArray objectAtIndex:1] floatValue],
                                 [[extraColorArray objectAtIndex:2] floatValue]);
}
@end

@implementation JSONScene
-(void)loadScene:(NSDictionary *)input
{
    NSArray *ambientArray = [input valueForKey:@"ambient_color"];
    self.ambient_color = GLKVector3Make([[ambientArray objectAtIndex:0] floatValue],
                                      [[ambientArray objectAtIndex:1] floatValue],
                                      [[ambientArray objectAtIndex:2] floatValue]);
    
    self.background_texture = [input valueForKey:@"background_texture"];
    
    NSArray *backgroundColorArray = [input valueForKey:@"background_color"];
    self.background_color = GLKVector3Make([[backgroundColorArray objectAtIndex:0] floatValue],
                                        [[backgroundColorArray objectAtIndex:1] floatValue],
                                        [[backgroundColorArray objectAtIndex:2] floatValue]);
    
    NSLog(@"");
}


@end