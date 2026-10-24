import display from '@ohos.display';
import { ChronTheme } from '../theme/ChronTheme';
import { ChronSettings } from '../model/ChronSettings';
import { Feedback, HapticLevel } from '../services/Feedback';
import { TimeFormat } from '../services/TimeFormat';
import { TickScale } from './TickScale';

const WEEK_LABELS: string[] = ['一', '二', '三', '四', '五', '六', '日'];

/** 番茄钟页：橙色专注氛围、下拉总结、刻度调时。 */
@Component
export struct PomodoroView {
  @State phase: number = 0;
  @State running: boolean = false;
  @State remaining: number = ChronSettings.focusSeconds;
  @State focusTotal: number = ChronSettings.focusSeconds;
  @State breakTotal: number = ChronSettings.breakSeconds;
  @State adjust: number = 0;
  @State adjustMinutes: number = 25;
  @State pullProgress: number = 0;
  @State summaryOpen: boolean = false;
  @State pageW: number = 360;
  @State pageH: number = 640;
  @State todayCount: number = 0;
  @State todaySeconds: number = 0;
  @State weekCount: number = 0;
  @State weekSeconds: number = 0;
  @State weekMinutes: number[] = [0, 0, 0, 0, 0, 0, 0];

  private endAt: number = 0;
  private timerId: number = -1;

  aboutToAppear(): void {
    try {
      const screen = display.getDefaultDisplaySync();
      this.pageW = px2vp(screen.width);
      this.pageH = px2vp(screen.height);
    } catch (e) {
    }
    this.timerId = setInterval(() => this.onTick(), 120);
    this.refreshSummary();
  }

