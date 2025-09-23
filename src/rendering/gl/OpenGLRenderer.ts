import {mat4, vec4, vec2} from 'gl-matrix';
import Drawable from './Drawable';
import Camera from '../../Camera';
import {gl} from '../../globals';
import ShaderProgram from './ShaderProgram';

// In this file, `gl` is accessible because it is imported above
class OpenGLRenderer {
  geometryColor: vec4;

  constructor(public canvas: HTMLCanvasElement) {
    this.geometryColor = vec4.fromValues(1, 0, 0, 1);
  }

  setClearColor(r: number, g: number, b: number, a: number) {
    gl.clearColor(r, g, b, a);
  }

  setSize(width: number, height: number) {
    this.canvas.width = width;
    this.canvas.height = height;
  }

  clear() {
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
  }

  render(camera: Camera, prog: ShaderProgram, drawables: Array<Drawable>, time: number) {
    let model = mat4.create();
    let viewProj = mat4.create();

    mat4.identity(model);
    mat4.multiply(viewProj, camera.projectionMatrix, camera.viewMatrix);
    prog.setModelMatrix(model);
    prog.setViewProjMatrix(camera.viewMatrix, viewProj);
    prog.setGeometryColor(this.geometryColor);
    let pos4:vec4 = vec4.fromValues(camera.controls.eye[0], camera.controls.eye[1], camera.controls.eye[2], 1.);
    let tar4:vec4 = vec4.fromValues(camera.controls.center[0], camera.controls.center[1], camera.controls.center[2], 1.);
    prog.setEyeCameraTarget(pos4, tar4);
    prog.setTime(time);

    let res = vec2.create();
    res[0] = this.canvas.width;
    res[1] = this.canvas.height;
    prog.setResolution(res);

    for (let drawable of drawables) {
      prog.draw(drawable);
    }
  }
};

export default OpenGLRenderer;
