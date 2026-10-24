import { ChronTheme } from '../theme/ChronTheme';
import { Feedback, HapticLevel } from '../services/Feedback';

/** 番茄钟时间刻度：拖动刻度改变上方时间，经过整数刻度时给出轻反馈。 */
@Component
export struct TickScale {
  min: number = 1;
  max: number = 90;
  initial: number = 25;
  accent: string = ChronTheme.warm;
  onValueChange: (value: number) => void = (value: number) => {
  };

  @State floatValue: number = 25;
  @State widthVp: number = 320;
  private lastOffset: number = 0;
  private readonly pxPerUnit: number = 8;

  aboutToAppear(): void {
    this.floatValue = this.clamp(this.initial);
    this.onValueChange(this.value());
  }

  private clamp(value: number): number {
    return Math.max(this.min, Math.min(value, this.max));
  }

  private value(): number {
    return Math.round(this.floatValue);
  }

  private xFor(tick: number): number {
    return this.widthVp / 2 + (tick - this.floatValue) * this.pxPerUnit - 0.75;
  }

  private visibleTicks(): number[] {
    const span = Math.ceil(this.widthVp / 2 / this.pxPerUnit) + 2;
    const center = Math.round(this.floatValue);
    const ticks: number[] = [];
    for (let i = center - span; i <= center + span; i++) {
      if (i >= this.min && i <= this.max) {
        ticks.push(i);
      }
    }
    return ticks;
  }

  private onPan(offsetX: number): void {
    const delta = offsetX - this.lastOffset;
    this.lastOffset = offsetX;
    const before = this.value();
    this.floatValue = this.clamp(this.floatValue - delta / this.pxPerUnit);
    if (this.value() !== before) {
      Feedback.play(HapticLevel.Light);
      this.onValueChange(this.value());
    }
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      ForEach(this.visibleTicks(), (tick: number) => {
        Column()
          .width(tick % 5 === 0 ? 1.5 : 1)
          .height(tick % 5 === 0 ? 18 : 10)
          .borderRadius(1)
          .backgroundColor(tick % 5 === 0 ? '#66FFFFFF' : '#33FFFFFF')
          .position({ x: this.xFor(tick), y: 34 })
      }, (tick: number) => tick.toString())

      Path()
        .commands('M -6 0 L 6 0 L 0 9 Z')
        .fill(this.accent)
        .position({ x: this.widthVp / 2 - 6, y: 10 })

      Row()
        .width(this.widthVp)
        .height(1)
        .linearGradient({ angle: 90,
          colors: [['#00FFFFFF', 0.0], ['#3DFFFFFF', 0.5], ['#00FFFFFF', 1.0]] })
        .position({ x: 0, y: 55 })
    }
    .width('100%')
    .height(96)
    .clip(true)
    .onAreaChange((oldValue: Area, newValue: Area) => {
      this.widthVp = newValue.width as number;
    })
    .gesture(PanGesture({ direction: PanDirection.Horizontal, distance: 2 })
      .onActionStart(() => {
        this.lastOffset = 0;
      })
      .onActionUpdate((event: GestureEvent) => {
        this.onPan(event.offsetX);
      })
      .onActionEnd(() => {
        this.floatValue = this.value();
      }))
  }
}