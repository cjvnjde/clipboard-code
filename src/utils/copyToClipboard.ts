import { spawn } from "node:child_process";

export function copyToClipboard(content: string) {
  spawn("wl-copy", [content], { stdio: "ignore" }).on("error", () => {
    console.error(
      "Failed to copy to clipboard. Make sure 'wl-copy' is installed.",
    );
  });

  console.log("Copied selected files to clipboard!");
}
