#!/usr/bin/env bash
set -euo pipefail

VERSION=${1:?"Usage: $0 <version> [changelog]"}
CHANGELOG=${2:-CHANGELOG.md}

python3 - "$VERSION" "$CHANGELOG" <<'PY'
import html
import pathlib
import re
import sys

version = sys.argv[1]
changelog = pathlib.Path(sys.argv[2])
text = changelog.read_text()

pattern = re.compile(rf"^##\s+\[?{re.escape(version)}\]?.*$", re.M)
match = pattern.search(text)
if not match:
    sys.exit(f"changelog section not found for {version}")

start = match.end()
next_header = text.find("\n## ", start)
section = text[start: next_header if next_header != -1 else len(text)].strip()

items = []
paragraphs = []
for line in section.splitlines():
    line = line.strip()
    if not line:
        continue
    bullet = re.match(r"^[-*]\s+(.*)$", line)
    if bullet:
        items.append(bullet.group(1))
    else:
        paragraphs.append(line)

out = []
if paragraphs:
    out.append("<p>{}</p>".format(html.escape(" ".join(paragraphs))))
if items:
    out.append("<ul>{}</ul>".format("".join(f"<li>{html.escape(item)}</li>" for item in items)))
print("".join(out))
PY
