import display from '@ohos.display';
import { ChronTheme } from '../theme/ChronTheme';
import { TimeFormat } from '../services/TimeFormat';

interface SunPalette {
  top: string;
  bottom: string;
  ink: string;
}

interface SunStop {
  hour: number;
  top: string;
  bottom: string;
  ink: string;
}

const SUN_STOPS: SunStop[] = [
  { hour: 0, top: '#0A0B16', bottom: '#020308', ink: '#AAB8E2' },
  { hour: 5, top: '#10101E', bottom: '#04040C', ink: '#C4BADC' },
  { hour: 7, top: '#302034', bottom: '#0C0C1A', ink: '#FFD6A8' },
  { hour: 12, top: '#1A2C4E', bottom: '#0A1022', ink: '#FFF6E8' },
  { hour: 16, top: '#1E2C46', bottom: '#0A0F1E', ink: '#FFEED6' },
  { hour: 19, top: '#3E2432', bottom: '#0E0A16', ink: '#FFBE8C' },
  { hour: 21, top: '#181426', bottom: '#060610', ink: '#CEBEE0' },
  { hour: 24, top: '#0A0B16', bottom: '#020308', ink: '#AAB8E2' }
];

function mixColor(from: string, to: string, k: number): string {
  const a = parseInt(from.substring(1), 16);
  const b = parseInt(to.substring(1), 16);
  const r = Math.round(((a >> 16) & 0xFF) + (((b >> 16) & 0xFF) - ((a >> 16) & 0xFF)) * k);
  const g = Math.round(((a >> 8) & 0xFF) + (((b >> 8) & 0xFF) - ((a >> 8) & 0xFF)) * k);
  const bl = Math.round((a & 0xFF) + ((b & 0xFF) - (a & 0xFF)) * k);
  return '#' + TimeFormat.two(r) + TimeFormat.two(g) + TimeFormat.two(bl);
}

function smoothstep(x: number): number {
  const c = Math.max(0, Math.min(1, x));
  return c * c * (3 - 2 * c);
}

/** 全屏时钟页：指针 / 沉浸 / 全屏沉浸 / 七段码 / 太阳。 */
@Component
export struct ClockView {
  @Prop style: number = 1;
  @Prop color: string = '#F5F5F7';
  onRequestStyleBar: () => void = () => {
  };

  @State hour: number = 0;
  @State minute: number = 0;
  @State second: number = 0;
  @State pageW: number = 360;
  @State pageH: number = 640;
  @State sunTop: string = '#0A0B16';
  @State sunBottom: string = '#020308';
  @State sunInk: string = '#AAB8E2';

  private timerId: number = -1;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  aboutToAppear(): void {
    try {
      const screen = display.getDefaultDisplaySync();
      this.pageW = px2vp(screen.width);
      this.pageH = px2vp(screen.height);
    } catch (e) {
    }
    this.refresh();
    this.timerId = setInterval(() => this.refresh(), 200);
  }

