let handle;

const KATEX_ATTR = "data-katex-hash";
const preview = document.getElementById("preview");
const katexOptions = {
  delimiters: [
    { left: "$$", right: "$$", display: true },
    { left: "$", right: "$", display: false },
  ],
  // throwOnError: false
};

function parseTemplate(htmlString) {
  return parseTemplate.parser.parseFromString(htmlString, "text/html").body;
}
parseTemplate.parser = new DOMParser();

function nodeType(node) {
  switch (node.nodeType) {
    case 3:
      return "span";
    case 8:
      return "comment";
    default:
      return node.tagName.toLowerCase();
  }
}

function nodeContent(node) {
  return node.hasChildNodes() ? null : node.textContent;
}

/**
 * @param {string} str
 */
function hashCode(str) {
  var hash = 0,
    i,
    chr;
  if (str.length === 0) return hash;
  for (i = 0; i < str.length; i++) {
    chr = str.charCodeAt(i);
    hash = (hash << 5) - hash + chr;
    hash |= 0; // Convert to 32bit integer
  }
  return hash;
}

function katexHashMatches(textContent, dom) {
  if (!(dom && textContent && textContent.startsWith("$"))) return false;
  const attr = dom.getAttribute?.(KATEX_ATTR);
  const N = textContent.length;
  const ret =
    attr == hashCode(textContent.substring(1, N - 1)) ||
    attr == hashCode(textContent.substring(2, N - 2));
  if (!ret) dom.removeAttribute?.(KATEX_ATTR);
  return ret;
}

// see https://gomakethings.com/dom-diffing-with-vanilla-js/
function diff(template, elem) {
  const domNodes = elem.childNodes;
  const templateNodes = template.childNodes;
  //   const domNodes = Array.prototype.slice.call(elem.childNodes);
  //   const templateNodes = Array.prototype.slice.call(template.childNodes);
  for (let count = domNodes.length - templateNodes.length; count > 0; count--) {
    // this seems filthy...
    domNodes[domNodes.length - count].parentNode.removeChild(
      domNodes[domNodes.length - count]
    );
  }
  templateNodes.forEach((node, index) => {
    if (!domNodes[index]) {
      // add if missing
      elem.appendChild(node.cloneNode(true));
    } else if (nodeType(node) != nodeType(domNodes[index])) {
      // replace if type changed
      domNodes[index].parentNode.replaceChild(
        node.cloneNode(true),
        domNodes[index]
      );
    } else {
      const domNode = domNodes[index];
      // replace text content
      const content = nodeContent(node);
      const katexChanged = !katexHashMatches(content, domNode);
      if (content && katexChanged && content !== nodeContent(domNode)) {
        domNodes[index].textContent = content;
      }

      const domNodeHasChild = domNode.hasChildNodes();
      const nodeHasChild = node.hasChildNodes();
      if (domNodeHasChild && !nodeHasChild && katexChanged) {
        // wipe
        domNode.textContent = node.textContent;
      } else if (!domNodeHasChild && nodeHasChild) {
        // new children
        const fragment = document.createDocumentFragment();
        diff(node, fragment);
        domNode.appendChild(fragment);
      } else if (nodeHasChild) {
        // recursively diff
        diff(node, domNode);
      }
    }
  });
}

const app = {
  indentCount: 0,
  source: localStorage.getItem("source"),
  mounted() {
    document.addEventListener("DOMContentLoaded", () => {
      const superRender = katex.render;
      katex.render = function attachHash(math, el, opts) {
        superRender(math, el, opts);
        el.setAttribute(KATEX_ATTR, hashCode(math).toString());
      };
      this.updatePreview();
    });
  },
  updatePreview(source = this.source) {
    if (source) {
      const template = marked.parse(source);
      const elm = parseTemplate(template);
      try {
        diff(elm, preview);
        renderMathInElement(preview, katexOptions);
      } catch (e) {
        alert(e.message);
      }
    } else {
      preview.innerHTML = "";
    }
  },
  onInput(event) {
    clearTimeout(handle);
    handle = setTimeout(() => {
      this.source = event.target.value;
      this.updatePreview();
      localStorage.setItem("source", this.source);
    }, 100);
  },
  onKey(event) {
    console.log(event);
    event.preventDefault();
  },
  onScroll(event) {
    preview.scrollTop =
      event.target.scrollTop *
      (preview.scrollHeight / event.target.scrollHeight);
  },
};
PetiteVue.createApp(app).mount();
