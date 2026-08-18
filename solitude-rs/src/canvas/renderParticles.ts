export type VictoryPattern = "cascade" | "fountain" | "scatter" | "vortex";

const MAX_PARTICLES = 120;

export class ParticleSystem {
  private count: number = 0;
  private x: Float32Array = new Float32Array(MAX_PARTICLES);
  private y: Float32Array = new Float32Array(MAX_PARTICLES);
  private vx: Float32Array = new Float32Array(MAX_PARTICLES);
  private vy: Float32Array = new Float32Array(MAX_PARTICLES);
  private rotation: Float32Array = new Float32Array(MAX_PARTICLES);
  private vr: Float32Array = new Float32Array(MAX_PARTICLES); // angular velocity
  private life: Float32Array = new Float32Array(MAX_PARTICLES);
  private maxLife: Float32Array = new Float32Array(MAX_PARTICLES);
  private colorIndex: Uint8Array = new Uint8Array(MAX_PARTICLES);

  private colors: string[] = [
    "#ffd700", "#ff5722", "#4caf50", "#2196f3", "#9c27b0", "#e91e63", "#00bcd4"
  ];

  public spawnVictoryPattern(pattern: VictoryPattern, canvasWidth: number, canvasHeight: number) {
    this.count = MAX_PARTICLES;
    const cx = canvasWidth / 2;
    const cy = canvasHeight / 2;

    for (let i = 0; i < MAX_PARTICLES; i++) {
      this.colorIndex[i] = i % this.colors.length;
      this.rotation[i] = Math.random() * Math.PI * 2;
      this.vr[i] = (Math.random() - 0.5) * 0.1;
      this.life[i] = 1.0;
      this.maxLife[i] = 100 + Math.random() * 80;

      switch (pattern) {
        case "cascade":
          // Drop from top with random x and downward velocity
          this.x[i] = Math.random() * canvasWidth;
          this.y[i] = -20 - Math.random() * 200;
          this.vx[i] = (Math.random() - 0.5) * 4;
          this.vy[i] = 2 + Math.random() * 6;
          break;

        case "fountain":
          // Erupt from bottom center upwards
          this.x[i] = cx + (Math.random() - 0.5) * 40;
          this.y[i] = canvasHeight + 10;
          this.vx[i] = (Math.random() - 0.5) * 12;
          this.vy[i] = -12 - Math.random() * 10;
          break;

        case "scatter":
          // Explode out from center
          this.x[i] = cx;
          this.y[i] = cy;
          const angle = Math.random() * Math.PI * 2;
          const speed = 4 + Math.random() * 12;
          this.vx[i] = Math.cos(angle) * speed;
          this.vy[i] = Math.sin(angle) * speed;
          break;

        case "vortex":
          // Spiral in a circular orbit
          const r = 50 + Math.random() * 200;
          const theta = Math.random() * Math.PI * 2;
          this.x[i] = cx + Math.cos(theta) * r;
          this.y[i] = cy + Math.sin(theta) * r;
          this.vx[i] = -Math.sin(theta) * (3 + Math.random() * 3);
          this.vy[i] = Math.cos(theta) * (3 + Math.random() * 3);
          break;

        default:
          this.x[i] = Math.random() * canvasWidth;
          this.y[i] = 0;
          this.vx[i] = 0;
          this.vy[i] = 5;
          break;
      }
    }
  }

  public updateAndRender(ctx: CanvasRenderingContext2D, canvasWidth: number, canvasHeight: number, pattern: VictoryPattern) {
    if (this.count === 0) return;

    const gravity = 0.4;
    const bounceDamping = 0.7;
    const friction = 0.98;

    for (let i = 0; i < this.count; i++) {
      if (this.life[i] <= 0) continue;

      // Update positions
      if (pattern === "cascade" || pattern === "fountain") {
        this.vy[i] += gravity;
        this.x[i] += this.vx[i];
        this.y[i] += this.vy[i];

        // Bounce on bottom
        if (this.y[i] > canvasHeight - 20 && this.vy[i] > 0) {
          this.vy[i] = -this.vy[i] * bounceDamping;
          this.y[i] = canvasHeight - 20;
        }
      } else if (pattern === "scatter") {
        this.vx[i] *= friction;
        this.vy[i] *= friction;
        this.vy[i] += gravity * 0.5;
        this.x[i] += this.vx[i];
        this.y[i] += this.vy[i];
      } else if (pattern === "vortex") {
        const cx = canvasWidth / 2;
        const cy = canvasHeight / 2;
        const dx = this.x[i] - cx;
        const dy = this.y[i] - cy;
        const dist = Math.sqrt(dx * dx + dy * dy);
        if (dist > 5) {
          // Tangential & centripetal force
          this.vx[i] += (-dy / dist) * 0.3 - (dx / dist) * 0.1;
          this.vy[i] += (dx / dist) * 0.3 - (dy / dist) * 0.1;
        }
        this.x[i] += this.vx[i];
        this.y[i] += this.vy[i];
      }

      this.rotation[i] += this.vr[i];
      this.life[i] -= 1 / this.maxLife[i];

      // Draw particle (mini playing card)
      const alpha = Math.max(0, this.life[i]);
      ctx.save();
      ctx.translate(this.x[i], this.y[i]);
      ctx.rotate(this.rotation[i]);
      ctx.globalAlpha = alpha;

      ctx.fillStyle = this.colors[this.colorIndex[i]];
      ctx.beginPath();
      ctx.roundRect(-15, -22, 30, 44, 4);
      ctx.fill();
      ctx.strokeStyle = "#ffffff";
      ctx.lineWidth = 1.5;
      ctx.stroke();

      ctx.restore();
    }
  }

  public clear() {
    this.count = 0;
  }
}
