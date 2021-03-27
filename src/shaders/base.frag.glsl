#version 300 es

out highp vec4 pc_fragColor;

precision highp float;
precision highp int;

uniform vec2 resolution;
uniform float time;

const float epsilon = 0.0001;
const int maxSteps = 50;
const vec3 light = vec3(-100., 50., 0.);
const vec4 sphere = vec4(0., 0., 100., 30.);

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

float sceneSDF(vec3 pos) {
  return diffSDF(
    sphereSDF(pos - sphere.xyz, sphere.w),
    boxSDF(pos - vec3(0., 20., 100.), vec3(20., 30., 30.))
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
  float minR = max(resolution.x, resolution.y);
  return vec3(
    (pos.xy - resolution/2.) / minR,
    pos.z
  );
}

void main() {
  vec3 pos = normPos(gl_FragCoord.xyz);
  vec3 nv = normalize(pos);
  float dist = 0.;
  float minDist = 1./0.;

  vec3 newLight = rotate(light, vec3(0., 1., 0.), vec3(0., 0., 100.), time/100.);

  for (int i = 0; i < maxSteps; i++) {
    dist = sceneSDF(pos);
    if(dist < epsilon) {
      float c = dot(normalize(newLight - pos), normalize(estimateNormal(pos)));
      pc_fragColor = vec4(vec3(c), 1.);
      return;
    }
    minDist = min(minDist, dist);
    pos += nv * dist;
  }
  pc_fragColor = vec4(vec3(1.-minDist), 1.);
}