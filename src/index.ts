import { render } from "ink";
import { App } from "./ui/App";
import { createElement } from "react";
import yargs from "yargs";
import { hideBin } from "yargs/helpers";
import { buildTree } from "./buildTree";

const main = () => {
  yargs(hideBin(process.argv))
    .option("path", {
      alias: "p",
      type: "string",
      describe: "The path to start the file explorer from",
    })
    .parseAsync()
    .then((argv) => {
      const basePath = argv.path ?? process.cwd();

      console.log(`Starting file explorer at: ${basePath}`);

      const tree = buildTree(basePath);

      render(createElement(App, { tree, basePath }));
    });
};

main();
