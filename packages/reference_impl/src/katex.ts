import { toVNode, VNode, thunk } from "snabbdom";
import katex from "katex";

export function Katex(source: string, displayMode = false) {
  const span = document.createElement("span");
  katex.render(source, span, {
    displayMode,
    throwOnError: false,
  });
  return toVNode(span);
}

export function visitChildren(
  children: (string | VNode)[],
  parseKatex = true
): (string | VNode)[] {
  const ret: (string | VNode)[] = [];
  for (const child of children) {
    const isString = typeof child === "string";
    const text = isString ? child : child.text;
    if (text) {
      let display: boolean | undefined;
      if (parseKatex) {
        for (const section of text.split(KATEX_RE)) {
          if (display !== undefined) {
            ret.push(thunk("span", Katex, [section, display]));
            display = undefined;
          } else if (section === "$$") {
            display = true;
          } else if (section === "$") {
            display = false;
          } else {
            ret.push({ text: section } as any);
          }
        }
      } else {
        ret.push({ text } as any);
      }
    } else {
      if (isString) continue;
      const _parseKatex =
        parseKatex &&
        (!child.sel || !KATEX_IGNORE.some((e) => child.sel!.startsWith(e)));
      if (child.children?.length) {
        const children = visitChildren(child.children, _parseKatex);
        ret.push({ ...child, children });
      } else if (child.text?.length) {
        const children = visitChildren([child.text], _parseKatex);
        ret.push({ ...child, children });
      } else {
        ret.push(child);
      }
    }
  }
  return ret;
}

const KATEX_RE = /(\${1,2})([^\0]+?)\1/g;
const KATEX_IGNORE = [
  "script",
  "noscript",
  "style",
  "textarea",
  "pre",
  "code",
  "option",
];

