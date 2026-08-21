#!/usr/bin/env python3
"""Check that every term a candidate meets on screen appears somewhere in a track.

An objective-level check answers whether a topic exists, which stops being the
risk once a plan exists. This answers a different question: does the word
CompTIA prints appear on the page a question links to. On Network+ the same
check ran once, at the end, and found seven strings that appeared nowhere,
including one the question bank was already asking for while the topic taught it
under a different name. A reader could get that question wrong having read the
page it pointed at.

SY0-701 carries 743 unique bullet terms, half again as many as N10-009, so this
one runs per block during authoring rather than once at the end.

The totals here and in docs/security-plus-sy0-701-research.md are counted
differently and both are right. The research document counts 797 bullet lines
and 743 terms unique across the whole document. This deduplicates within an
objective and not across them, because a term printed under two objectives is
two things to check, and gets 794. Encryption appears under six.

    scripts/term-coverage.py                      # every objective
    scripts/term-coverage.py --objective 1.4
    scripts/term-coverage.py --objective 2.4 --objective 2.5
    scripts/term-coverage.py --missing-only

Exits 1 when any term has no match, so it can gate the end of a block.

The objectives document is downloaded to a gitignored cache and parsed on every
run. It is deliberately not stored in the repository: the bullet content under
an objective is copyrighted and this project reproduces objective numbers and
statements only. The check needs the list; the repository does not get to keep
it.

Needs pypdf, which is not a repository dependency:

    pip install pypdf
"""
from __future__ import annotations

import argparse
import re
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CACHE = ROOT / ".cache"

EXAMS = {
    "sy0-701": {
        "track": "security-plus",
        "url": (
            "https://comptiacdn.azureedge.net/webcontent/docs/default-source/"
            "exam-objectives/comptia-security-sy0-701-exam-objectives-(6-0).pdf"
        ),
        # The objective statements, which this repo already reproduces in
        # src/config/exams.ts. They are how a bullet block gets attached to a
        # number, because the PDF prints the number in a separate cell.
        "objectives": {
            "1.1": "Compare and contrast various types of security controls.",
            "1.2": "Summarize fundamental security concepts.",
            "1.3": "Explain the importance of change management processes and the impact to security.",
            "1.4": "Explain the importance of using appropriate cryptographic solutions.",
            "2.1": "Compare and contrast common threat actors and motivations.",
            "2.2": "Explain common threat vectors and attack surfaces.",
            "2.3": "Explain various types of vulnerabilities.",
            "2.4": "Given a scenario, analyze indicators of malicious activity.",
            "2.5": "Explain the purpose of mitigation techniques used to secure the enterprise.",
            "3.1": "Compare and contrast security implications of different architecture models.",
            "3.2": "Given a scenario, apply security principles to secure enterprise infrastructure.",
            "3.3": "Compare and contrast concepts and strategies to protect data.",
            "3.4": "Explain the importance of resilience and recovery in security architecture.",
            "4.1": "Given a scenario, apply common security techniques to computing resources.",
            "4.2": "Explain the security implications of proper hardware, software, and data asset management.",
            "4.3": "Explain various activities associated with vulnerability management.",
            "4.4": "Explain security alerting and monitoring concepts and tools.",
            "4.5": "Given a scenario, modify enterprise capabilities to enhance security.",
            "4.6": "Given a scenario, implement and maintain identity and access management.",
            "4.7": "Explain the importance of automation and orchestration related to secure operations.",
            "4.8": "Explain appropriate incident response activities.",
            "4.9": "Given a scenario, use data sources to support an investigation.",
            "5.1": "Summarize elements of effective security governance.",
            "5.2": "Explain elements of the risk management process.",
            "5.3": "Explain the processes associated with third-party risk assessment and management.",
            "5.4": "Summarize elements of effective security compliance.",
            "5.5": "Explain types and purposes of audits and assessments.",
            "5.6": "Given a scenario, implement security awareness practices.",
        },
        # Where the objective bullets stop and the appendices begin.
        "stop_at": "Acronym List",
    }
}

