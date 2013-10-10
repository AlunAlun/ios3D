
#import <GLKit/GLKit.h>

typedef enum {
    MaterialBlendingNormal,
    MaterialBlendingAdditive
} MaterialBlendingMode;

typedef enum {
    JSONComponentTypeTransform,
    JSONComponentTypeMesh,
    JSONComponentTypeCamera,
    JSONComponentTypeLight,
    JSONComponentTypeAnnotation
} JSONComponentType;

@interface JSONMaterial : NSObject
@property(nonatomic,assign) GLKVector3 color;
@property(nonatomic,assign) float alpha;
@property(nonatomic,assign) GLKVector3 ambient;
@property(nonatomic,assign) GLKVector3 diffuse;
@property(nonatomic,assign) GLKVector3 emissive;
@property(nonatomic,assign) float backlight_factor;
@property(nonatomic,assign) float specular_factor;
@property(nonatomic,assign) float specular_gloss;
@property(nonatomic,assign) float reflection_factor;
@property(nonatomic,assign) float reflection_fresnel;
@property(nonatomic,assign) GLKVector3 velvet;
@property(nonatomic,assign) float velvet_exp;
@property(nonatomic,assign) bool velvet_additive;
@property(nonatomic,assign) GLKVector3 detail;
@property(nonatomic,assign) GLKVector4 uvs_matrix;
@property(nonatomic,assign) float extra_factor;
@property(nonatomic,assign) GLKVector3 extra_color;
@property(nonatomic,assign) MaterialBlendingMode blending;
@property(nonatomic,assign) float normalmap_factor;
@property(nonatomic,strong) NSString *texture_specular;
@property(nonatomic,strong) NSString *texture_normal;
@property(nonatomic,strong) NSString *texture_color;
@property(nonatomic,strong) NSString *texture_irradiance;
@property(nonatomic,assign) bool specular_ontop;
- (void)loadMaterial:(NSDictionary*)input;
@end

@interface JSONNode : NSObject
@property(nonatomic,strong) NSString *ID;
@property(nonatomic,assign) bool visible;
@property(nonatomic,assign) bool selectable;
@property(nonatomic,assign) bool two_sided;
@property(nonatomic,assign) bool flip_normals;
@property(nonatomic,assign) bool cast_shadows;
@property(nonatomic,assign) bool receive_shadows;
@property(nonatomic,assign) bool ignore_lights;
@property(nonatomic,assign) bool alpha_test;
@property(nonatomic,assign) bool alpha_shadows;
@property(nonatomic,assign) bool depth_test;
@property(nonatomic,assign) bool depth_write;
@property(nonatomic,assign) bool flipnormals;
@property(nonatomic,assign) bool twosided;
@property(nonatomic,strong) NSMutableArray *components;
@property(nonatomic,strong) JSONMaterial *material;
@property(nonatomic,assign) bool isLight;
@property(nonatomic,assign) bool isMesh;
@property(nonatomic,assign) bool isCamera;
- (void)loadNode:(NSDictionary*)input;
@end

@interface JSONComponent : NSObject
@property(nonatomic,assign) JSONComponentType componentType;
@end

@interface JSONComponentAnnotation : JSONComponent
@property(nonatomic,assign) GLKVector3 startPosition;
@property(nonatomic,assign) GLKVector3 endPosition;
@property(nonatomic,strong) NSString *text;
- (void)loadAnnotation:(NSDictionary*)input;
@end

@interface JSONComponentTransform : JSONComponent
@property(nonatomic,assign) GLKVector3 position;
@property(nonatomic,assign) GLKQuaternion rotation;
@property(nonatomic,assign) GLKVector3 scale;
- (void)loadTransform:(NSDictionary*)input;
@end

@interface JSONComponentMeshRenderer: JSONComponent
@property(nonatomic,strong) NSString *mesh;
@property(nonatomic,strong) NSString *lod_mesh;
@end

@interface JSONComponentCamera: JSONComponent
@property(nonatomic,assign) int type;
@property(nonatomic,assign) GLKVector3 eye;
@property(nonatomic,assign) GLKVector3 center;
@property(nonatomic,assign) GLKVector3 up;
@property(nonatomic,assign) float near;
@property(nonatomic,assign) float far;
@property(nonatomic,assign) float aspect;
@property(nonatomic,assign) float fov;
@property(nonatomic,assign) float frustrum_size;
- (void)loadCamera:(NSDictionary*)input;
@end

@interface JSONComponentLight: JSONComponent
@property(nonatomic,assign) GLKVector3 position;
@property(nonatomic,assign) GLKVector3 target;
@property(nonatomic,assign) GLKVector3 up;
@property(nonatomic,assign) bool enabled;
@property(nonatomic,assign) float near;
@property(nonatomic,assign) float far;
@property(nonatomic,assign) float angle;
@property(nonatomic,assign) float angle_end;
@property(nonatomic,assign) bool use_diffuse;
@property(nonatomic,assign) bool use_specular;
@property(nonatomic,assign) bool linear_attenuation;
@property(nonatomic,assign) bool range_attenuation;
@property(nonatomic,assign) bool target_in_world_coords;
@property(nonatomic,assign) float att_start;
@property(nonatomic,assign) float att_end;
@property(nonatomic,assign) float offset;
@property(nonatomic,assign) bool spot_cone;
@property(nonatomic,assign) GLKVector3 color;
@property(nonatomic,assign) float intensity;
@property(nonatomic,assign) bool cast_shadows;
@property(nonatomic,assign) float shadow_bias;
@property(nonatomic,assign) int type; //1= omni, 2=spotLight, 3= directional
@property(nonatomic,assign) int shadowmap_resolution; //1= omni, 2=spotLight, 3= directional
@property(nonatomic,assign) float frustrum_size;
@property(nonatomic,assign) float size;
@property(nonatomic,strong) NSString *projective_texture;
- (void)loadLight:(NSDictionary*)input;
- (void)addTransformComponent:(NSDictionary*)input;
@end



@interface JSONScene : NSObject
@property(nonatomic,assign) GLKVector3 ambient_color;
@property(nonatomic,assign) GLKVector3 background_color;
@property(nonatomic,strong) NSString *background_texture;
@property(nonatomic,strong) NSString *local_repository;
@property(nonatomic,strong) NSMutableArray *nodes;
@property(nonatomic,strong) NSMutableArray *lights;
@property(nonatomic,strong) NSMutableArray *cameras;
- (void)loadScene:(NSDictionary*)input;
@end
