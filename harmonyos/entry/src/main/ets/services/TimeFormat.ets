/** 时间格式化：等宽两位数字，跨小时时自动补上小时位。 */
export class TimeFormat {
  static two(value: number): string {
    return value < 10 ? '0' + value.toString() : value.toString();
  }

  static countdown(seconds: number): string {
    const total = Math.max(0, Math.ceil(seconds - 0.0001));
    const hours = Math.floor(total / 3600);
    const minutes = Math.floor((total % 3600) / 60);
    const secs = total % 60;
    if (hours > 0) {
      return hours.toString() + ':' + TimeFormat.two(minutes) + ':' + TimeFormat.two(secs);
    }
    return TimeFormat.two(minutes) + ':' + TimeFormat.two(secs);
  }

  static clock(hour: number, minute: number): string {
    return TimeFormat.two(hour) + ':' + TimeFormat.two(minute);
  }

  static duration(seconds: number): string {
    if (seconds >= 3600) {
      const hours = Math.floor(seconds / 3600);
      const minutes = Math.floor((seconds % 3600) / 60);
      return minutes > 0 ? hours.toString() + ' 小时 ' + minutes.toString() + ' 分'
        : hours.toString() + ' 小时';
    }
    if (seconds >= 60) {
      return Math.floor(seconds / 60).toString() + ' 分钟';
    }
    return seconds.toString() + ' 秒';
  }
}