  aboutToDisappear(): void {
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private accent(): string {
    return this.phase === 2 ? '#8FC9BD' : ChronTheme.warm;
  }

  private phaseTitle(): string {
    if (this.phase === 0) {
      return '准备专注';
    }
    if (this.phase === 1) {
      return this.running ? '专注中' : '已暂停';
    }
    return '休息';
  }

  private timeText(): string {
    return TimeFormat.countdown(this.remaining);
  }

  private onTick(): void {
    if (this.running && this.adjust === 0) {
      const next = (this.endAt - Date.now()) / 1000;
      if (next <= 0) {
        this.finishPhase();
      } else {
        this.remaining = next;
      }
    }
  }

  private refreshSummary(): void {
    this.todayCount = ChronSettings.todayCount();
    this.todaySeconds = ChronSettings.todaySeconds();
    this.weekCount = ChronSettings.weekCount();
    this.weekSeconds = ChronSettings.weekSeconds();
    this.weekMinutes = ChronSettings.last7DaysMinutes();
  }

  private toggleRun(): void {
    if (this.phase === 0) {
      this.phase = 1;
      this.remaining = this.focusTotal;
      this.endAt = Date.now() + this.focusTotal * 1000;
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

  private abandon(): void {
    this.phase = 0;
    this.running = false;
    this.focusTotal = ChronSettings.focusSeconds;
    this.breakTotal = ChronSettings.breakSeconds;
    this.remaining = this.focusTotal;
    Feedback.play(HapticLevel.Light);
  }

  private finishPhase(): void {
    if (this.phase === 1) {
      ChronSettings.addFocus(Math.round(this.focusTotal));
      Feedback.play(HapticLevel.Heavy);
      this.phase = 2;
      this.breakTotal = ChronSettings.breakSeconds;
      this.remaining = this.breakTotal;
      this.endAt = Date.now() + this.breakTotal * 1000;
      this.running = true;
      this.refreshSummary();
    } else {
      Feedback.play(HapticLevel.Medium);
      this.phase = 0;
      this.running = false;
      this.focusTotal = ChronSettings.focusSeconds;
      this.remaining = this.focusTotal;
    }
  }

  private beginAdjust(target: number): void {
    if (this.running) {
      return;
    }
    this.adjust = target;
    this.adjustMinutes = target === 1 ? Math.max(1, Math.round(this.focusTotal / 60))
      : Math.max(1, Math.round(this.breakTotal / 60));
    Feedback.play(HapticLevel.Light);
  }

  private endAdjust(): void {
    if (this.adjust === 1) {
      this.focusTotal = this.adjustMinutes * 60;
      ChronSettings.setFocusSeconds(this.focusTotal);
      if (this.phase === 0) {
        this.remaining = this.focusTotal;
      }
    } else if (this.adjust === 2) {
      this.breakTotal = this.adjustMinutes * 60;
      ChronSettings.setBreakSeconds(this.breakTotal);
    }
    this.adjust = 0;
  }

  private maxMinutes(): number {
    return this.adjust === 2 ? 30 : 90;
  }

  private pullThreshold(): number {
    return this.pageH * 0.22;
  }

  @Builder
  chip(primary: string, secondary: string, onTap: () => void) {
    Column({ space: 2 }) {
      Text(primary)
        .fontSize(13)
        .fontColor(this.accent())
        .fontFamily(ChronTheme.fontFamily)
        .fontWeight(FontWeight.Medium)
      Text(secondary)
        .fontSize(11)
        .fontColor(ChronTheme.dim)
        .fontFamily(ChronTheme.fontFamily)
    }
    .width(132)
    .height(46)
    .justifyContent(FlexAlign.Center)
    .borderRadius(16)
    .backgroundColor('#0AFFFFFF')
    .border({ width: 1, color: '#1F' + this.accent().substring(1) })
    .onClick(onTap)
  }

  @Builder
  summaryPanel() {
    Column({ space: 14 }) {
      Text('近期专注')
        .fontSize(11)
        .fontColor(ChronTheme.faint)
        .fontFamily(ChronTheme.fontFamily)

      Row() {
        Text('今日').fontSize(13).fontColor(this.accent()).fontFamily(ChronTheme.fontFamily)
        Text(this.todayCount.toString() + ' 次 · ' + TimeFormat.duration(this.todaySeconds))
          .fontSize(13).fontColor(ChronTheme.ink).fontFamily(ChronTheme.fontFamily)
          .margin({ left: 12 })
      }
      .width('100%')

      Row() {
        Text('本周').fontSize(13).fontColor(this.accent()).fontFamily(ChronTheme.fontFamily)
        Text(this.weekCount.toString() + ' 次 · ' + TimeFormat.duration(this.weekSeconds))
          .fontSize(13).fontColor(ChronTheme.ink).fontFamily(ChronTheme.fontFamily)
          .margin({ left: 12 })
      }
      .width('100%')

      Row({ space: 0 }) {
        ForEach(this.weekMinutes, (value: number, index: number) => {
          Column() {
            Column()
              .width(14)
              .height(Math.max(3, 74 * value / Math.max(1, this.peakMinutes())))
              .borderRadius(7)
              .linearGradient({ angle: 180,
                colors: [[this.accent(), index === 6 ? 1.0 : 0.55],
                  ['#00' + this.accent().substring(1), 0.0]] })
            Text(WEEK_LABELS[index])
              .fontSize(10)
              .fontColor(ChronTheme.faint)
              .fontFamily(ChronTheme.fontFamily)
              .margin({ top: 6 })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.End)
          .height(98)
        }, (value: number, index: number) => index.toString() + value.toString())
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)
    }
    .width('90%')
    .constraintSize({ maxWidth: 520 })
    .padding(24)
    .borderRadius(ChronTheme.radiusXl)
    .backgroundColor('#F2121010')
    .border({ width: 1, color: '#14FFFFFF' })
  }

  private peakMinutes(): number {
    let peak = 1;
    for (const value of this.weekMinutes) {
      peak = Math.max(peak, value);
    }
    return peak;
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(ChronTheme.bg)
        .radialGradient({ center: ['50%', '58%'], radius: '82%',
          colors: [[this.phase === 2 ? '#148FC9BD' : '#1EFFA35C', 0.0], ['#00000000', 1.0]] })

      if (this.adjust !== 0) {
        Column({ space: 10 }) {
          Text(this.adjustMinutes.toString())
            .fontSize(this.pageW * 0.30)
            .fontColor(this.accent())
            .fontWeight(FontWeight.Medium)
            .fontFamily(ChronTheme.fontFamily)
          Text(this.adjust === 1 ? '专注时长 / 分钟' : '休息时长 / 分钟')
            .fontSize(11)
            .fontColor(ChronTheme.dim)
            .fontFamily(ChronTheme.fontFamily)
          TickScale({
            min: 1,
            max: this.maxMinutes(),
            initial: this.adjustMinutes,
            accent: this.accent(),
            onValueChange: (value: number) => {
              this.adjustMinutes = value;
            }
          })
          .width(this.pageW * 0.78)
          .margin({ top: 24 })
          Text('完成')
            .fontSize(12)
            .fontColor(ChronTheme.dim)
            .fontFamily(ChronTheme.fontFamily)
            .padding({ top: 8, bottom: 8, left: 18, right: 18 })
            .borderRadius(16)
            .backgroundColor('#0DFFFFFF')
            .margin({ top: 16 })
            .onClick(() => this.endAdjust())
        }
        .width('100%')
        .margin({ bottom: 60 })
      } else {
        Column({ space: 10 }) {
          Text(this.phaseTitle())
            .fontSize(12)
            .fontColor(this.accent())
            .opacity(0.75)
            .fontFamily(ChronTheme.fontFamily)

          Text(this.timeText())
            .fontSize(this.pageW * 0.20)
            .fontColor('#F2' + this.accent().substring(1))
            .fontFamily(ChronTheme.fontFamily)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .onClick(() => {
              if (this.phase === 0 && !this.running) {
                this.beginAdjust(1);
              }
            })

          Row() {
            Row()
              .width(this.pageW * 0.34 * Math.max(0, Math.min(1,
                this.remaining / Math.max(this.phase === 2 ? this.breakTotal : this.focusTotal, 1))))
              .height(1.6)
              .borderRadius(1)
              .backgroundColor(this.accent())
              .opacity(0.65)
          }
          .width(this.pageW * 0.34)
          .height(1.6)
          .borderRadius(1)
          .backgroundColor('#1AFFFFFF')
        }
      }

      Column() {
        if (this.adjust === 0) {
          if (this.phase === 0) {
            Row({ space: 12 }) {
              this.chip('专注 ' + TimeFormat.duration(this.focusTotal),
                '点击调整', (): void => {
                  this.beginAdjust(1);
                })
              this.chip('休息 ' + TimeFormat.duration(this.breakTotal),
                '点击调整', (): void => {
                  this.beginAdjust(2);
                })
            }
            .margin({ bottom: 24 })
          }

          Row({ space: 40 }) {
            Stack({ alignContent: Alignment.Center }) {
              Circle().width(56).height(56).fillOpacity(0)
                .stroke('#30' + this.accent().substring(1)).strokeWidth(1)
              if (this.running) {
                Row({ space: 12 }) {
                  Rect().width(4.2).height(17).radius(2).fill(this.accent())
                  Rect().width(4.2).height(17).radius(2).fill(this.accent())
                }
              } else {
                Path()
                  .commands('M -6 -9 L 9 0 L -6 9 Z')
                  .fill(this.accent())
              }
            }
            .width(64)
            .height(64)
            .opacity(0.78)
            .onClick(() => this.toggleRun())

            Stack({ alignContent: Alignment.Center }) {
              Circle().width(56).height(56).fillOpacity(0)
                .stroke('#24' + this.accent().substring(1)).strokeWidth(1)
              Path()
                .commands('M -7 -7 L 7 7 M 7 -7 L -7 7')
                .fillOpacity(0)
                .stroke(this.accent())
                .strokeWidth(1.8)
                .strokeLineCap(LineCapStyle.Round)
            }
            .width(64)
            .height(64)
            .opacity(0.6)
            .onClick(() => this.abandon())
          }
        }
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.End)
      .padding({ bottom: 56 })
      .hitTestBehavior(HitTestMode.Transparent)

      if (this.pullProgress > 0.001 || this.summaryOpen) {
        Stack({ alignContent: Alignment.Top }) {
          this.summaryPanel()
        }
        .width('100%')
        .height('100%')
        .padding({ top: 40 })
        .opacity(Math.max(0, Math.min(1, this.pullProgress * 1.4)))
        .translate({ y: (1 - this.pullProgress) * this.pageH * 0.46 })
        .onClick(() => {
          this.summaryOpen = false;
          animateTo({ duration: 260, curve: Curve.Friction }, () => {
            this.pullProgress = 0;
          });
          Feedback.play(HapticLevel.Light);
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ChronTheme.bg)
    .gesture(PanGesture({ direction: PanDirection.Vertical, distance: 8 })
      .onActionUpdate((event: GestureEvent) => {
        if (this.summaryOpen || this.adjust !== 0) {
          return;
        }
        if (event.offsetY > 0 && event.offsetY > Math.abs(event.offsetX)) {
          this.pullProgress = Math.max(0, Math.min(1, event.offsetY / this.pullThreshold()));
        }
      })
      .onActionEnd(() => {
        if (this.summaryOpen || this.adjust !== 0) {
          return;
        }
        if (this.pullProgress > 0.34) {
          this.summaryOpen = true;
          this.refreshSummary();
          Feedback.play(HapticLevel.Medium);
          animateTo({ duration: 320, curve: Curve.Friction }, () => {
            this.pullProgress = 1;
          });
        } else {
          animateTo({ duration: 240, curve: Curve.Friction }, () => {
            this.pullProgress = 0;
          });
        }
      }))
  }
}