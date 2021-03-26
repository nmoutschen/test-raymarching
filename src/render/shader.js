import {
  Camera, Mesh, PlaneGeometry, RawShaderMaterial, Scene,
} from 'three';

import baseVertShader from '@/shaders/base.vert.glsl';
import baseFragShader from '@/shaders/base.frag.glsl';

export default class ShaderScene {
  constructor({
    vertexShader = baseVertShader,
    fragmentShader = baseFragShader,
    uniforms = {
    },
  } = {}) {
    this.uniforms = uniforms;

    this.camera = new Camera();
    this.camera.position.z = 1;

    this.scene = new Scene();

    const material = new RawShaderMaterial({
      uniforms: this.uniforms,
      vertexShader,
      fragmentShader,
    });

    const mesh = new Mesh(new PlaneGeometry(2, 2), material);
    this.scene.add(mesh);
  }

  render(renderer) {
    renderer.setRenderTarget(null);
    renderer.render(this.scene, this.camera);
  }
}
