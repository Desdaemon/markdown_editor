import { createApp } from "petite-vue";
import renderMathInElement from "katex/dist/contrib/auto-render";
import { DiffDOM, stringToObj } from "diff-dom";

let handle;
type Elm = Partial<HTMLElement>;

function parseTemplate(htmlString: string) {
  return parseTemplate.parser.parseFromString(htmlString, "text/html").body;
}
parseTemplate.parser = new DOMParser();

const workerUrl = new URL("worker.js", import.meta.url);
const worker = new Worker(workerUrl);
const dd = new DiffDOM();
const preview = document.getElementById("preview")!;
const katexOptions = {
  delimiters: [
    { left: "$$", right: "$$", display: true },
    { left: "$", right: "$", display: false },
  ],
  throwOnError: false,
};

let previewTree;
function onWorkerMessage({ data: template }: any) {
  const virtualTemplate = stringToObj(
    `<div id="preview" class="col markdown-body">${template}</div>`
  );
  if (!previewTree) {
    // first time or deleted
    previewTree = virtualTemplate;
    preview.innerHTML = template;
    renderMathInElement(preview, katexOptions);
  } else {
    const diff = dd.diff(previewTree, virtualTemplate);
    previewTree = virtualTemplate;
    dd.apply(preview, diff);
    for (const change of diff) {
      const [changedIndex] = change.route;
      renderMathInElement(
        preview.childNodes[changedIndex] as any,
        katexOptions
      );
    }
  }
}

class App {
  indentCount = 0;
  source = localStorage.getItem("source") || "";
  mounted() {
    document.addEventListener("DOMContentLoaded", () => {
      worker.onmessage = onWorkerMessage;
      this.updatePreview();
    });
  }
  updatePreview(source: string = this.source) {
    if (source) {
      worker.postMessage(source);
    } else {
      preview.innerHTML = "";
      previewTree = null;
    }
  }
  onInput(event: any) {
    this.source = event.target.value;
    localStorage.setItem("source", this.source);
    clearTimeout(handle);
    handle = setTimeout(this.updatePreview.bind(this), 100);
  }
  onKey(event: any) {
    console.log(event);
    event.preventDefault();
  }
  onScroll(event: any) {
    preview.scrollTop =
      event.target.scrollTop *
      (preview.scrollHeight / event.target.scrollHeight);
  }
}
createApp(new App()).mount();
