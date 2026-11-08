#!/usr/bin/env python3
"""Documentation cross-reference check for the blueprint (standard library only).

Usage:
    python3 -I tool/check_docs.py            # check the repository this script lives in
    python3 -I tool/check_docs.py --refs     # also list every section reference with its target heading
    python3 -I tool/check_docs.py <root>     # check another checkout

Fails (exit 1) when a reference does not resolve:
  * `NN §n` / `docs/NN-name.md §n` / `ARCHITECTURE §n` / `AGENTS §n` / `library spec §n` / bare `§n`
    must point at a numbered `## n. Title` heading that exists;
  * every ADR id (D-nnn) used anywhere is defined in DECISIONS.md as `### D-nnn`;
  * every requirement (P-nn), quality target (Q-n), screen (U-nn) and risk (Rn) used anywhere is defined
    in its spec;
  * every milestone id (M0.1, S1, G0, D1, Y3, ...) used anywhere is defined in MILESTONES.md;
  * every `file.md` named in backticks exists, unless it is on the future-file list below.

Agents: run this after editing any document, and fix the document, not the script, unless the document
conventions themselves changed.
"""
import os
import re
import sys

args = [a for a in sys.argv[1:] if not a.startswith("--")]
SHOW_REFS = "--refs" in sys.argv
ROOT = args[0] if args else os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

DOC_BY_NUM = {
    "01": "docs/01-product-spec.md",
    "02": "docs/02-ux-spec.md",
    "03": "docs/03-engine-spec.md",
    "04": "docs/04-library-spec.md",
    "05": "docs/05-android-platform-spec.md",
    "06": "docs/06-direct-output-spec.md",
    "07": "docs/07-sources-spec.md",
    "08": "docs/08-testing-spec.md",
    "09": "docs/09-design-handoff.md",
    "10": "docs/10-risks.md",
}
NAMED = {"ARCHITECTURE": "ARCHITECTURE.md", "AGENTS": "AGENTS.md"}
# Files that docs may mention before they exist (created by milestone items).
FUTURE_OK = {"docs/release.md", "docs/dev-environment.md"}
FUTURE_DIRS = ("docs/spikes/", "docs/device-notes/", "docs/human-checks/")

md_files = []
for dirpath, _dirs, files in os.walk(ROOT):
    rel_parts = [p for p in os.path.relpath(dirpath, ROOT).split(os.sep) if p not in (".", "")]
    if any(part.startswith(".") for part in rel_parts):
        continue  # skip hidden directories such as .git and .dart_tool
    for name in files:
        if name.endswith(".md"):
            md_files.append(os.path.relpath(os.path.join(dirpath, name), ROOT))
md_files.sort()


