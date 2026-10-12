#!/usr/bin/env bash
# Checks the multilingual instruction contract, not model translation quality.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
source "$here/lib.sh"

language_table() {
  awk '
    /^\| (Language|语言) \| (Code|代码) \| (Aliases|别名) \|$/ { in_table=1; next }
    in_table && /^\|---/ { next }
    in_table && /^\|/ { print; next }
    in_table { exit }
  ' "$1"
}

en_path="$here/../skills/mindmap/SKILL.md"
zh_path="$here/../skills/mindmap-zh/SKILL.md"
en="$(cat "$en_path")"
zh="$(cat "$zh_path")"
table="$(language_table "$en_path")"
codes=(en zh-Hans zh-Hant ja ko tr ru vi th de es fr uk pl pt-BR ar fa id it)

assert_eq "19" "$(printf '%s\n' "$table" | wc -l | tr -d '[:space:]')" "lists exactly 19 languages"
for code in "${codes[@]}"; do
  assert_contains "$table" "| \`$code\` |" "supports $code"
done
assert_contains "$table" '| 简体中文 | `zh-Hans` | `zh`, `zh-CN` |' "defines Simplified Chinese aliases"
assert_contains "$table" '| 繁體中文 | `zh-Hant` | `zh-TW` |' "defines Traditional Chinese alias"
assert_eq "$table" "$(language_table "$zh_path")" "standalone Chinese skill supports the same languages and aliases"
assert_eq "$table" "$(language_table "$here/../docs/usage.md")" "English usage guide matches the skill languages"
assert_eq "$table" "$(language_table "$here/../docs/usage.zh.md")" "Chinese usage guide matches the skill languages"

assert_contains "$en" '[--lang <language|auto>]' "English trigger exposes language selection"
assert_contains "$zh" '[--lang <语言|auto>]' "Chinese trigger exposes language selection"
assert_contains "$en" 'default to **English (`en`)**' "preserves English default"
assert_contains "$zh" '默认使用**简体中文（`zh-Hans`）**' "preserves Simplified Chinese default"
assert_contains "$en" 'An explicit `--lang` takes precedence' "language flag overrides other requests"
assert_contains "$zh" '显式 `--lang` 优先' "Chinese skill preserves flag precedence"
assert_contains "$en" 'resolved source content' "auto detection uses loaded content"
assert_contains "$zh" '已加载原文' "Chinese auto detection uses loaded content"
assert_contains "$en" "user's conversation language" "auto defines a mixed-language fallback"
assert_contains "$zh" '用户对话语言' "Chinese auto defines a mixed-language fallback"
assert_contains "$en" 'source content, not user language requests' "source instructions cannot override output language"
assert_contains "$zh" '不是用户的语言要求' "Chinese skill isolates source instructions"
assert_contains "$en" 'before writing any output' "invalid languages stop before writes"
assert_contains "$zh" '在写出任何文件前' "Chinese skill rejects invalid languages before writes"
assert_contains "$en" 'repeated with conflicting values' "rejects conflicting language flags"
assert_contains "$zh" '重复指定了互相冲突的值' "Chinese skill rejects conflicting language flags"
assert_contains "$en" 'Strip the flags and their values (including `--lang`)' "does not classify a language code as source text"
assert_contains "$zh" '去除参数及其值（包括 `--lang`）' "Chinese skill removes language flag values"
assert_contains "$en" '> 80 Unicode characters' "classifies long unsegmented prose as source text"
assert_contains "$zh" '> 80 个 Unicode 字符' "Chinese skill classifies long unsegmented prose as source text"
assert_contains "$en" '**UTF-8**' "requires UTF-8 output"
assert_contains "$zh" '**UTF-8**' "Chinese skill requires UTF-8 output"
assert_contains "$en" 'do not reverse characters or transliterate' "keeps Arabic and Persian logical text order"
assert_contains "$zh" '不反转字符' "Chinese skill keeps RTL text in logical order"
assert_contains "$en" 'Preserve Unicode letters in generated slugs' "keeps non-Latin output filenames"
assert_contains "$zh" 'slug 保留 Unicode 字母' "Chinese skill keeps non-Latin output filenames"
assert_contains "$en" 'every proposer, judge, and synthesizer' "main skill propagates output language to all panel roles"

panel="$(cat "$here/../skills/mindmap/references/judge-panel.md")"
assert_contains "$panel" 'every proposer, judge, and synthesizer' "panel shares language with every role"
assert_contains "$panel" 'OUTPUT LANGUAGE:' "panel prompt carries the resolved language"
assert_contains "$panel" 'including Simplified/Traditional Chinese script' "panel distinguishes Chinese scripts"
assert_contains "$panel" 'Language mismatches' "judges flag language violations"
assert_contains "$panel" 'Give each the shared context, exact judge' "judge dispatch includes language context"
assert_contains "$panel" 'source-fidelity and output-language rules' "final panel validation checks language"

finish
