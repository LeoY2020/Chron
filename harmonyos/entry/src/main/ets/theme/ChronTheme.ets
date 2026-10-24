/**
 * Chron 设计令牌：纯黑背景、克制的暖白与低饱和橙。
 * 对齐 HarmonyOS Design 的 4px 网格与 8 / 12 / 16 / 24 圆角。
 */
export class ChronTheme {
  static readonly bg: string = '#000000';
  static readonly bgLift: string = '#0F0F14';
  static readonly ink: string = '#F5F5F7';
  static readonly dim: string = '#808086';
  static readonly faint: string = '#424248';
  static readonly warm: string = '#FFA35C';
  static readonly warmDeep: string = '#D6763E';
  static readonly panel: string = '#F218181B';
  static readonly stroke: string = '#1AFFFFFF';
  static readonly strokeSoft: string = '#0DFFFFFF';

  static readonly radiusS: number = 8;
  static readonly radiusM: number = 12;
  static readonly radiusL: number = 16;
  static readonly radiusXl: number = 24;

  static readonly spaceXs: number = 4;
  static readonly spaceSm: number = 8;
  static readonly spaceMd: number = 12;
  static readonly spaceLg: number = 16;
  static readonly spaceXl: number = 24;

  static readonly fontFamily: string = 'HarmonyOS Sans';

  static readonly durationFast: number = 200;
  static readonly durationBase: number = 320;
  static readonly durationSlow: number = 380;
  static readonly shrinkScale: number = 0.93;
  static readonly cornerInset: number = 24;
}

/** 样式栏可选字体颜色 */
export const CHRON_PALETTE: string[] = ['#F5F5F7', '#FFA35C', '#E8C07A', '#9CC4FF', '#FF8E9B'];

/** 样式栏可选圆环粗细 */
export const CHRON_THICKNESS: number[] = [4, 8, 14];