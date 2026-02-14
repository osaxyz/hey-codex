---
description: Codex CLI への自動委譲ルール（常時適用）
globs:
alwaysApply: true
---

# Codex CLI 委譲ルール

council.sh を使用して Codex CLI にタスクを委譲するための判断基準。
このルールは常時適用され、Claude Code が自動的に判断を行う。

## council.sh の呼び出し手順

1. プロンプトファイルを `/tmp/codex-prompt-XXXXX.txt` に書き出す
2. council.sh のパスを以下の優先順位で解決:
   - `.claude/hey-codex/scripts/council.sh` (プロジェクトローカル)
   - `~/.claude/hey-codex/scripts/council.sh` (ユーザーグローバル)
   - `scripts/council.sh` (開発時)
3. `council.sh <mode> <prompt_file> <workdir>` を実行
4. 結果を検証し、Codex Council Report フォーマットで報告

## MUST delegate（自動委譲）

以下の **いずれか** に該当する場合、Codex に自動委譲せよ:

1. 同じ問題への修正を 2回以上試みて失敗した
2. ターミナルスクリプト / CLI ツール / CI パイプラインの生成タスクである
3. 新規ファイル群のプロトタイプ生成（既存コードへの影響なし）
4. アルゴリズム最適化・計算量削減が主目的

**実行**: `council.sh implement <prompt_file> <workdir>`

## SHOULD delegate（確認後委譲）

以下のいずれかに該当する場合、ユーザーに「Codex に委譲しますか？」と確認せよ:

- 計画（plan）完了後のセカンドオピニオン
- 3ファイル以上にまたがる新機能の実装フェーズ
- レースコンディション / 並行処理のデバッグ
- 外部 API 統合のボイラープレート生成
- パフォーマンス分析・改善提案

**実行**: ユーザー承認後 `council.sh consult` または `council.sh implement`

## MUST NOT delegate（委譲禁止）

以下の場合は必ず自分（Claude）で処理せよ:

- 既存コードの大規模リファクタリング（グローバル整合性が必要）
- レガシーコード移行
- セキュリティ関連の変更（認証、暗号化、入力検証）
- 巨大コードベースの全体解析（1M コンテキスト活用）
- 単純な 1ファイル編集（タイポ修正、import 追加等）

## 委譲時の共通プロトコル

- **言語**: Codex への指示は英語（推論精度向上）、ユーザーへの報告は日本語
- **実行モード**: 分析のみ → `consult` (read-only)、実装委譲 → `implement` (workspace-write)
- **結果検証**: Codex の出力は必ず Claude が検証してからユーザーに提示
- **報告形式**: Codex Council Report フォーマット

## 無効化方法

この自動委譲を無効にするには:
- このファイル (`rules/codex-delegation.md`) を削除する
- または `alwaysApply: false` に変更する
