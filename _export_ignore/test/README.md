# SyntaxHighlighters text tests

Run from the workspace root with Godot 4.6 or newer:

```sh
python3 addons/_lib/syntax_highlighters/_export_ignore/test/run_headless.py --godot godot --export
```

The runner creates two isolated projects containing the SyntaxHighlighters text module and both
suites. One has no GDSh files; the other includes only GDSh's standalone
`src/ui/script_highlighter_logic.gd` provider. No generated namespace, editor addon, or other GDSh
script is needed.

- `dispatcher_test.gd`: extension normalization and discovery, fresh provider instances,
  SyntaxHighlighters palette compatibility, and plain-text fallback when the provider is absent.
- `multiline_cache_test.gd`: multiline entry states follow TextEdit edits (inserted and removed
  lines, whole-text replacement, rebinding to another TextEdit).

`--export` repeats both cases from binary-script PCKs; `--keep` retains the temporary projects.
Inside the editor, run `test res://addons/_lib/syntax_highlighters/_export_ignore/test`.
