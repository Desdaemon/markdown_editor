import {
  VNode,
  init,
  classModule,
  attributesModule,
  styleModule,
} from "snabbdom";

export const patch = init([classModule, attributesModule, styleModule]);

export function createVirtualRoot(id: string): [VNode, (node: VNode) => void] {
  let root: any;
  const updateRoot = (node: VNode) =>
    (root = patch(root ?? document.getElementById(id), node));
  return [root, updateRoot];
}
