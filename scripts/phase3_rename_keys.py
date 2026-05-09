#!/usr/bin/env python3
"""Phase 3: rename xcstrings keys from Korean natural-language → '<group>.<identifier>' English keys.

Also regenerates L10n.swift to use the new keys as the lookup string.
"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'scripts'))
from generate_l10n import GROUPS, IDENTIFIERS  # type: ignore

XCSTRINGS = os.path.join(ROOT, 'NoteCard/Localizable.xcstrings')
OUTPUT_SWIFT = os.path.join(ROOT, 'NoteCard/Global/Localization/L10n.swift')


def group_lower(group: str) -> str:
    # Convert PascalCase group to camelCase for key prefix
    return group[0].lower() + group[1:]


def build_korean_to_english_key():
    """Map old Korean key → new English '<group>.<identifier>' key."""
    mapping = {}
    for group, keys in GROUPS.items():
        prefix = group_lower(group)
        for k in keys:
            ident = IDENTIFIERS[k]
            mapping[k] = f"{prefix}.{ident}"
    return mapping


def main():
    with open(XCSTRINGS, 'r', encoding='utf-8') as f:
        data = json.load(f)

    ko_to_en = build_korean_to_english_key()

    # Sanity: every key in xcstrings must have a mapping
    missing = set(data['strings'].keys()) - set(ko_to_en.keys())
    if missing:
        print("Keys in xcstrings missing from mapping:")
        for m in missing:
            print(f"  {m!r}")
        raise SystemExit(1)

    # Build new strings dict with renamed keys
    new_strings = {}
    for old_key, entry in data['strings'].items():
        new_key = ko_to_en[old_key]
        new_strings[new_key] = entry

    data['strings'] = new_strings
    data['sourceLanguage'] = 'en'

    with open(XCSTRINGS, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"Renamed {len(new_strings)} keys in {os.path.relpath(XCSTRINGS, ROOT)}")

    # Regenerate L10n.swift with new keys as lookup strings
    lines = [
        "import Foundation",
        "",
        "/// Type-safe wrapper around Localizable.xcstrings.",
        "/// Use `L10n.<group>.<name>` instead of bare `\"...\".localized()` for compile-time safety.",
        "enum L10n {",
    ]
    for group in GROUPS:
        prefix = group_lower(group)
        lines.append(f"    enum {group} {{")
        for old_key in GROUPS[group]:
            ident = IDENTIFIERS[old_key]
            new_key = f"{prefix}.{ident}"
            lines.append(f'        static let {ident} = "{new_key}".localized()')
        lines.append("    }")
        lines.append("")
    lines.append("}")
    lines.append("")

    with open(OUTPUT_SWIFT, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))
    print(f"Regenerated {os.path.relpath(OUTPUT_SWIFT, ROOT)}")


if __name__ == '__main__':
    main()
