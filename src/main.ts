import {vec3, vec4} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import Cube from './geometry/Cube';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

import { AudioController } from './audio';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 5,
  'Load Scene': loadScene, // A function pointer, essentially
  color1: [ 0, 128, 255 ],
  flameSize:1,
  polarity: 0.5,
  BurstSpeed: 1.,
  WindSpeed: 0.2,
  Brightness: 0.5
};
let time: number = 0;
let icosphere: Icosphere;
let square: Square;
let cube: Cube;
let prevTesselations: number = 5;

let audio : AudioController = new AudioController();
var playingAudioIndex = -1;
var htmlButton = document.createElement('button');

const buttonPlayAudio1 = {
  myFunction: function() {
    audio.playAudio(0);
  }
}

const buttonPlayAudio2 = {
  myFunction: function() {
    audio.playAudio(1);
  }
}

const buttonPause = {
  myFunction: function() {
    console.log("Button clicked!");
    // Add any desired functionality here
    audio.pauseAudio();
  }
}

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
  cube = new Cube(vec3.fromValues(0, 0, 0));
  cube.create();
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '50px';
  document.body.appendChild(stats.domElement);
  var clickedDir = vec3.fromValues(0, 1, 0);
  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'tesselations', 0, 8).step(1);
  gui.add(controls, 'Load Scene');

  gui.addColor(controls, 'color1');
  gui.add(controls, "flameSize", 0., 3.).name("Fire Size");
  gui.add(controls, "polarity", 0.0, 0.7).name("Shape");
  gui.add(controls, "BurstSpeed", 0., 5.);
  gui.add(controls, "WindSpeed", 0., 0.75).name("Wind");
  gui.add(controls, "Brightness", 0., 1);
  gui.add(buttonPlayAudio1, "myFunction").name("Play Audio 1");
  gui.add(buttonPlayAudio2, "myFunction").name("Play Audio 2");
  gui.add(buttonPause, "myFunction").name("Pause Audio");
  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  function printMousePos(event:any) {
    const width  = window.innerWidth || document.documentElement.clientWidth || 
    document.body.clientWidth;
    const height = window.innerHeight|| document.documentElement.clientHeight|| 
    document.body.clientHeight;

    console.log(width, height);
    console.log("clientX: " + (event.clientX - width / 2.) +
      " - clientY: " + (event.clientY - height / 2.));
      clickedDir[0] = event.clientX - width / 2.;
      clickedDir[1] = event.clientY - height / 2.;
    
  }

  document.addEventListener("click", printMousePos);
  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);

  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
  ]);

  // This function will be called every frame
  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    if(audio.initialized){
      var amp1 = audio.getAmplitude();
      var amp2 = audio.getLowPassAmp();
      if(amp1>0.1){
        controls.Brightness = amp1*1.5+0.5;
      }
      if(amp2>0.1){
        controls.BurstSpeed = 2.5;
        controls.flameSize = amp2*1.5+1.;
      }
    }
    
    // Update geometry color for lambert shading
    renderer.geometryColor[0] = controls.color1[0] / 256.;
    renderer.geometryColor[1] = controls.color1[1] / 256.;
    renderer.geometryColor[2] = controls.color1[2] / 256.;
    renderer.geometryColor[3] = 1.;
    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();
    }
    var flameDir = vec4.fromValues(clickedDir[0], clickedDir[1], clickedDir[2], 0);
    vec3.normalize(clickedDir, clickedDir);
    lambert.setFlameProp(vec4.fromValues(0, 1, 0, 0), 
      controls.flameSize, 
      controls.polarity, 
      controls.BurstSpeed, 
      controls.WindSpeed,
      controls.Brightness
    );
    renderer.render(camera, lambert, [
      icosphere
      //cube,
      //square
    ], time++);
    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();
  // Start the render loop
  tick();
}

main();
