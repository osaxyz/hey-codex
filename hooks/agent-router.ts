/**
 * agent-router.ts — UserPromptSubmit hook for hey-codex auto-delegation.
 *
 * Reads JSON from stdin ({"user_prompt": "..."}) and routes to:
 *   - MUST delegate  → outputs delegation instruction context
 *   - SHOULD delegate → outputs delegation suggestion context
 *   - KEEP           → outputs nothing (exit 0)
 *
 * Must complete within 10 seconds (keyword matching only, no Codex calls).
 */
import * as fs from "fs";
import * as path from "path";

// --- Trigger keywords ---

const CODEX_MUST_TRIGGERS = [
  // Repeated failure
  "また失敗", "still failing", "same error", "まだ動かない",
  "同じエラー", "again failed", "keeps failing",
  // Terminal / CLI
  "bash script", "shell script", "シェルスクリプト",
  "ci/cd", "github actions", "パイプライン", "pipeline",
  "ターミナル", "terminal", "cli tool", "cliツール",
  // Prototype / scaffold
  "プロトタイプ", "prototype", "scaffold", "boilerplate",
  "ボイラープレート", "スキャフォールド",
  // Algorithm optimization
  "アルゴリズム", "algorithm", "最適化", "optimize",
  "計算量", "complexity", "time complexity",
];

const CODEX_SHOULD_TRIGGERS = [
  "設計", "architecture", "design", "アーキテクチャ",
  "レビュー", "review", "セカンドオピニオン", "second opinion",
  "トレードオフ", "trade-off", "tradeoff",
  "race condition", "concurrent", "並行", "並列",
  "api連携", "api integration", "api統合",
  "performance", "パフォーマンス", "ベンチマーク", "benchmark",
];

const KEEP_TRIGGERS = [
  "リファクタ", "refactor", "リファクタリング",
  "migration", "移行", "マイグレーション",
  "セキュリティ", "security", "認証", "auth",
  "暗号", "encrypt", "入力検証", "validation",
];

interface HookInput {
  user_prompt?: string;
  query?: string;
}

interface HookOutput {
  hookSpecificOutput: { message: string };
}

function resolveCouncilSh(): string | null {
  const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();
  const home = process.env.HOME || require("os").homedir();

  const candidates = [
    path.join(projectDir, ".claude", "hey-codex", "scripts", "council.sh"),
    path.join(home, ".claude", "hey-codex", "scripts", "council.sh"),
    path.join(projectDir, "scripts", "council.sh"),
  ];

  for (const candidate of candidates) {
    try {
      if (fs.statSync(candidate).isFile()) return candidate;
    } catch {
      // not found, continue
    }
  }

  return null;
}

function route(prompt: string): HookOutput | null {
  const p = prompt.toLowerCase();

  // KEEP triggers take priority — never delegate these
  for (const t of KEEP_TRIGGERS) {
    if (p.includes(t)) return null;
  }

  // MUST triggers — auto-delegate
  for (const t of CODEX_MUST_TRIGGERS) {
    if (p.includes(t)) {
      const councilPath = resolveCouncilSh();
      const councilInfo = councilPath ? `\n   council.sh: ${councilPath}` : "";
      return {
        hookSpecificOutput: {
          message:
            `[hey-codex] MUST delegate: Codex CLI への自動委譲を推奨します（トリガー: ${t}）\n` +
            `   → council.sh implement でタスクを委譲してください${councilInfo}`,
        },
      };
    }
  }

  // SHOULD triggers — suggest delegation
  for (const t of CODEX_SHOULD_TRIGGERS) {
    if (p.includes(t)) {
      return {
        hookSpecificOutput: {
          message:
            `[hey-codex] SHOULD delegate: Codex CLI に委譲すると効果的かもしれません（トリガー: ${t}）\n` +
            "   → 委譲する場合は「codex に聞いて」と指示してください",
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

  const prompt = stdinData.user_prompt || stdinData.query || "";
  if (!prompt) process.exit(0);

  const result = route(prompt);
  if (result) {
    process.stdout.write(JSON.stringify(result));
  }
}

main();
