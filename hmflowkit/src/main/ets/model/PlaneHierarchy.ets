import { GraphModel } from './GraphModel'

export class BreadcrumbEntry {
  processId: string
  label: string

  constructor(processId: string, label: string) {
    this.processId = processId
    this.label = label
  }
}

export class PlaneDefinition {
  diagramId: string
  processId: string
  model: GraphModel
  label: string
  parentProcessId: string

  constructor(diagramId: string, processId: string, model: GraphModel,
              label: string, parentProcessId: string) {
    this.diagramId = diagramId
    this.processId = processId
    this.model = model
    this.label = label
    this.parentProcessId = parentProcessId
  }
}

export class PlaneHierarchy {
  private _planes: Record<string, PlaneDefinition> = {}
  private _rootProcessId: string = ''

  constructor(planes: PlaneDefinition[], rootProcessId: string) {
    this._rootProcessId = rootProcessId
    for (let i = 0; i < planes.length; i++) {
      let p = planes[i]
      this._planes[p.processId] = p
    }
  }

  getPlane(processId: string): PlaneDefinition | null {
    let p = this._planes[processId]
    return p !== undefined ? p : null
  }

  hasPlane(processId: string): boolean {
    return this._planes[processId] !== undefined
  }

  getRootModel(): GraphModel {
    let root = this._planes[this._rootProcessId]
    if (root !== undefined) {
      return root.model
    }
    return GraphModel.createEmpty()
  }

  getRootProcessId(): string {
    return this._rootProcessId
  }

  getBreadcrumbs(processId: string): BreadcrumbEntry[] {
    let result: BreadcrumbEntry[] = []
    let current: string = processId
    let visited: Record<string, boolean> = {}
    // walk parent chain up to root
    while (current.length > 0) {
      if (visited[current]) {
        break // circular guard
      }
      visited[current] = true
      let plane = this._planes[current]
      if (plane === undefined) {
        break
      }
      result.push(new BreadcrumbEntry(plane.processId, plane.label))
      current = plane.parentProcessId
    }
    // reverse so root is first
    let reversed: BreadcrumbEntry[] = []
    for (let i = result.length - 1; i >= 0; i--) {
      reversed.push(result[i])
    }
    return reversed
  }

  getParentProcessId(processId: string): string {
    let plane = this._planes[processId]
    if (plane !== undefined) {
      return plane.parentProcessId
    }
    return ''
  }

  getPlaneCount(): number {
    return Object.keys(this._planes).length
  }
}
