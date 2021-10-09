import marked from "marked";

marked.setOptions({ gfm: true });

onmessage = ({ data }) => {
  if (data) postMessage(marked(data));
};
