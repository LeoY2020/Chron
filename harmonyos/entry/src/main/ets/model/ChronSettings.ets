import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';

export interface FocusRecord {
  start: number;
  seconds: number;
}

/**
 * 偏好与专注记录的唯一来源：偏好走 preferences，记录以 JSON 字符串保存。
 * 全部读取为同步（启动时一次性加载到内存），写入异步落盘。
 */
export class ChronSettings {
  private static pref: preferences.Preferences | undefined = undefined;

  static countdownStyle: number = 0;
  static clockStyle: number = 1;
  static countdownColor: string = '#F5F5F7';
  static clockColor: string = '#F5F5F7';
  static countdownSeconds: number = 300;
  static ringThickness: number = 8;
  static focusSeconds: number = 25 * 60;
  static breakSeconds: number = 5 * 60;
  static reduceMotion: boolean = false;

  private static history: FocusRecord[] = [];

  static async init(context: common.UIAbilityContext): Promise<void> {
    const prefs = await preferences.getPreferences(context, 'chron_settings');
    this.pref = prefs;
    this.countdownStyle = (await prefs.get('countdownStyle', 0)) as number;
    this.clockStyle = (await prefs.get('clockStyle', 1)) as number;
    this.countdownColor = (await prefs.get('countdownColor', '#F5F5F7')) as string;
    this.clockColor = (await prefs.get('clockColor', '#F5F5F7')) as string;
    this.countdownSeconds = (await prefs.get('countdownSeconds', 300)) as number;
    this.ringThickness = (await prefs.get('ringThickness', 8)) as number;
    this.focusSeconds = (await prefs.get('focusSeconds', 25 * 60)) as number;
    this.breakSeconds = (await prefs.get('breakSeconds', 5 * 60)) as number;
    this.reduceMotion = (await prefs.get('reduceMotion', false)) as boolean;

    const raw = (await prefs.get('history', '[]')) as string;
    this.history = this.parseHistory(raw);
  }

  private static parseHistory(raw: string): FocusRecord[] {
    try {
      const parsed = JSON.parse(raw) as FocusRecord[];
      if (Array.isArray(parsed)) {
        return parsed;
      }
    } catch (e) {
    }
    return [];
  }

  private static write(key: string, value: string | number | boolean): void {
    const prefs = this.pref;
    if (prefs === undefined) {
      return;
    }
    prefs.put(key, value).then(() => {
      prefs.flush();
    }).catch(() => {
    });
  }

  static setCountdownStyle(value: number): void {
    this.countdownStyle = value;
    this.write('countdownStyle', value);
  }

  static setClockStyle(value: number): void {
    this.clockStyle = value;
    this.write('clockStyle', value);
  }

  static setCountdownColor(value: string): void {
    this.countdownColor = value;
    this.write('countdownColor', value);
  }

  static setClockColor(value: string): void {
    this.clockColor = value;
    this.write('clockColor', value);
  }

  static setCountdownSeconds(value: number): void {
    this.countdownSeconds = Math.max(1, Math.min(value, 24 * 3600 - 1));
    this.write('countdownSeconds', this.countdownSeconds);
  }

  static setRingThickness(value: number): void {
    this.ringThickness = value;
    this.write('ringThickness', value);
  }

  static setFocusSeconds(value: number): void {
    this.focusSeconds = Math.max(60, Math.min(value, 90 * 60));
    this.write('focusSeconds', this.focusSeconds);
  }

  static setBreakSeconds(value: number): void {
    this.breakSeconds = Math.max(30, Math.min(value, 30 * 60));
    this.write('breakSeconds', this.breakSeconds);
  }

  static addFocus(seconds: number): void {
    if (seconds <= 0) {
      return;
    }
    const record: FocusRecord = { start: Date.now(), seconds: seconds };
    this.history.push(record);
    this.write('history', JSON.stringify(this.history));
  }

  static todayCount(): number {
    const start = this.startOfToday();
    let count = 0;
    for (const record of this.history) {
      if (record.start >= start) {
        count++;
      }
    }
    return count;
  }

  static todaySeconds(): number {
    const start = this.startOfToday();
    let total = 0;
    for (const record of this.history) {
      if (record.start >= start) {
        total += record.seconds;
      }
    }
    return total;
  }

  static weekCount(): number {
    let count = 0;
    for (const record of this.history) {
      if (record.start >= this.startOfWeek()) {
        count++;
      }
    }
    return count;
  }

  static weekSeconds(): number {
    let total = 0;
    for (const record of this.history) {
      if (record.start >= this.startOfWeek()) {
        total += record.seconds;
      }
    }
    return total;
  }

  /** 最近七天每天的专注分钟数，索引 6 为今天。 */
  static last7DaysMinutes(): number[] {
    const result: number[] = [0, 0, 0, 0, 0, 0, 0];
    const dayMs = 24 * 3600 * 1000;
    const today = this.startOfToday();
    for (const record of this.history) {
      if (record.start < today - 6 * dayMs) {
        continue;
      }
      const index = Math.floor((record.start - (today - 6 * dayMs)) / dayMs);
      if (index >= 0 && index < 7) {
        result[index] += Math.floor(record.seconds / 60);
      }
    }
    return result;
  }

  private static startOfToday(): number {
    const now = new Date();
    return new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
  }

  private static startOfWeek(): number {
    const start = this.startOfToday();
    const day = new Date().getDay();
    const offset = day === 0 ? 6 : day - 1;
    return start - offset * 24 * 3600 * 1000;
  }
}