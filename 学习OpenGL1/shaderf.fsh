//#extension GL_OES_EGL_image_external : require

//precision mediump float;

varying lowp vec2 varyTextCoord;

uniform sampler2D myTexture;

void main()
{
    
    gl_FragColor = vec4(texture2D(myTexture, varyTextCoord).rgb, texture2D(myTexture, +varyTextCoord+vec2(-0.5, 0)).r);
    
    //gl_FragColor = texture2D(myTexture, varyTextCoord);
}