VERB = re.compile(r"^\s*(Compare and contrast|Summarize|Explain|Given a scenario,)")
SKIP = re.compile(r"^(CompTIA |Copyright ©|[0-9]\.0\s*(\||$))")
NUMCELL = re.compile(r"^\s*[0-9]\.[0-9]\s*$")
BULLET = re.compile(r"^([•\-°]|o\b)\s*(.*)$")

# Column boundaries in the SY0-701 layout, in PDF user units. An objective's
# bullets flow across all three columns inside the band under its statement, so
# reading the extracted text in stream order interleaves two objectives.
COLUMNS = (220, 400)
# A bullet glyph and its text are emitted as separate runs a couple of points
# apart vertically. Anything closer than this is the same line.
LINE_TOLERANCE = 4


def norm(text: str) -> str:
    return re.sub(r"\s+", " ", text.replace(" ", " ").replace("\t", " ")).strip()


def fetch(url: str, dest: Path) -> Path:
    if dest.exists():
        return dest
    dest.parent.mkdir(parents=True, exist_ok=True)
    print(f"downloading {url}", file=sys.stderr)
    request = urllib.request.Request(url, headers={"User-Agent": "term-coverage"})
    with urllib.request.urlopen(request, timeout=60) as response:
        dest.write_bytes(response.read())
    return dest


def terms_by_objective(pdf: Path, exam: dict) -> dict[str, list[str]]:
    """Bullet terms from the objectives document, attributed to their objective."""
    try:
        import pypdf
    except ImportError:
        sys.exit("term-coverage: needs pypdf. pip install pypdf")

    reader = pypdf.PdfReader(str(pdf))
    pages = []
    for page in reader.pages:
        runs: list[dict] = []
        page.extract_text(
            visitor_text=lambda t, cm, tm, font, size: runs.append(
                {"t": t, "x": tm[4], "y": tm[5]}
            )
        )
        pages.append(runs)

    stop = next(
        (i for i, runs in enumerate(pages) if any(exam["stop_at"] in r["t"] for r in runs)),
        len(pages),
    )
    statements = {norm(v): k for k, v in exam["objectives"].items()}
    column = lambda x: 0 if x < COLUMNS[0] else (1 if x < COLUMNS[1] else 2)

    out: dict[str, list[str]] = {}
    current: str | None = None
    for runs in pages[:stop]:
        live = [
            r
            for r in runs
            if r["t"].strip() and not (r["x"] == 0.0 and r["y"] == 0.0) and not NUMCELL.match(r["t"])
        ]
        rows: list[dict] = []
        for col in (0, 1, 2):
            in_column = sorted(
                (r for r in live if column(r["x"]) == col), key=lambda r: (-r["y"], r["x"])
            )
            for run in in_column:
                if rows and rows[-1]["col"] == col and abs(rows[-1]["y"] - run["y"]) <= LINE_TOLERANCE:
                    rows[-1]["t"] += run["t"]
                    rows[-1]["x"] = min(rows[-1]["x"], run["x"])
                else:
                    rows.append({"col": col, "y": run["y"], "x": run["x"], "t": run["t"]})
        for row in rows:
            row["t"] = norm(row["t"])

        columns = [[r for r in rows if r["col"] == c] for c in (0, 1, 2)]
        heads = [r["y"] for r in columns[0] if VERB.match(r["t"])]
        bands = [(heads[i], heads[i + 1] if i + 1 < len(heads) else -1) for i in range(len(heads))]
        if not bands:
            bands = [(float("inf"), -1)]

        for top, bottom in bands:
            head = None if top == float("inf") else next(r["t"] for r in columns[0] if r["y"] == top)
            band = [
                r
                for column_rows in columns
                for r in column_rows
                if bottom < r["y"] < top and not SKIP.match(r["t"])
            ]
            if head is not None:
                statement = norm(head)
                # A statement can wrap onto a second line before the bullets start.
                while band and not BULLET.match(band[0]["t"]) and band[0]["col"] == 0 and band[0]["x"] <= 70:
                    statement = norm(statement + " " + band.pop(0)["t"])
                current = statements.get(statement)
                if current is None:
                    print(f"term-coverage: unrecognised statement {statement!r}", file=sys.stderr)
                    continue
            if current is None:
                continue
            collected = out.setdefault(current, [])
            for row in band:
                bullet = BULLET.match(row["t"])
                if bullet and bullet.group(2).strip():
                    collected.append(norm(bullet.group(2)))
                elif collected:
                    collected[-1] = norm(collected[-1] + " " + row["t"])
    return out


