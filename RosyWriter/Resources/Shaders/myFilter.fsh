
precision mediump float;

varying mediump vec2 coordinate;
uniform sampler2D videoframe;

void main()
{
	vec4 color = texture2D(videoframe, coordinate);
    gl_FragColor.bgra = vec4(vec3(1.0 - color), 1.0);//vec4(color.b, color.g, color.r, color.a);
    
//    float average = (gl_FragColor.r + gl_FragColor.g + gl_FragColor.b) / 3.0;
//    float average = 0.2126 * gl_FragColor.r + 0.7152 * gl_FragColor.g + 0.0722 * gl_FragColor.b;
//    gl_FragColor = vec4(average, average, average, 1.0);

}
