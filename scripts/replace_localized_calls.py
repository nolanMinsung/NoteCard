#!/usr/bin/env python3
"""Replace bare `"...".localized()` calls with L10n.Group.name references."""
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NOTECARD_DIR = os.path.join(ROOT, 'NoteCard')
MAPPING_JSON = '/tmp/l10n_mapping.json'
SKIP_PATHS = [
    os.path.join(NOTECARD_DIR, 'Global', 'Localization'),
]

with open(MAPPING_JSON, 'r', encoding='utf-8') as f:
    mapping = json.load(f)


def swift_string_pattern(key: str) -> str:
    """Build a regex matching the Swift literal for `key`, escaped for the source as written."""
    # Special chars in Swift string literal escapes
    parts = []
    for ch in key:
        if ch == '\\':
            # Match backslash → in source: \\
            parts.append(r'\\\\')
        elif ch == '"':
            parts.append(r'\\"')
        elif ch == '\n':
            parts.append(r'\\n')
        elif ch == '\t':
            parts.append(r'\\t')
        else:
            parts.append(re.escape(ch))
    return '"' + ''.join(parts) + r'"\.localized\(\)'


def main():
    # Sort keys longest first to avoid prefix conflicts (e.g., "취소" being part of a longer string)
    sorted_keys = sorted(mapping.keys(), key=lambda k: -len(k))

    total_replacements = 0
    files_changed = []

    for root, dirs, files in os.walk(NOTECARD_DIR):
        if any(root.startswith(skip) for skip in SKIP_PATHS):
            continue
        for fn in files:
            if not fn.endswith('.swift'):
                continue
            path = os.path.join(root, fn)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            original = content
            file_replacements = 0
            for key in sorted_keys:
                pattern = swift_string_pattern(key)
                replacement = f'L10n.{mapping[key]}'
                new_content, n = re.subn(pattern, replacement, content)
                content = new_content
                file_replacements += n
            if content != original:
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(content)
                files_changed.append((path, file_replacements))
                total_replacements += file_replacements

    print(f"Total replacements: {total_replacements}")
    print(f"Files changed: {len(files_changed)}")
    for path, n in files_changed:
        print(f"  {n:3d}  {os.path.relpath(path, ROOT)}")


if __name__ == '__main__':
    main()
