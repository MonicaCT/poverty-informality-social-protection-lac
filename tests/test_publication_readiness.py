from __future__ import annotations

import argparse
import ast
import re
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "README.md",
    "LICENSE",
    "CITATION.cff",
    "CONTRIBUTING.md",
    "CHANGELOG.md",
    "CODE_OF_CONDUCT.md",
    "PUBLICATION_CHECKLIST.md",
    ".gitignore",
    ".gitattributes",
    ".github/workflows/ci.yml",
    ".github/workflows/pages.yml",
    ".github/pull_request_template.md",
    ".github/ISSUE_TEMPLATE/bug_report.yml",
    ".github/ISSUE_TEMPLATE/data_issue.yml",
    ".github/ISSUE_TEMPLATE/econometric_question.yml",
    ".github/ISSUE_TEMPLATE/documentation.yml",
    ".github/ISSUE_TEMPLATE/feature_request.yml",
    "assets/brand/repository-banner.png",
    "assets/brand/social-preview.png",
    "assets/screenshots/dashboard-overview.png",
    "assets/screenshots/dashboard-country-profile.png",
    "assets/screenshots/dashboard-mobile.png",
    "docs/index.md",
    "docs/reproducibility.md",
    "docs/dashboard.md",
    "docs/repository-architecture.md",
    "releases/README.md",
    "releases/v0.1.0/RELEASE_NOTES.md",
]

TEMP_PATTERNS = {
    "__pycache__",
    ".pytest_cache",
    ".mypy_cache",
    ".ruff_cache",
    ".DS_Store",
    "Thumbs.db",
}
TEMP_SUFFIXES = {".pyc", ".pyo", ".tmp", ".temp", ".bak", ".swp", ".swo", ".log"}
MARKDOWN_LINK = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")


def parse_python_scripts() -> None:
    for path in list((ROOT / "code" / "python").glob("*.py")) + list((ROOT / "tests").glob("*.py")):
        ast.parse(path.read_text(encoding="utf-8-sig"), filename=str(path))


def test_required_files() -> None:
    missing = [rel for rel in REQUIRED_FILES if not (ROOT / rel).exists()]
    assert not missing, f"Missing publication files: {missing}"


def test_readme_contains_all_figures() -> None:
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    missing = []
    for i in range(1, 13):
        token = f"outputs/figures/figure_{i:02d}_"
        if token not in readme:
            missing.append(token)
    assert not missing, f"README is missing figure references: {missing}"


def iter_markdown_files():
    for path in ROOT.rglob("*.md"):
        rel = path.relative_to(ROOT)
        if rel.parts and rel.parts[0] in {".git", ".venv", "venv"}:
            continue
        if rel.name == "DATA_INVENTORY.md":
            continue
        yield path


def normalize_target(raw: str) -> str | None:
    target = raw.strip().strip("<>")
    if not target or target.startswith("#"):
        return None
    lower = target.lower()
    if lower.startswith(("http://", "https://", "mailto:", "tel:")):
        return None
    target = target.split("#", 1)[0].split("?", 1)[0]
    target = unquote(target).strip()
    return target or None


def test_relative_markdown_links_are_valid() -> None:
    broken = []
    for path in iter_markdown_files():
        text = path.read_text(encoding="utf-8-sig")
        for match in MARKDOWN_LINK.finditer(text):
            target = normalize_target(match.group(1))
            if target is None:
                continue
            candidate = (path.parent / target).resolve()
            try:
                candidate.relative_to(ROOT.resolve())
            except ValueError:
                broken.append(f"{path.relative_to(ROOT)} -> {target} escapes repository")
                continue
            if not candidate.exists():
                broken.append(f"{path.relative_to(ROOT)} -> {target}")
    assert not broken, "Broken relative markdown links:\n" + "\n".join(broken[:50])


def test_no_temporary_files() -> None:
    bad = []
    for path in ROOT.rglob("*"):
        rel = path.relative_to(ROOT)
        if rel.parts and rel.parts[0] in {".git", ".venv", "venv"}:
            continue
        if any(part in TEMP_PATTERNS for part in rel.parts):
            bad.append(str(rel))
        elif path.is_file() and (path.suffix in TEMP_SUFFIXES or path.name.startswith("~$")):
            bad.append(str(rel))
    assert not bad, "Temporary files found:\n" + "\n".join(bad[:50])


def test_github_actions_are_publication_safe() -> None:
    ci = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")
    pages = (ROOT / ".github/workflows/pages.yml").read_text(encoding="utf-8")
    assert "tests/test_publication_readiness.py" in ci
    assert "workflow_dispatch" in pages
    assert "push:" not in pages, "Pages deployment should remain manual until publication"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--syntax-only", action="store_true")
    args = parser.parse_args()
    parse_python_scripts()
    if args.syntax_only:
        print("python_syntax_tests_passed")
        return 0
    test_required_files()
    test_readme_contains_all_figures()
    test_relative_markdown_links_are_valid()
    test_no_temporary_files()
    test_github_actions_are_publication_safe()
    print("publication_readiness_tests_passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

