
// Fragment shader

varying highp vec4 pos;

highp vec4 PackDepth32(highp float depth)
{
    const highp vec4 bitSh = vec4( 256*256*256, 256*256, 256, 1);
    const highp vec4 bitMsk = vec4( 0, 1.0/256.0, 1.0/256.0, 1.0/256.0);
    highp vec4 comp;
    comp	= depth * bitSh;
    comp	= fract(comp);
    comp	-= comp.xxyz * bitMsk;
    return comp;
}

void main(void)
{

    gl_FragColor.a = 1.0;
    gl_FragColor.rgb=vec3(gl_FragCoord.z);
    
    //highp float depth = pos.z / pos.w;
    //gl_FragColor = PackDepth32(depth * 0.5 + 0.5);
    
}