  aboutToDisappear(): void {
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private refresh(): void {
    const now = new Date();
    this.hour = now.getHours();
    this.minute = now.getMinutes();
    this.second = now.getSeconds() + now.getMilliseconds() / 1000;
    this.updateSun(now);
    this.draw();
  }

  private text(): string {
    return TimeFormat.clock(this.hour, this.minute);
  }

  private immersiveSize(): number {
    return Math.min(this.pageW * 0.62, this.pageH * 0.46);
  }

  private updateSun(now: Date): void {
    const hour = now.getHours() + now.getMinutes() / 60;
    for (let i = 0; i < SUN_STOPS.length - 1; i++) {
      const a = SUN_STOPS[i];
      const b = SUN_STOPS[i + 1];
      if (hour <= b.hour) {
        const k = smoothstep((hour - a.hour) / Math.max(0.001, b.hour - a.hour));
        this.sunTop = mixColor(a.top, b.top, k);
        this.sunBottom = mixColor(a.bottom, b.bottom, k);
        this.sunInk = mixColor(a.ink, b.ink, k);
        return;
      }
    }
  }

  private draw(): void {
    const ctx = this.ctx;
    const width = this.pageW;
    const height = this.pageH;
    ctx.clearRect(0, 0, width, height);
    if (this.style === 0) {
      this.drawAnalog(ctx, width, height);
    } else if (this.style === 3) {
      this.drawSeven(ctx, width, height);
    }
  }

  private drawAnalog(ctx: CanvasRenderingContext2D, width: number, height: number): void {
    const cx = width / 2;
    const cy = height / 2;
    const radius = Math.min(width, height) * 0.37;

    ctx.beginPath();
    ctx.arc(cx, cy, radius, 0, Math.PI * 2);
    ctx.lineWidth = 1;
    ctx.strokeStyle = 'rgba(245, 245, 247, 0.08)';
    ctx.stroke();

    for (let i = 0; i < 60; i++) {
      const angle = i * Math.PI * 2 / 60 - Math.PI / 2;
      const inner = radius - (i % 5 === 0 ? 14 : 6);
      ctx.beginPath();
      ctx.moveTo(cx + Math.cos(angle) * radius, cy + Math.sin(angle) * radius);
      ctx.lineTo(cx + Math.cos(angle) * inner, cy + Math.sin(angle) * inner);
      ctx.lineWidth = i % 5 === 0 ? 1.6 : 1;
      ctx.strokeStyle = i % 5 === 0 ? 'rgba(245, 245, 247, 0.25)' : 'rgba(245, 245, 247, 0.10)';
      ctx.stroke();
    }

    const hourAngle = ((this.hour % 12) + this.minute / 60) * Math.PI / 6 - Math.PI / 2;
    const minuteAngle = (this.minute + this.second / 60) * Math.PI / 30 - Math.PI / 2;
    const secondAngle = this.second * Math.PI / 30 - Math.PI / 2;

    ctx.lineCap = 'round';
    ctx.beginPath();
    ctx.moveTo(cx, cy);
    ctx.lineTo(cx + Math.cos(hourAngle) * radius * 0.52, cy + Math.sin(hourAngle) * radius * 0.52);
    ctx.lineWidth = 5;
    ctx.strokeStyle = this.color;
    ctx.stroke();

    ctx.beginPath();
    ctx.moveTo(cx, cy);
    ctx.lineTo(cx + Math.cos(minuteAngle) * radius * 0.76, cy + Math.sin(minuteAngle) * radius * 0.76);
    ctx.lineWidth = 3.4;
    ctx.strokeStyle = this.color;
    ctx.stroke();

    ctx.beginPath();
    ctx.moveTo(cx, cy);
    ctx.lineTo(cx + Math.cos(secondAngle) * radius * 0.86, cy + Math.sin(secondAngle) * radius * 0.86);
    ctx.lineWidth = 1.4;
    ctx.strokeStyle = ChronTheme.warm;
    ctx.stroke();

    ctx.beginPath();
    ctx.arc(cx, cy, 4.5, 0, Math.PI * 2);
    ctx.fillStyle = this.color;
    ctx.fill();
    ctx.beginPath();
    ctx.arc(cx, cy, 2, 0, Math.PI * 2);
    ctx.fillStyle = ChronTheme.bg;
    ctx.fill();
  }

  private drawSegment(ctx: CanvasRenderingContext2D, digit: number, x: number, y: number,
                       w: number, h: number): void {
    const masks: number[] = [0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F];
    const mask = digit >= 0 && digit <= 9 ? masks[digit] : 0;
    const thickness = w * 0.10;
    const x0 = x;
    const x1 = x + w / 2 - w * 0.06;
    const x2 = x + w;
    const y0 = y;
    const y1 = y + h / 2 - h * 0.03;
    const y2 = y + h;
    const on = ChronTheme.warm;
    const off = 'rgba(245, 245, 247, 0.06)';

    const drawLine = (bit: number, ax: number, ay: number, bx: number, by: number): void => {
      ctx.beginPath();
      ctx.moveTo(ax, ay);
      ctx.lineTo(bx, by);
      ctx.lineCap = 'round';
      ctx.lineWidth = thickness;
      ctx.strokeStyle = (mask & bit) !== 0 ? on : off;
      ctx.stroke();
    };

    drawLine(0x01, x0 + thickness, y0, x1, y0);
    drawLine(0x02, x2, y0 + thickness, x2, y1);
    drawLine(0x04, x2, y1, x2, y2 - thickness);
    drawLine(0x08, x0 + thickness, y2, x1, y2);
    drawLine(0x10, x0, y1, x0, y2 - thickness);
    drawLine(0x20, x0, y0 + thickness, x0, y1);
    drawLine(0x40, x0, y1, x1, y1);
  }

  private drawSeven(ctx: CanvasRenderingContext2D, width: number, height: number): void {
    const digits: number[] = [Math.floor(this.hour / 10), this.hour % 10,
      Math.floor(this.minute / 10), this.minute % 10];
    const digitWidth = Math.min(width * 0.13, height * 0.16);
    const digitHeight = digitWidth * 1.9;
    const gap = digitWidth * 0.34;
    const colonGap = digitWidth * 0.50;
    const total = digitWidth * 4 + gap * 2 + colonGap * 2;
    let x = width / 2 - total / 2;
    const y = height / 2 - digitHeight / 2;

    for (let i = 0; i < 4; i++) {
      this.drawSegment(ctx, digits[i], x, y, digitWidth, digitHeight);
      x += digitWidth;
      if (i === 1) {
        x += colonGap;
        ctx.beginPath();
        ctx.arc(x, y + digitHeight * 0.32, digitWidth * 0.08, 0, Math.PI * 2);
        ctx.arc(x, y + digitHeight * 0.70, digitWidth * 0.08, 0, Math.PI * 2);
        ctx.fillStyle = ChronTheme.warm;
        ctx.fill();
        x += colonGap;
      } else if (i < 3) {
        x += gap;
      }
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.style === 4) {
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({ angle: 180,
            colors: [[this.sunTop, 0.0], [this.sunBottom, 1.0]] })
      } else {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(ChronTheme.bg)
      }

      Canvas(this.ctx)
        .width('100%')
        .height('100%')

      if (this.style === 1 || this.style === 2) {
        Text(this.text())
          .fontSize(this.style === 2 ? this.immersiveSize() : this.pageW * 0.24)
          .fontColor(this.color)
          .fontFamily(ChronTheme.fontFamily)
          .fontWeight(FontWeight.Medium)
          .letterSpacing(this.style === 2 ? -4 : 0)
          .maxLines(1)
          .textAlign(TextAlign.Center)
          .width('100%')
          .padding({ left: ChronTheme.cornerInset, right: ChronTheme.cornerInset })
      }

      if (this.style === 4) {
        Column({ space: 8 }) {
          Text(this.text())
            .fontSize(this.pageW * 0.22)
            .fontColor(this.sunInk)
            .fontFamily(ChronTheme.fontFamily)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
          Text(TimeFormat.two(Math.floor(this.second)))
            .fontSize(this.pageW * 0.045)
            .fontColor(this.sunInk)
            .opacity(0.5)
            .fontFamily(ChronTheme.fontFamily)
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ChronTheme.bg)
    .gesture(LongPressGesture({ repeat: false, duration: 460 })
      .onAction(() => this.onRequestStyleBar()))
  }
}