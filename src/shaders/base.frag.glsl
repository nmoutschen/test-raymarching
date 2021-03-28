#version 300 es

out highp vec4 pc_fragColor;

precision highp float;
precision highp int;

uniform vec2 resolution;
uniform float time;

const float epsilon = 0.0001;
const int maxSteps = 50;
const vec3 lightColor1 = vec3(1., 0.8359375, 0.6640625);
const vec3 lightColor2 = vec3(1., 0.6640625, 0.8359375);

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

float unionSDF(float distA, float distB) {
  return min(distA, distB);
}

float diffSDF(float distA, float distB) {
  return max(distA, -distB);
}

float intersectSDF(float distA, float distB) {
  return max(distA, distB);
}

// Signed distance to the sphere
float sphereSDF(vec3 vector, float radius) {
  return length(vector) - radius;
}

float boxSDF(vec3 vector, vec3 size) {
  vec3 q = abs(vector) - size;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float smin(float a, float b, float k) {
  float h = clamp(0.5 + 0.5*(a-b)/k, 0.0, 1.0);
  return mix(a, b, h) - k*h*(1.0-h);
}

float sceneSDF(vec3 pos) {
  // pos = mod(pos+100., 200.)-100.;
  return unionSDF(
    -smin(
      sphereSDF(pos, 20.),
      -boxSDF(pos, vec3(20.)),
      5.
    ),
    boxSDF(pos, vec3(5.))
  );
}

vec3 estimateNormal(vec3 p) {
    return normalize(vec3(
        sceneSDF(vec3(p.x + epsilon, p.y, p.z)) - sceneSDF(vec3(p.x - epsilon, p.y, p.z)),
        sceneSDF(vec3(p.x, p.y + epsilon, p.z)) - sceneSDF(vec3(p.x, p.y - epsilon, p.z)),
        sceneSDF(vec3(p.x, p.y, p.z  + epsilon)) - sceneSDF(vec3(p.x, p.y, p.z - epsilon))
    ));
}

// Normalized position
vec3 normPos(vec3 pos) {
  float minR = min(resolution.x, resolution.y);
  return vec3(
    (pos.xy - resolution/2.) / minR,
    pos.z
  );
}

void main() {
  vec3 pos = vec3(0., 0., -100.);
  pos = rotate(pos, vec3(0., 1., 1.), vec3(0.), time/500.);
  vec3 light = pos;
  vec3 nv = -normalize(normPos(vec3(gl_FragCoord.xy, -1.)));
  nv = rotate(nv, vec3(0., 1., 1.), vec3(0.), time/500.);
  float dist = 0.;
  float minDist = 1./0.;

  vec3 newLight1 = rotate(light, vec3(0., 1., 0.), vec3(0., 0., 0.), time/100.);
  vec3 newLight2 = rotate(newLight1, vec3(0., 0., 1.), vec3(0., 0., 0.), 3.1415926535);

  for (int i = 0; i < maxSteps; i++) {
    dist = sceneSDF(pos);
    if(dist < epsilon) {
      vec3 color = max(
        lightColor1 * dot(normalize(newLight1 - pos), normalize(estimateNormal(pos))),
        lightColor2 * dot(normalize(newLight2 - pos), normalize(estimateNormal(pos)))
      );
      pc_fragColor = vec4(color/2., 1.);
      return;
    }
    minDist = min(minDist, dist);
    pos = mod(pos + nv * dist + 100., 200.)-100.;
  }
  float c = clamp(1.-minDist, 0., 1.);
  pc_fragColor = vec4(max(lightColor1*c, lightColor2/8.), 1.);
}