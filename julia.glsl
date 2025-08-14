#define A 2
#define AA (A*A)
uniform vec3 iMouse;

uniform vec3 iOrigin; // z for zoom
//uniform float iZoom;
uniform vec3 iJO;
uniform vec3 iJC;

uniform int iSuperSet;
uniform int iNumIters;
uniform float iThreshold;

//#define iZoom (iOrigin.z)

float width()   { return iResolution.x; }
float height()  { return iResolution.y; }
float rwidth()  { return iResolution.x / iResolution.y; }
float rheight() { return iResolution.y / iResolution.x; }

#define UVoff(off) pixel2uv(off)
vec2 pixel2uv(vec2 off) {
  return ((gl_FragCoord.xy + off) / iResolution.xy) - 0.5;
}

#define UV pixel2uv()
vec2 pixel2uv() {
  return (gl_FragCoord.xy / iResolution.xy) - 0.5;
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

float hypot (vec2 z) {
  float x = abs(z.x);
  float y = abs(z.y);
  float t = min(x, y);
  x = max(x, y);
  t = t / x;
  return x * sqrt(1.0 + t * t);
}

vec2 cdiv (vec2 a, vec2 b) {
  float e, f;
  float g = 1.0;
  float h = 1.0;
  if( abs(b.x) >= abs(b.y) ) {
    e = b.y / b.x;f = b.x + b.y * e;h = e;
  } else {
    e = b.x / b.y;
    f = b.x * e + b.y;g = e;
  }
  return (a * g + h * vec2(a.y, -a.x)) / f;
}

float cmod (vec2 z) {return hypot(z);}
vec2 csqrt (vec2 z) {float t = sqrt(2.0 * (cmod(z) + (z.x >= 0.0 ? z.x : -z.x)));vec2 f = vec2(0.5 * t, abs(z.y) / t);if (z.x < 0.0) f.xy = f.yx;if (z.y < 0.0) f.y = -f.y;return f;}

vec2 csqr(vec2 z) {
  return vec2(z.x*z.x - z.y*z.y, 2.0*z.x*z.y);
}


vec2 cpow(vec2 c, float exponent)
{
    if (abs(c.x) < 1e-5 && abs(c.y) < 1e-5) {
        return vec2(0,0);
    }

    float cAbs = length(c);
    vec2  cLog = vec2(log(cAbs), atan(c.y,c.x));
    vec2  cMul = exponent*cLog;
    float expReal = exp(cMul.x);
    return vec2(expReal*cos(cMul.y), expReal*sin(cMul.y));
}


vec2 j(vec2 z, vec2 c) {
  //return csqr(z) + c;
  
  return cpow(z, 5.0) + c;
  
  //return cpow(z, 3.0-z.y) + c;
  //return csqrt(cdiv((vec2(z.x*z.x - z.y*z.y, 2.0*z.x*z.y) + c - vec2(1.0,0.0)), (2.0*z + c - vec2(2.0,0.0))));
  //return csqrt(cdiv((vec2(z.x*z.x - z.y*z.y, 2.0*z.x*z.y) + c - vec2(1.0,1.0)), (2.0*z + c - vec2(2.0,2.0))));
  //return csqrt(cdiv((vec2(z.x*z.x - z.y*z.y - 1.0, 2.0*z.x*z.y) + c), (1.9*z + c - vec2(2.0,0.0))));
  //return vec2(z.x*z.x - z.y*z.y, 2.0*z.x*z.y) + vec2(c.x*c.x - c.y*c.y, 2.0*c.x*c.y);
}

bool term(vec2 z) {
  return dot(z,z) > iThreshold;
}

vec3 fractal(vec2 z, vec2 c) {
  int i;
  for (i = 0; i < iNumIters; i++) {
    if (term(z)) break;
    z = j(z, c);
    // special fractals:
    //z += 1.0/float(i*i+1)*vec2(c.x*c.x-c.y*c.y,2.0*c.x*c.y);
    //z += 1.0/float(i*i+1)*vec2(c.x*c.x-c.y*c.y,2.0*c.x*c.y);
    //c.xy += 0.1/float(i+1)*vec2(1.01 * c.y, 0.99 * c.x);
    c += 0.1 * csqr(c);
  }
  //z = j(z, c);
  //z = j(z, c);
  return vec3(z, float(i));
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 mandelbrot(vec2 z) {
  return fractal(z, z);
}

// julia zoom = 0.0025 * ethAmount
// e.g. 1000 ETH zoom = 2.5
// 0.1 ETH  = 0.00025

#define MARKER_SIZE 0.005
#define MARKER_CUTOFF 0.8
void draw_marker(vec2 uv, vec4 color, float size, float cutoff) {
  float len = length(uv);
  if (len > size) return;

  if (abs(uv.x) < cutoff || abs(uv.y) < cutoff)
    draw(color);
}

void draw_marker_selection(vec2 uvZoomed) {
 draw_marker(vec2(uvZoomed + iOrigin.xy - iJC.xy) * exp(iOrigin.z), vec4(0.9, 0.9, 0.9, 0.9), 0.015, 0.0015);
}

void draw_marker_origin(vec2 uvZoomed) {
  draw_marker(vec2(uvZoomed + iOrigin.xy) * exp(iOrigin.z), vec4(0.0, 0.0, 0.0, 1.0), 0.005, 0.008);
}

vec3 get_color(float iters) {
  if (float(iNumIters) - iters < 0.1)
    return vec3(0.1);

  float n1 = sin(iters * 0.1) * 0.5 + 0.5;
  float n2 = cos(iters * 0.1) * 0.5 + 0.5;
  float n3 = tan(iters * 0.1) * 0.2 + 0.8;
  return vec3(n1, n2, n3);
}

vec3 get_color2(vec3 res) {
  //float sit = log2(log2(val)/(log2(iThreshold)))/log2(5.0);
  float val = dot(res.z, res.z);
  vec3 col = 1.0 - 0.5*cos( 3.0 + val*0.075*5.0 + vec3(0.0,0.6,1.0));
  return col;
}

void draw_julia(vec2 uv) {
  vec2 uvZoomed = uv / exp(iOrigin.z);
  vec3 col;

  vec3 res = fractal(uv * 2.5 * exp(iJC.z) + iJO.xy, iJC.xy);
  float val = dot(res.xy, res.xy);
  //col = mix(vec3(val, 0.0, val), col, 0.005);
  //col = vec3(val, log(log(res.z)) / log(float(iNumIters)), 0.0);
  //col = hsv2rgb(vec3(val, log(log(res.z)) / log(float(iNumIters)), 1.0));
  //col = hsv2rgb(vec3(val + iTime/33.0, 1.0, 1.0));
  col = get_color2(res);

  draw(vec4(col, 0.9));
}

void draw_mandelbrot(vec2 uv) {
  vec2 uvZoomed = uv / exp(iOrigin.z);
  vec2 muv = uvZoomed + iOrigin.xy;
  vec3 res = mandelbrot(vec2(-abs(muv.x), muv.y));
  float val = dot(res.xy, res.xy);
  
  vec3 col;

  //col = hsv2rgb(vec3(val + iTime/33.0, 1.0, 1.0));
  //col = mix(col, get_color(res.z), 0.8);
  
  col = get_color2(res);
  //vec2 pol = polar(muv);
  
  if (res.z > 10.0)
    col = mix(col, vec3(muv.y, muv.x, 0.0), 0.5);

  draw(col);
  
  // draw markers
  draw_marker_origin(uvZoomed);
  draw_marker_selection(uvZoomed);
  
  if (iSuperSet == 0)
    draw_julia(uvZoomed);
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
    draw_mandelbrot(UV);
    #endif
}