def variants(term: str) -> set[str]:
    """The strings worth searching for one bullet term.

    CompTIA writes a term once and a topic may use either half of it: the
    spelled-out form, the abbreviation from the parentheses, or one side of a
    slash. Searching only the printed string reports gaps that are not gaps.
    """
    found: set[str] = set()

    def add(candidate: str) -> None:
        candidate = candidate.strip(" .,;:")
        if len(candidate) >= 3:
            found.add(candidate)

    add(term)
    paren = re.match(r"^(.*?)\s*\(([^)]+)\)\s*(.*)$", term)
    if paren:
        add(f"{paren.group(1)} {paren.group(3)}".strip())
        add(paren.group(2))
    bare = re.sub(r"\([^)]*\)", "", term)
    for part in re.split(r"\s*/\s*", bare):
        add(part)
    for part in re.split(r"\s+vs\.?\s+", bare):
        add(part)
    return found


def load_track(track: str) -> dict[str, str]:
    directory = ROOT / "src/content/learn" / track
    if not directory.is_dir():
        sys.exit(f"term-coverage: no track at {directory}")
    return {path.stem: path.read_text().lower() for path in sorted(directory.glob("*.md"))}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--exam", default="sy0-701", choices=sorted(EXAMS))
    parser.add_argument(
        "--objective", action="append", default=[], help="limit to one objective, repeatable"
    )
    parser.add_argument("--missing-only", action="store_true", help="print gaps and nothing else")
    args = parser.parse_args()

    exam = EXAMS[args.exam]
    pdf = fetch(exam["url"], CACHE / f"{args.exam}-objectives.pdf")
    by_objective = terms_by_objective(pdf, exam)
    topics = load_track(exam["track"])

    wanted = args.objective or sorted(by_objective, key=lambda o: (int(o[0]), int(o[2])))
    gaps: list[tuple[str, str]] = []
    checked = 0

    for objective in wanted:
        terms = by_objective.get(objective)
        if terms is None:
            print(f"term-coverage: {objective} is not on {args.exam}", file=sys.stderr)
            return 2
        missing = []
        for term in dict.fromkeys(terms):
            checked += 1
            patterns = [
                re.compile(r"(?<![a-z0-9])" + re.escape(v.lower()) + r"(?![a-z0-9])")
                for v in variants(term)
            ]
            if not any(p.search(text) for p in patterns for text in topics.values()):
                missing.append(term)
                gaps.append((objective, term))
        if not args.missing_only:
            covered = len(dict.fromkeys(terms)) - len(missing)
            total = len(dict.fromkeys(terms))
            share = 100 * covered / total if total else 100
            print(f"{objective}  {covered:3d}/{total:<3d} {share:5.1f}%")
        for term in missing:
            print(f"    missing: {term}")

    print(
        f"\n{checked} terms checked across {len(wanted)} objective(s), "
        f"{len(gaps)} with no match in {exam['track']}",
        file=sys.stderr,
    )
    return 1 if gaps else 0


if __name__ == "__main__":
    raise SystemExit(main())
