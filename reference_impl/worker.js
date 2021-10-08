importScripts("marked.min.js");

onmessage = ({ data }) => {
  if (data) postMessage(marked.parse(data));
};
