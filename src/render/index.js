import {
  Vector2,
  WebGLRenderer,
} from 'three';

import ShaderScene from './shader';

export default class Render {
  constructor({
    domElement = document.body,
    width = window.innerWidth,
    height = window.innerHeight,
  } = {}) {
    // Create the renderer
    this.renderer = new WebGLRenderer();
    this.renderer.setSize(width, height);
    domElement.appendChild(this.renderer.domElement);

    this.uniforms = {
      resolution: {
        type: 'v2', value: new Vector2(width, height),
      },
      time: {
        type: 'float', value: 0.0,
      },
    };

    this.shader = new ShaderScene({
      uniforms: this.uniforms,
    });
  }

  render(timestamp) {
    this.uniforms.time.value = timestamp / 10.0;
    this.shader.render(this.renderer);
  }

  onResize(width, height) {
    this.renderer.setSize(width, height);
    this.uniforms.resolution.value.x = width;
    this.uniforms.resolution.value.y = height;
  }
}
