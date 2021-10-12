const fs = require("fs");
// const { run, } = require("rust-md");
// run();
const { JSDOM } = require("jsdom");
const { window } = new JSDOM(`
<!DOCTYPE html>
<div id="preview"></div>
<!-- some comment -->
`);

const { document } = window;
global.document = document;

// shims for jsdom, required by snabbdom
document.isElement = (node) => node?.nodeType == document.ELEMENT_NODE;
document.isText = (node) => node?.nodeType == document.TEXT_NODE;
document.tagName = (node) => node?.tagName;
document.isComment = (node) => node?.nodeType == document.COMMENT_NODE;

// const katex = require("katex");
const marked = require("marked");
const {
  toVNode,
  // init,
  // classModule,
  // propsModule,
  // attributesModule,
  // styleModule,
  // datasetModule,
} = require("snabbdom");

const domParser = new window.DOMParser();

// const patch = init([
// classModule,
// propsModule,
// attributesModule,
// styleModule,
// datasetModule,
// ]);

let preview = toVNode(document.getElementById("preview"));
// const updatePreview = (node) => (preview = patch(preview, node));

// const PATTERN = /(\${1,2})([^\0]+?)\1/g;

// function Katex(source, displayMode = false) {
// const span = document.createElement("span");
// katex.render(source, span, { displayMode, throwOnError: false });
// return toVNode(span);
// }

function parse(markdown) {
  if (!markdown) return preview;

  const html = marked(markdown, {
    gfm: true,
    smartypants: true,
    headerIds: false,
  }).replace(/\n/g, "");
  console.log({ html });
  const node = domParser.parseFromString(`<div>${html}</div>`, "text/html").body
    .firstChild;
  const vnode = toVNode(node);
  // updatePreview(vnode);
  return vnode;
}

let contents;
parse.load = function load() {
  if (contents) return contents;
  return (contents = fs.readFileSync("../markdown_reference.md").toString());
};

parse.export = function () {
  const node = this(this.load());
  fs.writeFileSync(
    "markdown_reference.json",
    JSON.stringify(node, function (key, value) {
      if (key == "elm") return undefined;
      return value;
    })
  );
};

module.exports = parse;
parse.export();
