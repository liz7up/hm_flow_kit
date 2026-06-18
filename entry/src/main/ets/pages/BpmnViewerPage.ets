import { BpmnXmlParser, FlowViewer, GraphModel } from 'hmflowkit'
import { resourceManager } from '@kit.LocalizationKit'
import { util } from '@kit.ArkTS'
import { router } from '@kit.ArkUI'

@Entry
@Component
struct BpmnViewerPage {
  @State model: GraphModel = GraphModel.createEmpty()
  @State loading: boolean = true
  @State errorMsg: string = ''
  @State fileName: string = 'pizza-collaboration.bpmn'

  aboutToAppear(): void {
    this.loadBpmnFile()
  }

  async loadBpmnFile(): Promise<void> {
    try {
      let context = getContext(this)
      let rawData: Uint8Array = await context.resourceManager.getRawFileContent(this.fileName)
      let decoder = new util.TextDecoder('utf-8')
      let xmlStr: string = decoder.decodeToString(rawData)
      this.model = BpmnXmlParser.parse(xmlStr)
      this.loading = false
    } catch (e) {
      this.errorMsg = 'Failed to load BPMN file: ' + JSON.stringify(e)
      this.loading = false
    }
  }

  build() {
    Column() {
      Row() {
        Button('← 返回')
          .fontSize(14)
          .onClick(() => { router.back() })

        Text(this.fileName)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text(`节点:${this.model.getNodeCount()} | 连线:${this.model.getEdgeCount()} | 泳池:${this.model.getPoolCount()}`)
          .fontSize(12)
          .fontColor('#666')
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#f5f5f5')

      if (this.loading) {
        Column() {
          LoadingProgress()
            .color('#1890FF')
            .width(40)
            .height(40)
          Text('加载中...')
            .fontSize(14)
            .fontColor('#999')
            .margin({ top: 12 })
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .layoutWeight(1)
      } else if (this.errorMsg !== '') {
        Column() {
          Text(this.errorMsg)
            .fontSize(14)
            .fontColor('#FF4444')
            .textAlign(TextAlign.Center)
            .padding(20)
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .layoutWeight(1)
      } else {
        FlowViewer({
          model: this.model,
          showGrid: true,
          onNodeClick: (id: string) => { console.info('BPMN node clicked: ' + id) }
        })
          .width('100%')
          .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ffffff')
  }
}
