import UIAbility from '@ohos.app.ability.UIAbility';
import hilog from '@ohos.hilog';
import window from '@ohos.window';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import Want from '@ohos.app.ability.Want';
import { ChronSettings } from '../model/ChronSettings';

const DOMAIN = 0x0000;
const TAG = 'Chron';

/** 应用入口：初始化偏好后加载主页面，并让窗口内容延伸到状态栏下方。 */
export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    const context = this.context;
    const init = async (): Promise<void> => {
      try {
        await ChronSettings.init(context);
      } catch (e) {
        hilog.error(DOMAIN, TAG, 'settings init failed: %{public}s', JSON.stringify(e));
      }
      windowStage.loadContent('pages/Index', (err) => {
        if (err.code) {
          hilog.error(DOMAIN, TAG, 'loadContent failed: %{public}s', JSON.stringify(err));
          return;
        }
        try {
          const win = windowStage.getMainWindowSync();
          win.setWindowLayoutFullScreen(true);
          win.setWindowSystemBarEnable([]);
        } catch (e) {
        }
      });
    };
    init();
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, 'onWindowStageDestroy');
  }
}