import { createApp } from "petite-vue";
import { VNode, h } from "snabbdom";
import { createVirtualRoot } from "./utils";
import "./markdown.css";
import { visitChildren } from "./katex";

const PREVIEW_SEL = "div#preview.col.markdown-body";
let REFERENCE: string;

function parseTemplate(template: string) {
  return parseTemplate.parser.parseFromString(template, "text/html").body;
}
parseTemplate.parser = new DOMParser();

let [preview, updatePreview] = createVirtualRoot("preview");
const editor = document.getElementById("editor")!;

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
      const template = parse_vdom(source) ?? { children: [] };
      template.sel = PREVIEW_SEL;
      template.data ??= {};
      renderKatex(template as VNode);
      this.responseTime = performance.now() - t0;
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
