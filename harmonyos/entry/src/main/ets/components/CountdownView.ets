import display from '@ohos.display';
import { ChronTheme } from '../theme/ChronTheme';
import { ChronSettings } from '../model/ChronSettings';
import { Feedback, HapticLevel } from '../services/Feedback';
import { TimeFormat } from '../services/TimeFormat';
import { DurationWheel } from './DurationWheel';

/** 倒计时页：圆环 / 扇形 / 指针 / 沉浸 / 全屏沉浸。 */
@Component
export struct CountdownView {
  @Prop style: number = 0;
  @Prop color: string = '#F5F5F7';
  @Prop thickness: number = 8;
  onRequestStyleBar: () => void = () => {
  };

  @State total: number = ChronSettings.countdownSeconds;
  @State remaining: number = ChronSettings.countdownSeconds;
  @State running: boolean = false;
  @State finished: boolean = false;
  @State setting: boolean = false;
  @State pageW: number = 360;
  @State pageH: number = 640;
  @State pulseScale: number = 0.9;
  @State pulseAlpha: number = 0;
  @State pulseVisible: boolean = false;

  private endAt: number = 0;
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
    this.timerId = setInterval(() => this.onTick(), 120);
  }

  aboutToDisappear(): void {
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private onTick(): void {
    if (this.running && !this.setting) {
      const next = (this.endAt - Date.now()) / 1000;
      if (next <= 0) {
        this.remaining = 0;
        this.running = false;
        this.finished = true;
        Feedback.play(HapticLevel.Heavy);
        this.triggerPulse();
      } else {
        this.remaining = next;
      }
    }
    this.drawProgress();
  }

  private triggerPulse(): void {
    this.pulseVisible = true;
    this.pulseScale = 0.9;
    this.pulseAlpha = 0.55;
    animateTo({ duration: 900, curve: Curve.EaseOut, onFinish: () => {
      this.pulseVisible = false;
    } }, () => {
      this.pulseScale = 1.5;
      this.pulseAlpha = 0;
    });
  }

  private timeText(): string {
    return TimeFormat.countdown(this.remaining);
  }

  private digitSize(): number {
    if (this.style === 0) {
      return this.pageW * 0.13;
    }
    if (this.style === 3) {
      return this.pageW * 0.24;
    }
    return this.pageW * 0.20;
  }

  private immersiveSize(): number {
    const text = this.timeText();
    const factor = text.length > 5 ? 0.40 : 0.62;
    return Math.min(this.pageW * factor, this.pageH * 0.46);
  }

  private toggleRun(): void {
    if (this.finished) {
      this.finished = false;
      this.remaining = this.total;
      this.endAt = Date.now() + this.total * 1000;
      this.running = true;
    } else if (this.running) {
      this.running = false;
      this.endAt = Date.now() + this.remaining * 1000;
    } else {
      this.endAt = Date.now() + this.remaining * 1000;
      this.running = true;
    }
    Feedback.play(HapticLevel.Medium);
  }

  private resetTimer(): void {
    this.running = false;
    this.finished = false;
    this.remaining = this.total;
    Feedback.play(HapticLevel.Light);
  }

  private enterSetting(): void {
    if (this.running) {
      this.remaining = Math.max(0, (this.endAt - Date.now()) / 1000);
      this.running = false;
    }
    this.setting = true;
    Feedback.play(HapticLevel.Light);
  }

  private commitSetting(): void {
    if (!this.setting) {
      return;
    }
    this.setting = false;
    this.total = ChronSettings.countdownSeconds;
    this.remaining = this.total;
    this.finished = false;
  }

  private drawProgress(): void {
    const ctx = this.ctx;
    const width = this.pageW;
    const height = this.pageH;
    ctx.clearRect(0, 0, width, height);
    if (this.setting) {
      return;
    }
    const progress = this.total > 0 ? Math.max(0, Math.min(1, this.remaining / this.total)) : 0;
    const cx = width / 2;
    const cy = height / 2;

    if (this.style === 1) {
      const radius = Math.max(width, height) * 0.78;
      ctx.beginPath();
      ctx.moveTo(cx, cy);
      ctx.arc(cx, cy, radius, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * progress, false);
      ctx.closePath();
      const gradient = ctx.createLinearGradient(cx - radius, cy - radius, cx + radius, cy + radius);
      gradient.addColorStop(0, 'rgba(255, 196, 92, 0.30)');
      gradient.addColorStop(1, 'rgba(255, 132, 58, 0.30)');
      ctx.fillStyle = gradient;
      ctx.fill();
    } else if (this.style === 2) {
      const radius = Math.min(width, height) * 0.34;
      ctx.lineWidth = 1;
      for (let i = 0; i < 60; i++) {
        const angle = i * Math.PI * 2 / 60 - Math.PI / 2;
        const inner = i % 5 === 0 ? radius - 12 : radius - 6;
        ctx.beginPath();
        ctx.moveTo(cx + Math.cos(angle) * radius, cy + Math.sin(angle) * radius);
        ctx.lineTo(cx + Math.cos(angle) * inner, cy + Math.sin(angle) * inner);
        ctx.strokeStyle = i % 5 === 0 ? 'rgba(245, 245, 247, 0.28)' : 'rgba(245, 245, 247, 0.12)';
        ctx.stroke();
      }
      const handAngle = -Math.PI / 2 + Math.PI * 2 * progress;
      ctx.beginPath();
      ctx.moveTo(cx, cy);
      ctx.lineTo(cx + Math.cos(handAngle) * radius * 0.86, cy + Math.sin(handAngle) * radius * 0.86);
      ctx.lineWidth = 2.4;
      ctx.strokeStyle = this.color;
      ctx.stroke();
      ctx.beginPath();
      ctx.arc(cx, cy, 4, 0, Math.PI * 2);
      ctx.fillStyle = this.color;
      ctx.fill();
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Canvas(this.ctx)
        .width('100%')
        .height('100%')

      if (this.style === 0 && !this.setting) {
        Progress({ value: this.remaining, total: Math.max(this.total, 1), type: ProgressType.Ring })
          .width(this.pageW * 0.66)
          .height(this.pageW * 0.66)
          .color(this.color)
          .backgroundColor(ChronTheme.strokeSoft)
          .style({ strokeWidth: this.thickness, enableSmoothEffect: true })
      }

      if (this.pulseVisible) {
        Circle()
          .width(this.pageW * 0.6)
          .height(this.pageW * 0.6)
          .fillOpacity(0)
          .stroke(this.color)
          .strokeWidth(2)
          .scale({ x: this.pulseScale, y: this.pulseScale })
          .opacity(this.pulseAlpha)
      }

      if (this.setting) {
        Column({ space: 8 }) {
          DurationWheel({
            initialSeconds: this.total,
            onCommit: (seconds: number) => {
              ChronSettings.setCountdownSeconds(seconds);
            }
          })
          Text('时      分      秒')
            .fontSize(11)
            .fontColor(ChronTheme.faint)
            .fontFamily(ChronTheme.fontFamily)
        }
        .width(this.pageW * 0.86)
        .constraintSize({ maxWidth: 380 })
      } else {
        Column({ space: 18 }) {
          Text(this.timeText())
            .fontSize(this.style === 4 ? this.immersiveSize() : this.digitSize())
            .fontColor(this.color)
            .fontFamily(ChronTheme.fontFamily)
            .fontWeight(FontWeight.Medium)
            .letterSpacing(this.style === 4 ? -4 : 0)
            .maxLines(1)
            .textAlign(TextAlign.Center)
            .width('100%')
            .padding({ left: ChronTheme.cornerInset, right: ChronTheme.cornerInset })
            .onClick(() => {
              if (!this.running) {
                this.enterSetting();
              }
            })

          if (this.style === 3) {
            Row() {
              Row()
                .width(this.pageW * 0.30 * Math.max(0, Math.min(1,
                  this.remaining / Math.max(this.total, 1))))
                .height(1.6)
                .borderRadius(1)
                .backgroundColor(this.color)
                .opacity(0.7)
            }
            .width(this.pageW * 0.30)
            .height(1.6)
            .borderRadius(1)
            .backgroundColor('#1AFFFFFF')
          }
        }
        .width('100%')
      }

      Column() {
        if (this.setting) {
          Text('完成')
            .fontSize(12)
            .fontColor(ChronTheme.dim)
            .fontFamily(ChronTheme.fontFamily)
            .padding({ top: 8, bottom: 8, left: 18, right: 18 })
            .borderRadius(16)
            .backgroundColor('#0DFFFFFF')
            .onClick(() => this.commitSetting())
        } else {
          Row({ space: 40 }) {
            Stack({ alignContent: Alignment.Center }) {
              Circle().width(56).height(56).fillOpacity(0)
                .stroke(ChronTheme.stroke).strokeWidth(1)
              if (this.running) {
                Row({ space: 12 }) {
                  Rect().width(4.2).height(17).radius(2).fill(ChronTheme.ink)
                  Rect().width(4.2).height(17).radius(2).fill(ChronTheme.ink)
                }
              } else {
                Path()
                  .commands('M -6 -9 L 9 0 L -6 9 Z')
                  .fill(ChronTheme.ink)
              }
            }
            .width(64)
            .height(64)
            .opacity(0.7)
            .onClick(() => this.toggleRun())

            Stack({ alignContent: Alignment.Center }) {
              Circle().width(56).height(56).fillOpacity(0)
                .stroke(ChronTheme.stroke).strokeWidth(1)
              Path()
                .commands('M 0 -10 A 10 10 0 1 1 -7 7')
                .fillOpacity(0)
                .stroke(ChronTheme.ink)
                .strokeWidth(1.8)
                .strokeLineCap(LineCapStyle.Round)
              Path()
                .commands('M -2 -14 L 4 -10 L -2 -6 Z')
                .fill(ChronTheme.ink)
            }
            .width(64)
            .height(64)
            .opacity(0.55)
            .onClick(() => this.resetTimer())
          }
        }
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.End)
      .padding({ bottom: 56 })
      .hitTestBehavior(HitTestMode.Transparent)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ChronTheme.bg)
    .gesture(LongPressGesture({ repeat: false, duration: 460 })
      .onAction(() => this.onRequestStyleBar()))
  }
}