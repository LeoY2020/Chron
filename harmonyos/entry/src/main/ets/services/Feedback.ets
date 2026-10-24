import vibrator from '@ohos.vibrator';
import { ChronSettings } from '../model/ChronSettings';

export enum HapticLevel {
  Light,
  Medium,
  Heavy
}

/** 分级反馈：轻 / 中 / 重，尊重系统“减弱动效”偏好。 */
export class Feedback {
  static play(level: HapticLevel): void {
    if (level === HapticLevel.Light && ChronSettings.reduceMotion) {
      return;
    }
    let duration = 12;
    if (level === HapticLevel.Medium) {
      duration = 20;
    } else if (level === HapticLevel.Heavy) {
      duration = 36;
    }
    try {
      vibrator.startVibration({
        type: 'time',
        duration: duration
      }, {
        id: 'chron.feedback',
        usage: 'touch'
      }).catch(() => {
      });
    } catch (e) {
    }
  }
}