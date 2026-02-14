/**
 * post-implementation-review.ts — PostToolUse (Edit|Write) hook for hey-codex.
 *
 * Tracks edit counts per session and suggests Codex review:
 *   - 3+ file edits → suggest Codex review
 *   - CI/CD or shell script writes → suggest verification
 *
 * Uses /tmp/hey-codex-edit-count-{PPID} for tracking.
 * Advisory only — does NOT block operations.
 */
import * as fs from "fs";
import * as path from "path";

const EDIT_COUNT_DIR = "/tmp";
const REVIEW_THRESHOLD = 3;

// File types that warrant immediate verification suggestion
const VERIFY_PATTERNS: Record<string, string> = {
  ".github/workflows/": "CI/CD パイプライン",
  ".github/actions/": "GitHub Actions",
};

const VERIFY_EXTENSIONS: Record<string, string> = {
  ".sh": "シェルスクリプト",
  ".bash": "Bash スクリプト",
};

interface HookInput {
  tool_input?: { file_path?: string; path?: string };
}

interface HookOutput {
  hookSpecificOutput: { message: string };
}

function getCountFile(): string {
  const ppid = process.ppid;
  return path.join(EDIT_COUNT_DIR, `hey-codex-edit-count-${ppid}`);
}

function getEditedFiles(countFile: string): string[] {
  try {
    if (!fs.existsSync(countFile)) return [];
    const content = fs.readFileSync(countFile, "utf-8");
    return content.split("\n").filter((line) => line.trim() !== "");
  } catch {
    return [];
  }
}

function addEditedFile(countFile: string, filePath: string): void {
  try {
    fs.appendFileSync(countFile, filePath + "\n");
  } catch {
    // ignore write errors
  }
}

function checkVerifySuggestion(filePath: string): string | null {
  const normalized = filePath.replace(/\\/g, "/");
  const basename = path.basename(normalized);
  const ext = path.extname(basename);

  for (const [pattern, label] of Object.entries(VERIFY_PATTERNS)) {
    if (normalized.includes(pattern)) return label;
  }

  if (ext in VERIFY_EXTENSIONS) return VERIFY_EXTENSIONS[ext];

  return null;
}

function main() {
  let stdinData: HookInput;
  try {
    const raw = fs.readFileSync("/dev/stdin", "utf-8");
    stdinData = JSON.parse(raw);
  } catch {
    process.exit(0);
  }

  const toolInput = stdinData.tool_input || {};
  const filePath = toolInput.file_path || toolInput.path || "";

  if (!filePath) process.exit(0);

  const countFile = getCountFile();
  const editedFiles = getEditedFiles(countFile);

  // Track this edit (deduplicate)
  if (!editedFiles.includes(filePath)) {
    addEditedFile(countFile, filePath);
    editedFiles.push(filePath);
  }

  const messages: string[] = [];

  // Check for verification-worthy file types
  const verifyLabel = checkVerifySuggestion(filePath);
  if (verifyLabel) {
    messages.push(
      `[hey-codex] ${verifyLabel}を変更しました。` +
        " Codex CLI (council.sh consult) で検証することを推奨します"
    );
  }

  // Check edit count threshold
  const uniqueFiles = new Set(editedFiles).size;
  if (uniqueFiles === REVIEW_THRESHOLD) {
    messages.push(
      `[hey-codex] ${uniqueFiles} ファイルを編集しました。` +
        " Codex CLI にレビューを依頼すると品質向上に効果的です\n" +
        "   → council.sh consult でレビューを依頼できます"
    );
  }

  if (messages.length > 0) {
    const result: HookOutput = {
      hookSpecificOutput: {
        message: messages.join("\n"),
      },
    };
    process.stdout.write(JSON.stringify(result));
  }
}

main();
