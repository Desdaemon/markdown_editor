importScripts("marked.min.js");

marked.setOptions({
  gfm: true,
});

onmessage = ({ data }) => {
  if (data) postMessage(marked.parse(data));
};
