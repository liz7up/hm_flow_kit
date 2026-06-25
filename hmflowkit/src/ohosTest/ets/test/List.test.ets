import graphModelTest from './GraphModel.test';
import bpmnXmlParserTest from './BpmnXmlParser.test';
import canvasManagerTest from './CanvasManager.test';
import hitTestManagerTest from './HitTestManager.test';
import renderConfigTest from './RenderConfig.test';
import bpmnFullCoverageTest from './BpmnFullCoverage.test';
import drawioStyleParserTest from './DrawioStyleParser.test';
import drawioXmlParserTest from './DrawioXmlParser.test';
import shapeDefinitionTest from './ShapeDefinition.test';
import perimeterRouterTest from './PerimeterRouter.test';

export default function testsuite() {
  graphModelTest();
  bpmnXmlParserTest();
  canvasManagerTest();
  hitTestManagerTest();
  renderConfigTest();
  bpmnFullCoverageTest();
  drawioStyleParserTest();
  drawioXmlParserTest();
  shapeDefinitionTest();
  perimeterRouterTest();
}
