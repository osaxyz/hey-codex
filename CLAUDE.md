# hey-codex: Codex CLI Auto-Delegation

Claude Code の hooks と rules による Codex CLI 自動委譲スキルです。

## 仕組み

hooks がイベント駆動で委譲を判定し、rules が常時適用の判断基準を提供します。

### Rules (`rules/codex-delegation.md`)
- 常時適用の委譲判断ルール
- MUST / SHOULD / MUST NOT の3段階で判断

### Hooks (`hooks/`)
| フック | イベント | 役割 |
|--------|----------|------|
| `agent-router.ts` | UserPromptSubmit | プロンプトのキーワードから委譲を判定 |
| `check-codex-before-write.ts` | PreToolUse (Edit\|Write) | CI/CD・シェルスクリプト編集時にリマインド |
| `post-implementation-review.ts` | PostToolUse (Edit\|Write) | 3+ファイル編集後にレビュー提案 |

### council.sh

Codex CLI の実行ラッパー。委譲実行時に使用します。

```bash
# ステータス確認
council.sh status

# 合議（読み取り専用）
council.sh consult /tmp/codex-prompt.txt /path/to/project

# 実装委譲（書き込み可能）
council.sh implement /tmp/codex-prompt.txt /path/to/project
```

パス解決の優先順位:
1. `.claude/hey-codex/scripts/council.sh` (プロジェクトローカル)
2. `~/.claude/hey-codex/scripts/council.sh` (ユーザーグローバル)
3. `scripts/council.sh` (開発時)

## 無効化方法

```bash
# ルールを無効化
rm .claude/rules/codex-delegation.md

# フックを無効化
rm -rf .claude/hooks/hey-codex/

# settings.json から hey-codex フックを手動で削除
```

## Development

```bash
# テスト実行
scripts/council.sh status

# ローカルインストール
bash install.sh
```
