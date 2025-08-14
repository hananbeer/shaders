var wgl = WebGL2RenderingContext
let typeToSetters = {
  [wgl.FLOAT]: '1f',
  [wgl.FLOAT_VEC2]: '2fv',
  [wgl.FLOAT_VEC3]: '3fv',
  [wgl.FLOAT_VEC4]: '4fv',
  [wgl.INT]: '1i',
  [wgl.INT_VEC2]: '2iv',
  [wgl.INT_VEC3]: '3iv',
  [wgl.INT_VEC4]: '4iv',
}

function ShaderCanvas(canvas)
{
    this.mCanvas = canvas;
    
    this.mState = {}
    this.mUniforms = {}

    this.mXres = this.mCanvas.offsetWidth / 1;
    this.mYres = this.mCanvas.offsetHeight / 1.0;
    this.mRatio = this.mXres / this.mYres;

    // IMPORTANT NOTE: canvas resolution is based on these attributes
    // must set these to the element size to avoid rescaled (and aliased) resolutions!
    this.mCanvas.width = this.mXres;
    this.mCanvas.height = this.mYres;

    this.mGL = piCreateGlContext(this.mCanvas, false, false, false, false)
    if(!this.mGL) {
        console.error('failed to create WebGL context!')
        return;
    }

    console.log("Rendering resolution: " + this.mXres + " x " + this.mYres);

    this.mRenderer = new piRenderer();

    if(!this.mRenderer.Initialize(this.mGL)) {
        console.error('failed to initialize renderer!')
        return;
    }
}

ShaderCanvas.prototype.Init = function (fragSource) {

    var error;
    //this.mShader = this.mRenderer.CreateShader(vsSource(), fsSource(), error);
    var vs = vsSource()
    var fs = fsSourceHeader() + fragSource // fsSource()

    this.mShader = this.mRenderer.CreateShader(vs, fs, error);
    if (this.mShader.mResult === false) {
        console.log(this.mShader.mInfo);
        return false;
    }

    // TODO: monitor size changes..
    this.mRenderer.SetViewport( [0, 0, this.mXres, this.mYres ] );
    this.mState['iResolution'] = [this.mXres, this.mYres, 0.0];
    
    // TODO: confirm it's okay to set these only during init?
    this.mRenderer.AttachShader(this.mShader);
    this.mRenderer.SetRenderTarget(null);
    this.mRenderer.SetState(this.mRenderer.RENDSTGATE.CULL_FACE, false);
    this.mRenderer.SetState(this.mRenderer.RENDSTGATE.DEPTH_TEST, false);
    this.mRenderer.SetWriteMask(true, false, false, false, false);
    
    this.mFullScreenVerts = this.mRenderer.GetAttribLocation(this.mShader, "iPosition");
    
    this.LoadState()

    return true;
}

ShaderCanvas.prototype.LoadState = function() {
  let program = this.mShader.mProgram
  let gl = this.mGL
  let count = gl.getProgramParameter(program, gl.ACTIVE_UNIFORMS)
  for (let i = 0; i < count; i++) {
    let info = gl.getActiveUniform(program, i)

    let funcName = 'uniform' + typeToSetters[info.type]
    info.id = i
    info.loc = gl.getUniformLocation(program, info.name)
    //info.set = (val) => func(info.loc, val)
    info.setterName = funcName

    this.mUniforms[i] = info
    this.mUniforms[info.name] = info

    //console.log('name:', info.name, 'type:', info.type, 'size:', info.size);
  }

  return count
}

ShaderCanvas.prototype.StartRendering = function() {  
    var me = this;

    // render
    var to = performance.now();
    var fpsFrame = 0;
    var fpsTo = performance.now();
    function dorender()
    {
        var time = performance.now();

        let iTime = (time - to) / 1000.0
        me.mState['iTime'] = iTime
        if (!me.Render()) {
          console.error('render went wrong')
          return
        }

        fpsFrame++;
        if( (time - fpsTo) > 1000 )
        {
            var fps = 1000.0 * fpsFrame / (time - fpsTo);
            document.getElementById("fpsCounter").innerHTML = fps.toFixed(1) + " frames per second";
            fpsFrame = 0;
            fpsTo = time;
        }

        requestAnimFrame( dorender );
    }
    
    // first frame
    // (requestAnimFrame is from piWebUtils)
    requestAnimFrame( dorender );
}

//================================================================================================

var vsSource = function()
{
   return "" +

  //"#define HW_PERFORMANCE 1\n"+
  //"#ifdef GL_ES\n" +
  "precision highp float;\n" +
  //"#endif\n"+

  "layout(location=0) in vec2 iPosition;"+

  "void main()"+
  "{"+
      "gl_Position = vec4( iPosition, 0.0, 1.0 );\n"+
  "}";
}

var fsSourceHeader = function()
{
  return "" +

  //"#define HW_PERFORMANCE 1\n"+
  //"#ifdef GL_ES\n"+
  "precision highp float;\n"+
  //"#endif\n"+

  "uniform vec3 iResolution;\n"+
  "uniform float iTime;\n"+

  "out vec4 fragColor;\n"+

  "#define PI 3.1415926535897932384626433832795\n"
  // TODO: wrap main() here..
} 

function unit2ndc(p)
{
    return [ -1.1 + 2.2*p[0], -1.0 + 2.0*p[1]];
}

ShaderCanvas.prototype.Render = function()
{
    // --------------- animation

    /*let time = this.mState['iTime']

    if( this.mMouse.mIsMoving )
        this.mLastMoveTime = time;
    this.mMouse.mIsMoving = false;

    var x = this.mMouse.mPos.mX / this.mXres;
    var y = this.mMouse.mPos.mY / this.mYres;
    var p = unit2ndc([x, y]);
    //var a = Math.exp( -2.0*(time - this.mLastMoveTime) );
    var mouse = [p[0], p[1], 0.0]; // a];
    */

    /*
    this.mRenderer.Clear( this.mRenderer.CLEAR.Color, [0.0, 0.0, 0.0, 1.0], 1.0, 0 )

    this.mRenderer.SetBlend( true );
    */
    for (let name in this.mState) {
      let uniform = this.mUniforms[name]
      if (!uniform) {
        //console.warn(`missing uniform for "${name}"`)
        //return false
        continue
      }

      let value = this.mState[name]
      //let loc = this.mGL.getUniformLocation(this.mShader.mProgram, name)
      this.mGL[uniform.setterName](uniform.loc, value)
    }

    // finally, render full-screen triangle
    this.mRenderer.DrawFullScreenTriangle_XY(this.mFullScreenVerts)

    return true
}