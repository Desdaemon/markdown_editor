// import { unified } from "unified";
// // import remarkMath from "remark-math";
// import remarkParse from "remark-parse/lib";
// import remarkRehype from "remark-rehype";
// // import rehypeKatex from "rehype-katex";
// import rehypeReact from "rehype-react/lib";
// import { h } from "snabbdom";
// // import remarkGfm from "remark-gfm";

// import MarkdownIt from "markdown-it";
// import mk from "markdown-it-katex";
import { toVNode } from "snabbdom";

// const md = MarkdownIt();
// md.use(mk);

// const pipeline = unified()
// .use(remarkParse)
// // .use(remarkMath)
// // .use(remarkGfm)
// .use(remarkRehype)
// // .use(rehypeKatex, { output: "html" })
// .use(rehypeReact, {
// createElement(name, props, ...children) {
// return h(
// name,
// { props: { className: props.class }, attrs: { style: props.style } },
// ...children
// );
// },
// });
//

onmessage = ({ data }) => {
  if (data) {
    const t0 = Date.now();
    const markup = md.render(data, {});
    const result = toVNode(parseTemplate(markup));
    console.log("Processing took", Date.now() - t0, "ms");
    postMessage(result);
  }
};
