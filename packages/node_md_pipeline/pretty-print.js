const { readFile: _readFile, writeFile: _writeFile } = require("fs");
const { promisify } = require("util");

const readFile = promisify(_readFile);
const writeFile = promisify(_writeFile);

Promise.all(
  process.argv
    .slice(2)
    .map((path) =>
      readFile(path).then((buf) =>
        writeFile(path, JSON.stringify(JSON.parse(buf.toString()), null, 2))
      )
    )
).catch(console.error);
