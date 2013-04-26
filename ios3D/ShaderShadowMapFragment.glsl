varying highp vec3 v_pos;

void main(){

    gl_FragColor.a = 1.0;
    gl_FragColor.rgb=vec3(pow(gl_FragCoord.z,5.0));
}