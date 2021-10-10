import { unified } from "unified";
import remarkParse from "remark-parse";
import remarkMath from "remark-math";
import remarkVdom from "remark-vdom";
import { readSync } from "to-vfile";

console.error("Initialization done.");

// const file = readSync("markdown_reference.md");
const file = `
# One
## Two

The result of $1+1$ is $2$.

$$
\\int_1^2f(x)dx
$$
`;

unified()
  .use(remarkParse)
  .use(remarkMath)
  .use(remarkVdom)
  .process(file)
  .then((file) => {
    console.dir(file.result, { depth: null });
  });
