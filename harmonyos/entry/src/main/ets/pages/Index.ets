import { ChronTheme } from '../theme/ChronTheme';
import { ChronSettings } from '../model/ChronSettings';
import { Feedback, HapticLevel } from '../services/Feedback';
import { CountdownView } from '../components/CountdownView';
import { PomodoroView } from '../components/PomodoroView';
import { ClockView } from '../components/ClockView';
import { StyleBar } from '../components/StyleBar';

const COUNTDOWN_STYLES: string[] = ['圆环', '扇形', '指针', '沉浸', '全屏沉浸'];
const CLOCK_STYLES: string[] = ['指针', '沉浸', '全屏沉浸', '七段码', '太阳'];

/** 主界面：三页全屏横向分页，长按缩小并唤出底部样式栏。 */
@Entry
@Component
struct Index {
  @State pageIndex: number = 0;
  @State shrink: boolean = false;
  @State barEditing: boolean = false;
  @State countdownStyle: number = ChronSettings.countdownStyle;
  @State clockStyle: number = ChronSettings.clockStyle;
  @State countdownColor: string = ChronSettings.countdownColor;
  @State clockColor: string = ChronSettings.clockColor;
  @State ringThickness: number = ChronSettings.ringThickness;

  private swiper: SwiperController = new SwiperController();

  private openBar(): void {
    if (this.pageIndex === 1) {
      return;
    }
    this.barEditing = false;
    this.shrink = true;
    Feedback.play(HapticLevel.Medium);
  }

  private closeBar(): void {
    if (!this.shrink) {
      return;
    }
    this.shrink = false;
    this.barEditing = false;
    Feedback.play(HapticLevel.Light);
  }

  private currentStyles(): string[] {
    return this.pageIndex === 0 ? COUNTDOWN_STYLES : CLOCK_STYLES;
  }

  private currentStyle(): number {
    return this.pageIndex === 0 ? this.countdownStyle : this.clockStyle;
  }

  private currentColor(): string {
    return this.pageIndex === 0 ? this.countdownColor : this.clockColor;
  }

  private immersive(): boolean {
    if (this.pageIndex === 0) {
      return this.countdownStyle === 4;
    }
    return this.clockStyle === 1 || this.clockStyle === 2;
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Swiper(this.swiper) {
        CountdownView({
          style: this.countdownStyle,
          color: this.countdownColor,
          thickness: this.ringThickness,
          onRequestStyleBar: () => {
            this.openBar();
          }
        })
        PomodoroView()
        ClockView({
          style: this.clockStyle,
          color: this.clockColor,
          onRequestStyleBar: () => {
            this.openBar();
          }
        })
      }
      .index(this.pageIndex)
      .indicator(false)
      .loop(false)
      .disableSwipe(this.shrink)
      .onChange((index: number) => {
        this.pageIndex = index;
        this.barEditing = false;
      })
      .width('100%')
      .height('100%')
      .scale({ x: this.shrink ? ChronTheme.shrinkScale : 1,
        y: this.shrink ? ChronTheme.shrinkScale : 1 })
      .borderRadius(this.shrink ? 36 : 0)
      .clip(true)
      .animation({ duration: ChronTheme.durationSlow, curve: Curve.Friction })

      if (!this.shrink && !this.immersive()) {
        Column() {
          Row({ space: 12 }) {
            ForEach([0, 1, 2], (index: number) => {
              Circle()
                .width(index === this.pageIndex ? 5.6 : 4)
                .height(index === this.pageIndex ? 5.6 : 4)
                .fill(index === this.pageIndex ? '#82FFFFFF' : '#2EFFFFFF')
            }, (index: number) => index.toString())
          }
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.End)
        .padding({ bottom: 26 })
        .hitTestBehavior(HitTestMode.Transparent)
      }

      if (this.shrink) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#000000')
          .onClick(() => this.closeBar())

        Column() {
          StyleBar({
            styles: this.currentStyles(),
            current: this.currentStyle(),
            editing: this.barEditing,
            color: this.currentColor(),
            thickness: this.ringThickness,
            showThickness: this.pageIndex === 0,
            onSelectStyle: (index: number) => {
              if (this.pageIndex === 0) {
                this.countdownStyle = index;
                ChronSettings.setCountdownStyle(index);
              } else {
                this.clockStyle = index;
                ChronSettings.setClockStyle(index);
              }
              Feedback.play(HapticLevel.Light);
            },
            onToggleEdit: () => {
              this.barEditing = !this.barEditing;
              Feedback.play(HapticLevel.Light);
            },
            onSelectColor: (hex: string) => {
              if (this.pageIndex === 0) {
                this.countdownColor = hex;
                ChronSettings.setCountdownColor(hex);
              } else {
                this.clockColor = hex;
                ChronSettings.setClockColor(hex);
              }
              Feedback.play(HapticLevel.Light);
            },
            onSelectThickness: (value: number) => {
              this.ringThickness = value;
              ChronSettings.setRingThickness(value);
              Feedback.play(HapticLevel.Light);
            }
          })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.End)
        .padding({ bottom: 28 })
        .transition(TransitionEffect.OPACITY
          .combine(TransitionEffect.move(TransitionEdge.BOTTOM))
          .animation({ duration: ChronTheme.durationBase, curve: Curve.Friction }))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }
}