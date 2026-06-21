import { AbilityConstant, Configuration, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 读取系统 colorMode 并存入 AppStorage —— FlowViewer 通过 @StorageProp 读取
    AppStorage.setOrCreate('currentColorMode', this.context.config.colorMode);
    hilog.info(DOMAIN, 'testTag', 'Ability onCreate, colorMode: %{public}d', this.context.config.colorMode);
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    // 系统主题切换时更新 AppStorage，FlowViewer 的 @StorageProp + @Watch 自动响应
    AppStorage.setOrCreate('currentColorMode', newConfig.colorMode);
    hilog.info(DOMAIN, 'testTag', 'Config updated, colorMode: %{public}d', newConfig.colorMode);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}