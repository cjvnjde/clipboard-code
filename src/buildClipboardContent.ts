import { readFileSync } from "node:fs";
import { join } from "node:path";
import { getFileType } from "./utils/getFileType";

export function buildClipboardContent(selectedFiles: string[], base: string) {
  let out = "";

  for (const file of selectedFiles) {
    if (file.endsWith("/")) continue;

    const full = join(base, file);
    let fileType = getFileType(file);
    let content;

    try {
      content = readFileSync(full, "utf8");
    } catch (e) {
      content = "[ERROR READING FILE]";
    }

    out += `${file}\n\`\`\`${fileType}\n${content}\n\`\`\`\n\n`;
  }

  return out.trim();
}