def read_lines(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8") as handle:
        return handle.read().split("\n")


lines = {f: read_lines(f) for f in md_files}
headings = {}
for f in md_files:
    found = {}
    for text in lines[f]:
        m = re.match(r"^##\s+(\d+)\.\s+(.*)$", text)
        if m:
            found[int(m.group(1))] = m.group(2).strip()
    headings[f] = found

problems = []
listing = []


def parse_nums(text):
    """'§3, §6, §13' / '§2–3' / '§6–8, §10' / '§2 and §9' -> [3, 6, 13] etc."""
    out = []
    for m in re.finditer(r"§\s*(\d+)(?:\s*[–-]\s*(\d+))?", text):
        a = int(m.group(1))
        b = int(m.group(2)) if m.group(2) else None
        out.extend(range(a, b + 1) if b else [a])
    return out


def check_ref(src, lineno, doc, nums, raw):
    if doc not in headings:
        problems.append(f"{src}:{lineno}: '{raw}' points at a document that does not exist ({doc})")
        return
    for n in nums:
        if n not in headings[doc]:
            problems.append(f"{src}:{lineno}: '{raw}' -> {doc} has no section {n}")
        else:
            listing.append((src, lineno, raw, doc, n, headings[doc][n]))


RUN = r"((?:§\s*\d+(?:\s*[–-]\s*\d+)?)(?:(?:,|\s+and)\s*§\s*\d+(?:\s*[–-]\s*\d+)?)*)"
PAT_PATH = re.compile(r"docs/(0[1-9]|10)-[a-z-]+\.md`?\s*" + RUN)
PAT_NAMED = re.compile(r"\b(ARCHITECTURE|AGENTS)(?:\.md)?`?\s*" + RUN)
PAT_SPEC = re.compile(r"\b(library|engine) spec\s*" + RUN)
PAT_NUM = re.compile(r"\b(0[1-9]|10)\s+" + RUN)

for f in md_files:
    for i, text in enumerate(lines[f], 1):
        used_spans = []
        for m in PAT_PATH.finditer(text):
            check_ref(f, i, DOC_BY_NUM[m.group(1)], parse_nums(m.group(2)), m.group(0))
            used_spans.append(m.span(2))
        for m in PAT_NAMED.finditer(text):
            check_ref(f, i, NAMED[m.group(1)], parse_nums(m.group(2)), m.group(0))
            used_spans.append(m.span(2))
        for m in PAT_SPEC.finditer(text):
            doc = DOC_BY_NUM["04"] if m.group(1) == "library" else DOC_BY_NUM["03"]
            check_ref(f, i, doc, parse_nums(m.group(2)), m.group(0))
            used_spans.append(m.span(2))
        for m in PAT_NUM.finditer(text):
            if any(a <= m.start(2) < b for a, b in used_spans):
                continue
            check_ref(f, i, DOC_BY_NUM[m.group(1)], parse_nums(m.group(2)), m.group(0))
            used_spans.append(m.span(2))
        for m in re.finditer(r"§\s*(\d+)(?:\s*[–-]\s*(\d+))?", text):
            if any(a <= m.start() < b for a, b in used_spans):
                continue
            a = int(m.group(1))
            b = int(m.group(2)) if m.group(2) else None
            check_ref(f, i, f, list(range(a, b + 1)) if b else [a], "local " + m.group(0))


def defined(pattern, files):
    ids = set()
    for f in files:
        for text in lines.get(f, []):
            for m in re.finditer(pattern, text):
                ids.add(m.group(1))
    return ids


def used(pattern):
    ids = {}
    for f in md_files:
        for i, text in enumerate(lines[f], 1):
            for m in re.finditer(pattern, text):
                ids.setdefault(m.group(1), []).append(f"{f}:{i}")
    return ids


def require(kind, pattern, defined_ids):
    for key, where in sorted(used(pattern).items()):
        if key not in defined_ids:
            problems.append(f"{kind} {key} is used at {where[:3]} but not defined")


require("ADR", r"\b(D-0\d\d)\b", defined(r"^###\s+(D-0\d\d)\b", ["DECISIONS.md"]))
p_ids = defined(r"^\|\s*(P-\d\d)\s*\|", ["docs/01-product-spec.md"]) | defined(
    r"^-\s+(P-\d\d)\b", ["docs/01-product-spec.md"]
)
require("Requirement", r"\b(P-\d\d)\b", p_ids)
require("Quality target", r"\b(Q-\d)\b", defined(r"^\|\s*(Q-\d)\s*\|", ["docs/01-product-spec.md"]))
require("Screen", r"\b(U-\d\d)\b", defined(r"^\|\s*(U-\d\d)\s*\|", ["docs/02-ux-spec.md"]))
require("Risk", r"\b(R\d{1,2})\b", defined(r"^\|\s*(R\d+)\s*\|", ["docs/10-risks.md"]))

milestone_ids = set()
for text in lines.get("MILESTONES.md", []):
    for m in re.finditer(r"\*\*((?:M\d\.\d+|S\d|G\d|D\d|Y\d|X\d)\b)", text):
        milestone_ids.add(m.group(1))
    m = re.match(r"^##\s+(M\d|G\d)\b", text)
    if m:
        milestone_ids.add(m.group(1))
for pattern in (r"\b(M\d\.\d+)\b", r"\b(S[1-7])\b", r"\b(G[0-2])\b", r"\b(D[0-5])\b", r"\b(Y[0-6])\b"):
    require("Milestone", pattern, milestone_ids)

existing = set(md_files)
mentioned = {}
for f in md_files:
    for i, text in enumerate(lines[f], 1):
        for m in re.finditer(r"`((?:docs/)?[A-Za-z0-9_./-]+\.md)`", text):
            mentioned.setdefault(m.group(1), []).append(f"{f}:{i}")
for name, where in sorted(mentioned.items()):
    if name in existing or name in FUTURE_OK or name.startswith(FUTURE_DIRS):
        continue
    if any(os.path.basename(e) == os.path.basename(name) for e in existing) and "/" not in name:
        continue  # a bare name such as `README.md` for a package README
    problems.append(f"File `{name}` is named at {where[:3]} but does not exist and is not on the future-file list")

if SHOW_REFS:
    for src, ln, raw, doc, n, title in listing:
        print(f"{src}:{ln}  [{raw}] -> {os.path.basename(doc)} §{n} {title}")
    print()

if problems:
    print("Documentation check FAILED:")
    for p in problems:
        print("  " + p)
    sys.exit(1)
print(f"Documentation check passed ({len(md_files)} files, {len(listing)} section references).")
