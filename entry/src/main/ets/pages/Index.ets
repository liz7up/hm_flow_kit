import { GraphModel, BpmnXmlParser, FlowViewer } from 'hmflowkit'
import { CPLX1_BPMN_XML } from './SampleData'
import { router } from '@kit.ArkUI'
import { picker, fileIo } from '@kit.CoreFileKit'
import { util } from '@kit.ArkTS'

@Entry
@Component
struct Index {
  @State model: GraphModel = GraphModel.createEmpty()
  @State parseError: string = ''
  @State drawioXml: string = ''
  @State showDrawio: boolean = false
  @State highlightNodeId: string = 'Activity_0qp0vie'

  aboutToAppear(): void {
    this.loadComplex()
  }

  loadComplex(): void {
    this.showDrawio = false
    this.drawioXml = ''
    try {
      this.model = BpmnXmlParser.parse(CPLX1_BPMN_XML)
      this.parseError = ''
    } catch (e) {
      this.parseError = '解析失败: ' + e
    }
  }

  async openDrawioFile(): Promise<void> {
    try {
      let options = new picker.DocumentSelectOptions()
      options.maxSelectNumber = 1
      options.fileSuffixFilters = ['.drawio', '.xml']
      let docPicker = new picker.DocumentViewPicker()
      let uris = await docPicker.select(options)
      if (uris.length > 0) {
        let uri = uris[0]
        let file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY)
        let stat = fileIo.statSync(file.fd)
        let buf = new ArrayBuffer(stat.size)
        fileIo.readSync(file.fd, buf)
        fileIo.closeSync(file)
        let decoder = new util.TextDecoder('utf-8')
        this.drawioXml = decoder.decodeToString(new Uint8Array(buf))
        this.showDrawio = true
        this.parseError = ''
      }
    } catch (e) {
      // user cancelled or picker error
    }
  }

  async openBpmnFile(): Promise<void> {
    try {
      let options = new picker.DocumentSelectOptions()
      options.maxSelectNumber = 1
      options.fileSuffixFilters = ['.bpmn', '.xml']
      let docPicker = new picker.DocumentViewPicker()
      let uris = await docPicker.select(options)
      if (uris.length > 0) {
        let uri = uris[0]
        let fileName = uri.substring(uri.lastIndexOf('/') + 1)
        router.pushUrl({
          url: 'pages/BpmnViewerPage',
          params: { fileUri: uri, pageTitle: fileName }
        })
      }
    } catch (e) {
      // user cancelled or picker error
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
        Button('Nested Subprocess')
          .fontSize(14)
          .onClick(() => {
            router.pushUrl({ url: 'pages/BpmnViewerPage', params: { fileName: 'nested-subprocesses.bpmn' } })
          })
        Button('审批流 Demo')
          .fontSize(14)
          .fontColor('#1565C0')
          .onClick(() => {
            router.pushUrl({ url: 'pages/ApprovalDemoPage' })
          })
        Button('打开任意bpmn文件')
          .fontSize(14)
          .onClick(() => { this.openBpmnFile() })
        Button('打开drawio文件')
          .fontSize(14)
          .onClick(() => { this.openDrawioFile() })
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
      if (this.showDrawio) {
        FlowViewer({ drawioXml: this.drawioXml, highlightNodeId: this.highlightNodeId })
          .width('100%')
          .layoutWeight(1)
      } else {
        FlowViewer({ model: this.model, highlightNodeId: this.highlightNodeId })
          .width('100%')
          .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
  }
}