import { BpmnXmlParser, FlowViewer, GraphModel, PlaneHierarchy } from 'hmflowkit'
import { resourceManager } from '@kit.LocalizationKit'
import { util } from '@kit.ArkTS'
import { router } from '@kit.ArkUI'
import { fileIo } from '@kit.CoreFileKit'

@Entry
@Component
struct BpmnViewerPage {
  @State model: GraphModel = GraphModel.createEmpty()
  @State loading: boolean = true
  @State errorMsg: string = ''
  @State fileName: string = 'pizza-collaboration.bpmn'
  @State pageTitle: string = 'pizza-collaboration.bpmn'
  @State fileUri: string = ''
  @State planeHierarchy: PlaneHierarchy | null = null

  aboutToAppear(): void {
    let params = router.getParams() as Record<string, string>
    if (params !== undefined) {
      if (params['fileName'] !== undefined) {
        this.fileName = params['fileName']
        this.pageTitle = params['fileName']
      }
      if (params['fileUri'] !== undefined) {
        this.fileUri = params['fileUri']
        this.pageTitle = params['pageTitle'] || 'BPMN 文件'
      }
    }
    this.loadBpmnFile()
  }

  async loadBpmnFile(): Promise<void> {
    try {
      let xmlStr: string
      if (this.fileUri.length > 0) {
        let file = fileIo.openSync(this.fileUri, fileIo.OpenMode.READ_ONLY)
        let stat = fileIo.statSync(file.fd)
        let buf = new ArrayBuffer(stat.size)
        fileIo.readSync(file.fd, buf)
        fileIo.closeSync(file)
        let decoder = new util.TextDecoder('utf-8')
        xmlStr = decoder.decodeToString(new Uint8Array(buf))
      } else {
        let context = getContext(this)
        let rawData: Uint8Array = await context.resourceManager.getRawFileContent(this.fileName)
        let decoder = new util.TextDecoder('utf-8')
        xmlStr = decoder.decodeToString(rawData)
      }
      // 尝试多平面解析（drill-down 导航）
      try {
        let hierarchy: PlaneHierarchy = BpmnXmlParser.parseHierarchy(xmlStr)
        if (hierarchy.getPlaneCount() > 1) {
          this.planeHierarchy = hierarchy
          this.model = hierarchy.getRootModel()
          this.loading = false
          return
        }
      } catch (e2) {
        // 无多平面数据，降级到单平面解析
      }
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

        Text(this.pageTitle)
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
          planeHierarchy: this.planeHierarchy,
          showGrid: false,
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
