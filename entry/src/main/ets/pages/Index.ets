import { GraphModel, BpmnXmlParser, FlowViewer } from 'hmflowkit'
import { CPLX1_BPMN_XML } from './SampleData'
import { router } from '@kit.ArkUI'

@Entry
@Component
struct Index {
  @State model: GraphModel = GraphModel.createEmpty()
  @State parseError: string = ''

  aboutToAppear(): void {
    this.loadComplex()
  }

  loadComplex(): void {
    try {
      this.model = BpmnXmlParser.parse(CPLX1_BPMN_XML)
      this.parseError = ''
    } catch (e) {
      this.parseError = '解析失败: ' + e
    }
  }

  build() {
    Column() {
      // ── 按钮栏 ──
      Row() {
        Button('复杂流程图')
          .fontSize(14)
          .onClick(() => { this.loadComplex() })
        Button('Pizza Demo')
          .fontSize(14)
          .onClick(() => { router.pushUrl({ url: 'pages/BpmnViewerPage' }) })
        Button('Kitchen Sink')
          .fontSize(14)
          .onClick(() => {
            router.pushUrl({ url: 'pages/BpmnViewerPage', params: { fileName: 'kitchen-sink.bpmn' } })
          })
      }
      .justifyContent(FlexAlign.SpaceEvenly)
      .width('100%')
      .padding(10)

      if (this.parseError.length > 0) {
        Text(this.parseError)
          .fontSize(13)
          .fontColor('#E53935')
          .padding(6)
      }

      // ── 画布 ──
      FlowViewer({ model: this.model })
        .width('100%')
        .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }
}