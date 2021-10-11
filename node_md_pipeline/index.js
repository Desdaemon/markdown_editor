const { JSDOM } = require("jsdom");
const { window } = new JSDOM(`
<!DOCTYPE html>
<p>Hello there.</p>
`);
const { document } = window;
const stub =
  (name) =>
  (...args) =>
    console.error("todo", name, ...args);
document.isElement = (node) => {
  stub("isElement", node);
  return !document.isText(node);
};
document.isText = (node) => {
  stub("isText", node);
  return !node.childNodes.length && node.textContent;
};
document.isComment = stub("isComment");
// const katex = require("katex");
const marked = require("marked");
const { init, toVNode: _toVNode } = require("snabbdom");

const toVNode = (node) => _toVNode(node, document);
const domParser = new window.DOMParser();

const patch = init([]);

let preview = toVNode(document.getElementById("preview"));
const updatePreview = (node) => (preview = patch(preview, node));

// function Katex(source, displayMode = false) {
// const span = document.createElement("span");
// katex.render(source, span, { displayMode, throwOnError: false });
// return toVNode(span);
// }

module.exports = function parse(markdown) {
  const xml = marked(markdown, { gfm: true });
  const vnode = toVNode(domParser.parseFromString(xml, "text/html"));
  updatePreview(vnode);
  console.dir(preview, { depth: null });
};
