import {vec4, mat4, vec2} from 'gl-matrix';
import Drawable from './Drawable';
import {gl} from '../../globals';

var activeProgram: WebGLProgram = null;

export class Shader {
  shader: WebGLShader;

  constructor(type: number, source: string) {
    this.shader = gl.createShader(type);
    gl.shaderSource(this.shader, source);
    gl.compileShader(this.shader);

    if (!gl.getShaderParameter(this.shader, gl.COMPILE_STATUS)) {
      throw gl.getShaderInfoLog(this.shader);
    }
  }
};

class ShaderProgram {
  prog: WebGLProgram;

  attrPos: number;
  attrNor: number;
  attrCol: number;

  unifModel: WebGLUniformLocation;
  unifModelInvTr: WebGLUniformLocation;
  unifViewProj: WebGLUniformLocation;
  unifColor: WebGLUniformLocation;
  unifResolution: WebGLUniformLocation;
  unifView :  WebGLUniformLocation;
  unifViewInv :  WebGLUniformLocation;
  unifEye :  WebGLUniformLocation;
  unifCameraTarget :  WebGLUniformLocation;
  unifTime :  WebGLUniformLocation;
  unifFlameDir :  WebGLUniformLocation;
  unifFlameSize :  WebGLUniformLocation;
  unifFlameBurst :  WebGLUniformLocation;
  unifBurstSpeed :  WebGLUniformLocation;
  unifWindSpeed :  WebGLUniformLocation;
  unifBrightness : WebGLUniformLocation;

  constructor(shaders: Array<Shader>) {
    this.prog = gl.createProgram();

    for (let shader of shaders) {
      gl.attachShader(this.prog, shader.shader);
    }
    gl.linkProgram(this.prog);
    if (!gl.getProgramParameter(this.prog, gl.LINK_STATUS)) {
      throw gl.getProgramInfoLog(this.prog);
    }

    this.attrPos = gl.getAttribLocation(this.prog, "vs_Pos");
    this.attrNor = gl.getAttribLocation(this.prog, "vs_Nor");
    this.attrCol = gl.getAttribLocation(this.prog, "vs_Col");
    this.unifModel      = gl.getUniformLocation(this.prog, "u_Model");
    this.unifModelInvTr = gl.getUniformLocation(this.prog, "u_ModelInvTr");
    this.unifViewProj   = gl.getUniformLocation(this.prog, "u_ViewProj");
    this.unifColor      = gl.getUniformLocation(this.prog, "u_Color");
    this.unifResolution = gl.getUniformLocation(this.prog, "u_Resolution");
    this.unifView = gl.getUniformLocation(this.prog, "u_View");
    this.unifViewInv = gl.getUniformLocation(this.prog, "u_ViewInv");
    this.unifEye = gl.getUniformLocation(this.prog, "u_Eye");
    this.unifCameraTarget = gl.getUniformLocation(this.prog, "u_CameraTarget");
    this.unifTime = gl.getUniformLocation(this.prog, "u_Time");
    this.unifFlameDir = gl.getUniformLocation(this.prog, "u_FlameDir");
    this.unifFlameSize = gl.getUniformLocation(this.prog, "u_FlameSize");
    this.unifFlameBurst = gl.getUniformLocation(this.prog, "u_FlameBurst");
    this.unifBurstSpeed = gl.getUniformLocation(this.prog, "u_BurstSpeed");
    this.unifWindSpeed = gl.getUniformLocation(this.prog, "u_WindSpeed");
    this.unifBrightness = gl.getUniformLocation(this.prog, "u_Brightness");
  }

  use() {
    if (activeProgram !== this.prog) {
      gl.useProgram(this.prog);
      activeProgram = this.prog;
    }
  }
  setFlameProp(dir:vec4, size: number, burst: number, burstSpeed: number, windSpeed: number, brightness: number){
    this.use();
    if(this.unifFlameDir!==-1){
      gl.uniform4fv(this.unifFlameDir, dir);
    }
    if(this.unifFlameSize!==-1){
      gl.uniform1f(this.unifFlameSize, size);
    }
    if(this.unifFlameBurst!==-1){
      gl.uniform1f(this.unifFlameBurst, burst);
    }
    if(this.unifBurstSpeed!==-1){
      gl.uniform1f(this.unifBurstSpeed, burstSpeed);
    }
    if(this.unifWindSpeed!==-1){
      gl.uniform1f(this.unifWindSpeed, windSpeed);
    }
    if(this.unifBrightness!==-1){
      gl.uniform1f(this.unifBrightness, brightness);
    }
  }

  setEyeCameraTarget(eye:vec4, target:vec4){
    this.use();
    if(this.unifEye!==-1){
      gl.uniform4fv(this.unifEye, eye);
    }
    if(this.unifCameraTarget!==-1){
      gl.uniform4fv(this.unifCameraTarget, target);
    }
  }

  setModelMatrix(model: mat4) {
    this.use();
    if (this.unifModel !== -1) {
      gl.uniformMatrix4fv(this.unifModel, false, model);
    }

    if (this.unifModelInvTr !== -1) {
      let modelinvtr: mat4 = mat4.create();
      mat4.transpose(modelinvtr, model);
      mat4.invert(modelinvtr, modelinvtr);
      gl.uniformMatrix4fv(this.unifModelInvTr, false, modelinvtr);
    }
  }

  setViewProjMatrix(v:mat4, vp: mat4) {
    this.use();
    if (this.unifViewProj !== -1) {
      gl.uniformMatrix4fv(this.unifViewProj, false, vp);
    }
    if(this.unifView!==-1){
      gl.uniformMatrix4fv(this.unifView, false, v);
      let vinv : mat4 = mat4.create();
      mat4.invert(vinv, v);
      gl.uniformMatrix4fv(this.unifViewInv, false, vinv);
    }
  }

  setGeometryColor(color: vec4) {
    this.use();
    if (this.unifColor !== -1) {
      gl.uniform4fv(this.unifColor, color);
    }
  }

  setResolution(res: vec2) {
    this.use();
    if (this.unifResolution !== -1) {
      gl.uniform2iv(this.unifResolution, res);
    }
  }

  setTime(t:number){
    this.use();
    if(this.unifTime!==-1){
      //console.log("t "+t);
      gl.uniform1f(this.unifTime, t);
    }
  }

  draw(d: Drawable) {
    this.use();

    if (this.attrPos != -1 && d.bindPos()) {
      gl.enableVertexAttribArray(this.attrPos);
      gl.vertexAttribPointer(this.attrPos, 4, gl.FLOAT, false, 0, 0);
    }

    if (this.attrNor != -1 && d.bindNor()) {
      gl.enableVertexAttribArray(this.attrNor);
      gl.vertexAttribPointer(this.attrNor, 4, gl.FLOAT, false, 0, 0);
    }

    d.bindIdx();
    gl.drawElements(d.drawMode(), d.elemCount(), gl.UNSIGNED_INT, 0);

    if (this.attrPos != -1) gl.disableVertexAttribArray(this.attrPos);
    if (this.attrNor != -1) gl.disableVertexAttribArray(this.attrNor);
  }
};

export default ShaderProgram;
