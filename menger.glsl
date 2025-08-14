#define A 1
#define AA (A*A)

uniform vec3 iOrigin; // z for zoom
//uniform float iZoom;

uniform int iNumIters;

float width()   { return iResolution.x; }
float height()  { return iResolution.y; }
float rwidth()  { return iResolution.x / iResolution.y; }
float rheight() { return iResolution.y / iResolution.x; }

#define UVoff(off) pixel2uv(off)
vec2 pixel2uv(vec2 off) {
  return ((gl_FragCoord.xy + off) / iResolution.xy);
}

#define UV pixel2uv()
vec2 pixel2uv() {
  return (gl_FragCoord.xy / iResolution.xy);
}

void draw(vec4 color) {
  fragColor.xyz = mix(fragColor.xyz, color.xyz, color.w);
}

void draw(vec3 color) {
  fragColor.xyz = color.xyz;
}

vec2 polar(vec2 p) {
  return vec2(length(p), atan(p.y / p.x));
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

bool term(vec2 z) {
  //return abs(z.x-0.5) < 0.5 && abs(z.y-0.5) < 0.5;
  //return abs(z.x) < 1.0 && abs(z.y) < 1.0;
  return z.x > 0.0 && z.x < 1.0 && z.y > 0.0 && z.y < 1.0;
}

// returns distance from menger boundaries
vec3 menger(vec2 z) {
  int i;
  for (i = 0; i < min(5+int(iOrigin.z), iNumIters); i++) {
    // assume z is normalized [0..1]
    // then map to [-1..2]
    // then [0..1] is the hole => return
    z = (3.0 * z) - 1.0;
    if (term(z)) break;
    
    // translate offset back to center
    // and scale again
    vec2 offset = floor(z);
    z -= offset;
  }
  //z = j(z, c);
  //z = j(z, c);
  return vec3(z, float(i));
}

void draw_menger(vec2 uv) {
  // UVs are in range [0..1]
  // move by half just to focus zoom at the center
  vec2 m = (uv - vec2(0.5,0.5)) / exp(iOrigin.z) + (iOrigin.xy + vec2(0.5,0.5));
  float dist = menger(m).z;
  if (!(abs(m.x-0.5) > 0.5 || abs(m.y-0.5) > 0.5)) {
    draw(hsv2rgb(vec3(dist*0.11, 1.0, (iOrigin.z - dist + 4.0) * 0.3)));
  } else {
    draw(vec4(0.5,0.2,0.2, dist / float(iNumIters)));
    draw(vec4(uv.x, uv.y, 0.0, 0.5));
  }
  
  if (dist > 13.0) {
    draw(vec4(0.0, 0.2 + 0.5*sin(2.0*iTime + uv.x + uv.y), 0.0, (iOrigin.z - 13.0 + 2.0) * 0.4));
  }
}

vec3 get_color(float iters) {
  if (float(iNumIters) - iters < 0.1)
    return vec3(0.1);

  float n1 = sin(iters * 0.1) * 0.5 + 0.5;
  float n2 = cos(iters * 0.1) * 0.5 + 0.5;
  float n3 = tan(iters * 0.1) * 0.2 + 0.8;
  return vec3(n1, n2, n3);
}

void main(void) {
    vec3 col;
 
    #if AA > 1
    vec3 sum;
    for (int j = 0; j < A; j++)
    for (int i = 0; i < A; i++) {
      vec2 offset = vec2(i - A/2, j - A/2);
      vec2 uv = UVoff(offset);
      //uv.x *= rwidth(); // fix non-square aspect ratio

      draw_mandelbrot(uv);
      sum += fragColor.xyz;
      fragColor.xyz = vec3(0.0);
    }
    draw(sum / float(AA));
    #else
    draw_menger(UV);
    #endif
}

