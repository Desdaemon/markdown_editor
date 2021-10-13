import { createApp } from "petite-vue";
import { VNode, h, thunk, toVNode } from "snabbdom";
import { createVirtualRoot } from "./utils";
import { render as renderKatexInElm } from "katex";
import "./markdown.css";

const PREVIEW_SEL = "div#preview.col.markdown-body";
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
let REFERENCE: string;

function parseTemplate(template: string) {
  return parseTemplate.parser.parseFromString(template, "text/html").body;
}
parseTemplate.parser = new DOMParser();

let [preview, updatePreview] = createVirtualRoot("preview");
const editor = document.getElementById("editor")!;

function Katex(source: string, displayMode = false) {
  const span = document.createElement("span");
  renderKatexInElm(source, span, {
    displayMode,
    throwOnError: false,
  });
  return toVNode(span);
}

function visitChildren(
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

function renderKatex(template: VNode) {
  if (template.children) {
    const children = visitChildren(template.children);
    updatePreview({ ...template, children });
  }
}

let handle: any;
class App {
  indentCount = 0;
  responseTime = 0;
  source = localStorage.getItem("source") || "";
  mounted() {
    document.addEventListener("DOMContentLoaded", () => {
      this.renderPreview();
    });
  }
  async renderPreview(source = this.source) {
    const t0 = performance.now();
    if (source) {
      const { parse_vdom } = await import("rust-md");
      // import("rust-md").then(({ parse_vdom }) => {
      const template = parse_vdom(source);
      template.sel = PREVIEW_SEL;
      template.data ??= {};
      renderKatex(template);
      this.responseTime = performance.now() - t0;
      // });
    } else {
      updatePreview(h(PREVIEW_SEL, {}, []));
    }
  }
  onInput(event: any) {
    this.source = event.target.value;
    localStorage.setItem("source", this.source);
    clearTimeout(handle);
    handle = setTimeout(this.renderPreview.bind(this), 100);
  }
  onKey(event: any) {
    console.log(event);
    event.preventDefault();
  }
  onScroll(event?: any) {
    const target = event?.target || editor;
    const elm: any = preview.elm!;
    elm.scrollTop = target.scrollTop * (elm.scrollHeight / target.scrollHeight);
  }
  async stressTest() {
    REFERENCE ??= await fetch(
      new URL("../../markdown_reference.md", import.meta.url).toString()
    ).then((e) => e.text());
    this.source = REFERENCE;
    await this.renderPreview();
  }
}
createApp(new App()).mount();
