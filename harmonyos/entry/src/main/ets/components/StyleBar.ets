import { ChronTheme, CHRON_PALETTE, CHRON_THICKNESS } from '../theme/ChronTheme';

/** 底部样式栏：样式切换 + 就地编辑（颜色 / 圆环粗细）。 */
@Component
export struct StyleBar {
  styles: string[] = [];
  @Prop current: number = 0;
  @Prop editing: boolean = false;
  @Prop color: string = '#F5F5F7';
  @Prop thickness: number = 8;
  @Prop showThickness: boolean = true;

  onSelectStyle: (index: number) => void = (index: number) => {
  };
  onToggleEdit: () => void = () => {
  };
  onSelectColor: (hex: string) => void = (hex: string) => {
  };
  onSelectThickness: (value: number) => void = (value: number) => {
  };

  build() {
    Column({ space: 16 }) {
      Row({ space: 8 }) {
        ForEach(this.styles, (name: string, index: number) => {
          Text(name)
            .fontSize(13)
            .fontFamily(ChronTheme.fontFamily)
            .fontWeight(index === this.current ? FontWeight.Medium : FontWeight.Regular)
            .fontColor(index === this.current ? ChronTheme.ink : ChronTheme.dim)
            .textAlign(TextAlign.Center)
            .height(46)
            .layoutWeight(1)
            .borderRadius(15)
            .backgroundColor(index === this.current ? '#1CFFFFFF' : '#08FFFFFF')
            .onClick(() => {
              if (index === this.current) {
                this.onToggleEdit();
              } else {
                this.onSelectStyle(index);
              }
            })
        }, (name: string, index: number) => name + index.toString())
      }
      .width('100%')

      if (this.editing) {
        Column({ space: 14 }) {
          Row({ space: 18 }) {
            ForEach(CHRON_PALETTE, (hex: string) => {
              Stack() {
                Circle()
                  .width(26)
                  .height(26)
                  .fill(hex)
                if (hex === this.color) {
                  Circle()
                    .width(34)
                    .height(34)
                    .fillOpacity(0)
                    .stroke(ChronTheme.ink)
                    .strokeWidth(1.5)
                }
              }
              .width(34)
              .height(34)
              .onClick(() => this.onSelectColor(hex))
            }, (hex: string) => hex)
          }
          .justifyContent(FlexAlign.Center)
          .width('100%')

          if (this.showThickness) {
            Row({ space: 26 }) {
              ForEach(CHRON_THICKNESS, (value: number) => {
                Circle()
                  .width(30)
                  .height(30)
                  .fillOpacity(0)
                  .stroke(value === this.thickness ? ChronTheme.ink : ChronTheme.faint)
                  .strokeWidth(value / 3 + 1)
                  .onClick(() => this.onSelectThickness(value))
              }, (value: number) => value.toString())
            }
            .justifyContent(FlexAlign.Center)
            .width('100%')
          }
        }
        .width('100%')
        .transition(TransitionEffect.OPACITY.animation({ duration: ChronTheme.durationFast,
          curve: Curve.Friction }))
      }
    }
    .width('92%')
    .constraintSize({ maxWidth: 560 })
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .backgroundColor(ChronTheme.panel)
    .borderRadius(ChronTheme.radiusXl)
    .border({ width: 1, color: ChronTheme.stroke })
  }
}