// Style
import '@/css/style.scss';

// Renderer
import Render from '@/render';

window.onload = () => {
  const render = new Render();
  const updater = (timestamp) => {
    render.render(timestamp);
    requestAnimationFrame(updater);
  };
  updater();

  window.addEventListener('resize', () => {
    render.onResize(
      window.innerWidth,
      window.innerHeight,
    );
  });
};
