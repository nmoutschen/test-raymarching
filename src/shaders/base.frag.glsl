#version 300 es

out highp vec4 pc_fragColor;

precision highp float;
precision highp int;

uniform vec2 resolution;
uniform float time;

const float epsilon = 0.0001;
const float PI = 3.1415926538;
const float fl = 1.0;

const int maxSteps = 50;
const int mandelIter = 15;
const float mandelIterStep = 2.5;
const float cmr2 = 1.5;
const float cfr2 = 3.0;
const float cameraEdges = 7.0;

vec3 rotate(vec3 v, vec3 axis, vec3 origin, float angle) {
  axis = normalize(axis);
  float s = sin(angle);
  float c = cos(angle);
  float oc = 1.0 - c;

  mat4 m = mat4(
		oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
    oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
    oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
		0.0,                                0.0,                                0.0,                                1.0
	);

  return (m * vec4(v - origin, 1.)).xyz + origin;
}

float hue2rgb(float f1, float f2, float hue) {
    if (hue < 0.0)
        hue += 1.0;
    else if (hue > 1.0)
        hue -= 1.0;
    float res;
    if ((6.0 * hue) < 1.0)
        res = f1 + (f2 - f1) * 6.0 * hue;
    else if ((2.0 * hue) < 1.0)
        res = f2;
    else if ((3.0 * hue) < 2.0)
        res = f1 + (f2 - f1) * ((2.0 / 3.0) - hue) * 6.0;
    else
        res = f1;
    return res;
}

vec3 hsl2rgb(vec3 hsl) {
    vec3 rgb;
    
    if (hsl.y == 0.0) {
        rgb = vec3(hsl.z); // Luminance
    } else {
        float f2;
        
        if (hsl.z < 0.5)
            f2 = hsl.z * (1.0 + hsl.y);
        else
            f2 = hsl.z + hsl.y - hsl.y * hsl.z;
            
        float f1 = 2.0 * hsl.z - f2;
        
        rgb.r = hue2rgb(f1, f2, hsl.x + (1.0/3.0));
        rgb.g = hue2rgb(f1, f2, hsl.x);
        rgb.b = hue2rgb(f1, f2, hsl.x - (1.0/3.0));
    }   
    return rgb;
}

float smin(float a, float b, float k) {
  float h = clamp(0.5 + 0.5*(a-b)/k, 0.0, 1.0);
  return mix(a, b, h) - k*h*(1.0-h);
}

void sphereFold(inout vec3 z, inout float dz) {
  float mr2 = cmr2;
  float fr2 = cfr2;

  float r2 = dot(z, z);
  if (r2<mr2) {
    float temp = fr2/mr2;
    z *= temp;
    dz *= temp;
  } else if(r2<fr2) {
    float temp = fr2/r2;
    z *= temp;
    dz *= temp;
  }

  z = rotate(z, vec3(sin(time/200.), 1., 0.), vec3(0.), time/500.);
}

void boxFold(inout vec3 z, inout float dz) {
  z = clamp(z, -fl, fl) * 2.0 - z;

  z = rotate(z, vec3(cos(time/400.), -1., 0.), vec3(0.), time/1000.);
}

float mandelboxSDF(vec3 pos) {
  vec3 offset = pos;
  float dr = 1.0;
  for (int i=0; i < mandelIter; i++) {
      boxFold(pos, dr);
      sphereFold(pos, dr);

      pos = mandelIterStep * pos + offset;
      dr = dr * abs(mandelIterStep) + 1.;
  }

  float r = length(pos);
  return r/abs(dr);
}

float sceneSDF(vec3 pos) {
  return mandelboxSDF(pos);
}

// Normalized position
vec3 normPos(vec3 pos) {
  float r = min(resolution.x, resolution.y);
  return vec3(
    (pos.xy - resolution/2.) / r,
    pos.z
  );
}

void main() {
  vec3 pos = vec3(0., 0., -10.);
  vec3 light = pos;

  // Calculate movement vector
  vec3 nv = normPos(vec3(gl_FragCoord.xy, -1.));
  // nv = vec3(abs(nv.xy), nv.z);
  float angle = abs(mod(atan(nv.x, nv.y), PI*2./cameraEdges) - PI/cameraEdges);
  float radius = length(nv.xy);
  nv = vec3(
    radius * cos(angle),
    radius * sin(angle),
    nv.z
  );
  nv = -normalize(nv);
  float dist = 0.;
  float minDist = 1./0.;

  int i = 0;
  for (; i < maxSteps; i++) {
    dist = sceneSDF(pos);
    minDist = min(minDist, dist);
    if(dist < epsilon) {
      break;
    }
    pos += nv * dist;
  }
  float c1 = 1.-float(i)/float(maxSteps);
  // float c2 = mod(-minDist*8000. + time/500., 1.);
  float c2 = mod(pos.z + time/500., 1.);

  // vec3 color = hsl2rgb(vec3(mod(time/500., 1.), 0.5, 0.75*c2));
  vec3 color = hsl2rgb(vec3(c2, 0.5, 0.75*c1));
  pc_fragColor = vec4(color, 1.);
}