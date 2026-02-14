/**
 * check-codex-before-write.ts — PreToolUse (Edit|Write) hook for hey-codex.
 *
 * Checks the target file path before write operations and provides
 * advisory reminders about Codex delegation for specific file types:
 *
 *   - .github/workflows/*  → CI/CD → MUST delegate reminder
 *   - *.sh, *.bash          → Shell scripts → MUST delegate reminder
 *   - Dockerfile, docker-*  → Infrastructure → SHOULD delegate reminder
 *
 * Advisory only — does NOT block the write operation.
 */
import * as fs from "fs";
import * as path from "path";

// File path patterns and their delegation levels
const MUST_DELEGATE_PATTERNS: Record<string, string> = {
  ".github/workflows/": "CI/CD パイプライン",
  ".github/actions/": "GitHub Actions",
};

const MUST_DELEGATE_EXTENSIONS: Record<string, string> = {
  ".sh": "シェルスクリプト",
  ".bash": "Bash スクリプト",
};

const SHOULD_DELEGATE_FILENAMES: Record<string, string> = {
  "Dockerfile": "Docker コンテナ",
  "docker-compose.yml": "Docker Compose",
  "docker-compose.yaml": "Docker Compose",
};

const SHOULD_DELEGATE_PREFIXES: Record<string, string> = {
  "docker-compose": "Docker Compose",
  "Dockerfile": "Dockerfile",
};

interface HookInput {
  tool_input?: { file_path?: string; path?: string };
}

interface HookOutput {
  hookSpecificOutput: { message: string };
}

function checkFilePath(filePath: string): HookOutput | null {
  if (!filePath) return null;

  // Normalize path
  const normalized = filePath.replace(/\\/g, "/");
  const basename = path.basename(normalized);
  const ext = path.extname(basename);

  // MUST delegate: CI/CD paths
  for (const [pattern, label] of Object.entries(MUST_DELEGATE_PATTERNS)) {
    if (normalized.includes(pattern)) {
      return {
        hookSpecificOutput: {
          message:
            `[hey-codex] MUST delegate: ${label}の変更を検出しました\n` +
            `   → ファイル: ${filePath}\n` +
            "   → Codex CLI (council.sh implement) への委譲を検討してください\n" +
            "   → ターミナル操作は Codex が +11.9pt 優位です",
        },
      };
    }
  }

  // MUST delegate: Shell scripts
  if (ext in MUST_DELEGATE_EXTENSIONS) {
    const label = MUST_DELEGATE_EXTENSIONS[ext];
    return {
      hookSpecificOutput: {
        message:
          `[hey-codex] MUST delegate: ${label}の変更を検出しました\n` +
          `   → ファイル: ${filePath}\n` +
          "   → Codex CLI (council.sh implement) への委譲を検討してください",
      },
    };
  }

  // SHOULD delegate: Docker files
  if (basename in SHOULD_DELEGATE_FILENAMES) {
    const label = SHOULD_DELEGATE_FILENAMES[basename];
    return {
      hookSpecificOutput: {
        message:
          `[hey-codex] SHOULD delegate: ${label}の変更を検出しました\n` +
          `   → ファイル: ${filePath}\n` +
          "   → Codex CLI に委譲すると効果的かもしれません",
      },
    };
  }

  for (const [prefix, label] of Object.entries(SHOULD_DELEGATE_PREFIXES)) {
    if (basename.startsWith(prefix)) {
      return {
        hookSpecificOutput: {
          message:
            `[hey-codex] SHOULD delegate: ${label}の変更を検出しました\n` +
            `   → ファイル: ${filePath}\n` +
            "   → Codex CLI に委譲すると効果的かもしれません",
        },
      };
    }
  }

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

  const result = checkFilePath(filePath);
  if (result) {
    process.stdout.write(JSON.stringify(result));
  }
}

main();
