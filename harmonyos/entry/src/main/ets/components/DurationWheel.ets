import { ChronTheme } from '../theme/ChronTheme';
import { Feedback, HapticLevel } from '../services/Feedback';

function rangeStrings(count: number): string[] {
  const values: string[] = [];
  for (let i = 0; i < count; i++) {
    values.push(i < 10 ? '0' + i.toString() : i.toString());
  }
  return values;
}

const HOUR_RANGE: string[] = rangeStrings(24);
const MINUTE_RANGE: string[] = rangeStrings(60);

/** 倒计时时长滚轮：时 / 分 / 秒，原生惯性、吸附与触感。 */
@Component
export struct DurationWheel {
  initialSeconds: number = 300;
  onCommit: (seconds: number) => void = (seconds: number) => {
  };

  @State hour: number = 0;
  @State minute: number = 5;
  @State second: number = 0;

  aboutToAppear(): void {
    this.apply(this.initialSeconds);
  }

  private apply(seconds: number): void {
    const total = Math.max(0, Math.min(seconds, 24 * 3600 - 1));
    this.hour = Math.floor(total / 3600);
    this.minute = Math.floor((total % 3600) / 60);
    this.second = total % 60;
  }

  private total(): number {
    return this.hour * 3600 + this.minute * 60 + this.second;
  }

  @Builder
  wheel(range: string[], selected: number, label: string,
        onChange: (index: number) => void) {
    Column({ space: 4 }) {
      TextPicker({ range: range, selected: selected })
        .width('100%')
        .height(180)
        .canLoop(false)
        .defaultPickerItemHeight(44)
        .selectedTextStyle({ color: ChronTheme.ink,
          font: { size: 26, weight: FontWeight.Medium, family: ChronTheme.fontFamily } })
        .textStyle({ color: ChronTheme.faint,
          font: { size: 18, weight: FontWeight.Regular, family: ChronTheme.fontFamily } })
        .divider({ strokeWidth: 1, color: '#12FFFFFF' })
        .onChange((value: string | string[], index: number | number[]) => {
          const next: number = index as number;
          if (next === selected) {
            return;
          }
          Feedback.play(HapticLevel.Light);
          onChange(next);
        })
      Text(label)
        .fontSize(11)
        .fontColor(ChronTheme.faint)
        .fontFamily(ChronTheme.fontFamily)
    }
    .layoutWeight(1)
  }

  build() {
    Row({ space: 6 }) {
      this.wheel(HOUR_RANGE, this.hour, '时', (index: number) => {
        this.hour = index;
        this.onCommit(this.total());
      })
      Text(':')
        .fontSize(24)
        .fontColor(ChronTheme.faint)
        .height(180)
        .textAlign(TextAlign.Center)
        .margin({ top: -18 })
      this.wheel(MINUTE_RANGE, this.minute, '分', (index: number) => {
        this.minute = index;
        this.onCommit(this.total());
      })
      Text(':')
        .fontSize(24)
        .fontColor(ChronTheme.faint)
        .height(180)
        .textAlign(TextAlign.Center)
        .margin({ top: -18 })
      this.wheel(MINUTE_RANGE, this.second, '秒', (index: number) => {
        this.second = index;
        this.onCommit(this.total());
      })
    }
    .width('100%')
    .padding({ left: 12, right: 12 })
  }
}