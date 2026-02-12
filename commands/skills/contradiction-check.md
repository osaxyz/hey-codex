# Contradiction Check: AGENTS.md vs CLAUDE.md 矛盾検出

AGENTS.md（Codex向け指示書）と CLAUDE.md（Claude Code向け指示書）の間の矛盾を検出・報告するプロトコル。

## Procedure

### Step 1: Detect Files

プロジェクト内の以下のファイルを探索:

- **CLAUDE.md**: プロジェクトルート、`.claude/CLAUDE.md`、`~/.claude/CLAUDE.md`
- **AGENTS.md**: プロジェクトルート、`.agents/rules/base.md`

### Step 2: Read and Parse

両方のファイルが存在する場合、以下の観点で内容を分析:

1. **コーディング規約**
   - 命名規則（camelCase vs snake_case etc.）
   - フォーマット（インデント、行長、セミコロン etc.）
   - ファイル構成（ディレクトリ構造、命名パターン）

2. **アーキテクチャ方針**
   - 使用フレームワーク・ライブラリ
   - 設計パターン（MVC、Clean Architecture etc.）
   - 依存関係の方針

3. **テスト方針**
   - テストフレームワーク
   - カバレッジ要件
   - テスト命名規則

4. **禁止事項**
   - 使用禁止の技術・パターン
   - セキュリティポリシー
   - パフォーマンスガイドライン

### Step 3: Compare and Detect

各観点について AGENTS.md と CLAUDE.md の記述を比較:

- **矛盾 (Conflict)**: 互いに反する指示がある
- **重複 (Overlap)**: 同じ指示が両方にある（問題なし）
- **補完 (Complement)**: 片方にのみ存在する指示（問題なし）

### Step 4: Report

#### 矛盾が見つかった場合

AskUserQuestion で以下を報告し、どちらに従うか確認:

```markdown
## Contradiction Report

### Found Contradictions

| # | Aspect | AGENTS.md | CLAUDE.md | Impact |
|---|--------|-----------|-----------|--------|
| 1 | [観点] | [AGENTS.mdの指示] | [CLAUDE.mdの指示] | [影響度] |

### Recommendation
[推奨する解決方法]
```

選択肢:
- **AGENTS.md に従う** — Codex実行時はAGENTS.md優先
- **CLAUDE.md に従う** — Claude Code実行時はCLAUDE.md優先
- **統合する** — 両方のファイルを修正して統一
- **場面に応じて使い分ける** — それぞれのAIが自身の指示書に従う

#### 矛盾がない場合

```markdown
## Contradiction Report

No contradictions found between AGENTS.md and CLAUDE.md.

### Summary
- AGENTS.md: [概要]
- CLAUDE.md: [概要]
- Overlapping rules: [重複数]
- Complementary rules: [補完数]

Both files are compatible. Proceeding with both instruction sets.
```
