import { GraphModel, BpmnXmlParser, FlowViewer } from 'hmflowkit'
import { CPLX1_BPMN_XML } from './SampleData'
import { router } from '@kit.ArkUI'
import { picker, fileIo } from '@kit.CoreFileKit'

const DRAWIO_TEST_XML: string = `<mxfile host="app.diagrams.net">
  <diagram name="第 1 页" id="5SaH_E39eHd-wbtu7vK2">
    <mxGraphModel dx="1041" dy="751" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="827" pageHeight="1169" math="0" shadow="0">
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />
        <mxCell id="xhq54t3BPlNCBh4OEzKU-1" parent="1" style="rounded=1;whiteSpace=wrap;html=1;" value="" vertex="1">
          <mxGeometry height="60" width="120" x="260" y="150" as="geometry" />
        </mxCell>
        <mxCell id="wztpRqVbKRzhqjhXyiTL-1" edge="1" parent="1" source="xhq54t3BPlNCBh4OEzKU-2" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;" target="xhq54t3BPlNCBh4OEzKU-9">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
        <mxCell id="xhq54t3BPlNCBh4OEzKU-2" parent="1" style="ellipse;whiteSpace=wrap;html=1;" value="" vertex="1">
          <mxGeometry height="80" width="120" x="370" y="320" as="geometry" />
        </mxCell>
        <mxCell id="xhq54t3BPlNCBh4OEzKU-3" edge="1" parent="1" source="xhq54t3BPlNCBh4OEzKU-2" style="curved=1;endArrow=classic;html=1;rounded=0;exitX=0.5;exitY=0;exitDx=0;exitDy=0;entryX=0.5;entryY=1;entryDx=0;entryDy=0;" target="xhq54t3BPlNCBh4OEzKU-1" value="">
          <mxGeometry height="50" relative="1" width="50" as="geometry">
            <Array as="points">
              <mxPoint x="440" y="328" />
              <mxPoint x="390" y="278" />
            </Array>
            <mxPoint x="390" y="328" as="sourcePoint" />
            <mxPoint x="440" y="278" as="targetPoint" />
          </mxGeometry>
        </mxCell>
        <mxCell id="xhq54t3BPlNCBh4OEzKU-4" parent="1" style="text;html=1;whiteSpace=wrap;overflow=hidden;rounded=0;" value="&lt;h1 style=&quot;margin-top: 0px;&quot;&gt;Heading&lt;/h1&gt;&lt;p&gt;Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.&lt;/p&gt;" vertex="1">
          <mxGeometry height="120" width="180" x="40" y="30" as="geometry" />
        </mxCell>
        <mxCell id="xhq54t3BPlNCBh4OEzKU-5" parent="1" style="text;html=1;whiteSpace=wrap;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;rounded=0;" value="Text" vertex="1">
          <mxGeometry height="30" width="60" x="50" y="210" as="geometry" />
        </mxCell>
        <mxCell id="xhq54t3BPlNCBh4OEzKU-6" parent="1" style="align=left;overflow=fill;html=1;dropTarget=0;whiteSpace=wrap;" value="&lt;p style=&quot;margin:0px;margin-top:6px;text-align:center;&quot;&gt;&lt;b&gt;Component&lt;/b&gt;&lt;/p&gt;&lt;hr size=&quot;1&quot; style=&quot;border-style:solid;&quot;/&gt;&lt;p style=&quot;margin:0px;margin-left:8px;&quot;&gt;+ Attribute1: Type&lt;br/&gt;+ Attribute2: Type&lt;/p&gt;" vertex="1">
          <mxGeometry height="90" width="180" x="100" y="330" as="geometry" />
        </mxCell>
        <mxCell id="xhq54t3BPlNCBh4OEzKU-7" parent="xhq54t3BPlNCBh4OEzKU-6" style="shape=component;jettyWidth=8;jettyHeight=4;" value="" vertex="1">
          <mxGeometry height="20" relative="1" width="20" x="1" as="geometry">
            <mxPoint x="-24" y="4" as="offset" />
          </mxGeometry>
        </mxCell>
        <mxCell id="xhq54t3BPlNCBh4OEzKU-8" parent="1" style="verticalAlign=top;align=left;overflow=fill;html=1;whiteSpace=wrap;" value="&lt;p style=&quot;margin:0px;margin-top:4px;text-align:center;&quot;&gt;&lt;i&gt;&amp;lt;&amp;lt;Interface&amp;gt;&amp;gt;&lt;/i&gt;&lt;br/&gt;&lt;b&gt;Interface&lt;/b&gt;&lt;/p&gt;&lt;hr size=&quot;1&quot; style=&quot;border-style:solid;&quot;/&gt;&lt;p style=&quot;margin:0px;margin-left:4px;&quot;&gt;+ field1: Type&lt;br/&gt;+ field2: Type&lt;/p&gt;&lt;hr size=&quot;1&quot; style=&quot;border-style:solid;&quot;/&gt;&lt;p style=&quot;margin:0px;margin-left:4px;&quot;&gt;+ method1(Type): Type&lt;br/&gt;+ method2(Type, Type): Type&lt;/p&gt;" vertex="1">
          <mxGeometry height="140" width="190" x="600" y="220" as="geometry" />
        </mxCell>
        <mxCell id="xhq54t3BPlNCBh4OEzKU-9" parent="1" style="ellipse;shape=umlControl;whiteSpace=wrap;html=1;" value="Control Object" vertex="1">
          <mxGeometry height="80" width="70" x="395" y="470" as="geometry" />
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>`

@Entry
@Component
struct Index {
  @State model: GraphModel = GraphModel.createEmpty()
  @State parseError: string = ''
  @State drawioXml: string = ''
  @State showDrawio: boolean = false

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

  loadDrawio(): void {
    this.showDrawio = true
    this.drawioXml = DRAWIO_TEST_XML
    this.parseError = ''
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
        Button('打开任意bpmn文件')
          .fontSize(14)
          .onClick(() => { this.openBpmnFile() })
        Button('Drawio Demo')
          .fontSize(14)
          .onClick(() => { this.loadDrawio() })
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
        FlowViewer({ drawioXml: this.drawioXml })
          .width('100%')
          .layoutWeight(1)
      } else {
        FlowViewer({ model: this.model })
          .width('100%')
          .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
  }
}