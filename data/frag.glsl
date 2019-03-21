uniform sampler2D image;
uniform vec2 res;
uniform vec2 pointer;
uniform float time;

vec2 fixsample(vec2 pos)
{
	return vec2(pos.x,1-pos.y);
}

vec2 rotate90(vec2 d)
{
	return vec2(d.y,-d.x);
}

void main()
{
	vec2 d = gl_FragCoord.xy-vec2(pointer.x,res.y-pointer.y);
	float distance = sqrt(dot(d,d));
	vec2 unit = d/distance;
	float bendiness_r = sin(distance/100.-time/5.)*10.;
	float bendiness_g = sin(distance/103.-time/7.)*10.;
	float bendiness_b = sin(distance/106.-time/9.)*10.;
	float wave_intensity = 100./(pow(distance-time*30.,2.)/300.+1.);
	vec2 power = wave_intensity*rotate90(unit);
	gl_FragColor = vec4(vec3(
		texture2D(image,fixsample((gl_FragCoord.xy+bendiness_r*power)/res)).r,
		texture2D(image,fixsample((gl_FragCoord.xy+bendiness_g*power)/res)).g,
		texture2D(image,fixsample((gl_FragCoord.xy+bendiness_b*power)/res)).b
	),1.0);
}
