#version 300 es

out highp vec4 pc_fragColor;

precision highp float;
precision highp int;

uniform vec2 resolution;
uniform float time;

// X/Y/Z/R
const vec4 spheres[] = vec4[](
  vec4(0., 0., 100., 20.),
  vec4(-20., 0., 100., 10.),
  vec4(+20., 0., 100., 10.)
);

vec4 getColor(vec2 pos) {
  return mod(vec4(
    pos.x / 100.,
    pos.y / 100.,
    pos.x / 100.,
    1.
  ), 1.);
}

mat4 rotation3d(vec3 axis, float angle) {
  axis = normalize(axis);
  float s = sin(angle);
  float c = cos(angle);
  float oc = 1.0 - c;

  return mat4(
		oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
    oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
    oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
		0.0,                                0.0,                                0.0,                                1.0
	);
}

vec3 rotate(vec3 point, float angle) {
  vec3 c = point - vec3(0., 0., 100.);
  return (rotation3d(vec3(0., 1., 0.75), angle) * vec4(c, 1.)).xyz + vec3(0., 0., 100.);
}

float getDist(vec3 pos) {
  float dist = 1./0.;
  for(int i = 0; i < spheres.length(); i++) {
    vec4 sphere = vec4(
      rotate(spheres[i].xyz, time/100.),
      spheres[i].w
    );
    dist = min(dist, distance(pos, sphere.xyz) - sphere.w);
  }
  return dist;
}

float minDist(vec3 pos) {
  vec3 nVec = normalize(pos);
  vec3 curPos = pos;
  float step = 0.;
  float minDist = 1./0.;
  for (int i = 0; i < 50; i++) {
    float dist = getDist(curPos);
    if (dist <= 0.001) {
      return 0.;
    }

    if (minDist > dist) {
      minDist = dist;
    }
    curPos += dist * nVec;
  }

  return minDist;
}

vec3 normPos(vec3 pos) {
  float minR = max(resolution.x, resolution.y);
  return vec3(
    (pos.xy - resolution/2.) / minR,
    pos.z
  );
}

void main() {
  vec3 pos = normPos(gl_FragCoord.xyz);
  float dist = minDist(pos);
  if (dist <= 0.) {
    pc_fragColor = vec4(1., 0., 0., 1.);
  } else if (dist < 1.) {
    pc_fragColor = vec4(1.-vec3(dist), 1.);
  } else {
    pc_fragColor = vec4(0., 0., 0., 1.);
  }
}