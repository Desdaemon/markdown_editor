import {
  VNode,
  init,
  classModule,
  attributesModule,
  styleModule,
  toVNode,
} from "snabbdom";

export const patch = init([classModule, attributesModule, styleModule]);

export function createVirtualRoot(
  id: string
): [root: VNode, update: (node: VNode) => VNode] {
  let root = toVNode(document.getElementById(id)!);
  const updateRoot = (node: VNode) => (root = patch(root, node));
  return [root, updateRoot];
}
