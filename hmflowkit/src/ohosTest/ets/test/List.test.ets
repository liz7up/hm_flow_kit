import graphModelTest from './GraphModel.test';
import bpmnXmlParserTest from './BpmnXmlParser.test';
import canvasManagerTest from './CanvasManager.test';
import hitTestManagerTest from './HitTestManager.test';
import renderConfigTest from './RenderConfig.test';

export default function testsuite() {
  graphModelTest();
  bpmnXmlParserTest();
  canvasManagerTest();
  hitTestManagerTest();
  renderConfigTest();
}
