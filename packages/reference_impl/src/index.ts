import { createApp } from "petite-vue";
import { VNode, h } from "snabbdom";
import initWasm, { parse_vdom } from "rust-md";
import { createVirtualRoot } from "./utils";
// import katex from "katex";

let initDone = false;
let prom = initWasm().then(() => (initDone = true));

function parseTemplate(template: string) {
  return parseTemplate.parser.parseFromString(template, "text/html").body;
}
parseTemplate.parser = new DOMParser();

// const transformKatex = (template: string) =>
// template.replace(transformKatex.pattern, transformKatex.replace);
// transformKatex.pattern = /(\${1,2})([^ ].*?[^ ])\1/g;
// transformKatex.replace = (_: any, delimiter: string, tex: string) => {
// const displayMode = delimiter.length == 2;
// return katex.renderToString(tex, { displayMode, throwOnError: false });
// };

let [preview, updatePreview] = createVirtualRoot("preview");
const editor = document.getElementById("editor")!;

declare global {
  interface String {
    hashCode(): number;
  }
}
String.prototype.hashCode = function () {
  var hash = 0,
    i,
    chr;
  if (this.length === 0) return hash;
  for (i = 0; i < this.length; i++) {
    chr = this.charCodeAt(i);
    hash = (hash << 5) - hash + chr;
    hash |= 0; // Convert to 32bit integer
  }
  return hash;
};

let handle: any;

class App {
  indentCount = 0;
  source = localStorage.getItem("source") || "";
  mounted() {
    document.addEventListener("DOMContentLoaded", () => {
      this.renderPreview();
    });
  }
  async renderPreview(source = this.source) {
    if (source) {
      let template: VNode;
      if (initDone) {
        template = parse_vdom(source);
      } else {
        await prom;
        template = parse_vdom(source);
      }
      template.sel = "div#preview.col.markdown-body";
      updatePreview(template);
    } else {
      updatePreview(h("div#preview.col.markdown-body", null, []));
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
}
createApp(new App()).mount();
