#!/usr/bin/env python3
"""
FDE Workspace & Dataset Automated Profiler
과제 폴더 내 문서, 데이터셋(CSV/JSON/SQLite), 기존 코드 구조를 3초 만에 해부하여
결정론 코어(80%) 설계에 필요한 임계치·결측치·스키마 정보를 자동 추출합니다.
"""
import argparse
import csv
import json
import math
import os
import sqlite3
from pathlib import Path
from typing import Any, Dict, List

IGNORE_DIRS = {
    ".git", "node_modules", ".next", "dist", "build", "__pycache__",
    ".venv", "venv", "fde-autopilot", "fde-kit", ".fde_audit_cache"
}


def compute_numeric_stats(values: List[float]) -> Dict[str, Any]:
    if not values:
        return {}
    n = len(values)
    mean = sum(values) / n
    variance = sum((x - mean) ** 2 for x in values) / n if n > 1 else 0.0
    std = math.sqrt(variance)
    sorted_vals = sorted(values)
    p50 = sorted_vals[n // 2]
    p95 = sorted_vals[min(n - 1, int(n * 0.95))]
    return {
        "count": n,
        "min": round(min(values), 4),
        "max": round(max(values), 4),
        "mean": round(mean, 4),
        "std": round(std, 4),
        "median": round(p50, 4),
        "p95": round(p95, 4),
        "ucl_3sigma": round(mean + 3 * std, 4),
        "lcl_3sigma": round(mean - 3 * std, 4),
    }


def analyze_csv(file_path: Path) -> str:
    lines = [f"### 📊 CSV 데이터셋: `{file_path.name}` (`{file_path}`)"]
    try:
        with open(file_path, "r", encoding="utf-8", errors="replace") as f:
            reader = csv.DictReader(f)
            headers = reader.fieldnames or []
            rows = []
            for idx, r in enumerate(reader):
                if idx >= 5000:
                    break
                rows.append(r)

        total_rows = len(rows)
        lines.append(f"- **스캔된 행 수**: {total_rows}건 | **컬럼 수**: {len(headers)}개")
        lines.append(f"- **컬럼 목록**: `{', '.join(headers)}`")

        col_Summary = []
        for col in headers:
            null_cnt = 0
            num_vals = []
            sample_vals = []
            for r in rows:
                val = r.get(col)
                if val is None or str(val).strip() == "" or str(val).strip().lower() in ("null", "nan", "none", "n/a"):
                    null_cnt += 1
                else:
                    s_val = str(val).strip()
                    if len(sample_vals) < 3 and s_val not in sample_vals:
                        sample_vals.append(s_val[:40])
                    try:
                        num_vals.append(float(s_val.replace(",", "")))
                    except ValueError:
                        pass

            if len(num_vals) > max(1, (total_rows - null_cnt) * 0.7):
                st = compute_numeric_stats(num_vals)
                col_Summary.append(
                    f"  - `{col}` (수치형, 결측 {null_cnt}건): min={st['min']}, max={st['max']}, "
                    f"mean={st['mean']}, std={st['std']}, **3σ UCL={st['ucl_3sigma']} / LCL={st['lcl_3sigma']}**"
                )
            else:
                col_Summary.append(
                    f"  - `{col}` (범주/텍스트, 결측 {null_cnt}건): 샘플={sample_vals}"
                )
        lines.extend(col_Summary)
    except Exception as e:
        lines.append(f"- ⚠️ CSV 파싱 오류: {e}")
    return "\n".join(lines)


def analyze_json(file_path: Path) -> str:
    lines = [f"### 🗂️ JSON 파일: `{file_path.name}` (`{file_path}`)"]
    try:
        with open(file_path, "r", encoding="utf-8", errors="replace") as f:
            data = json.load(f)
        if isinstance(data, list):
            lines.append(f"- **구조**: Array (총 {len(data)}개 요소)")
            if data and isinstance(data[0], dict):
                keys = list(data[0].keys())
                lines.append(f"- **첫 번째 객체 키**: `{', '.join(keys)}`")
                lines.append(f"- **첫 번째 샘플**: `{json.dumps(data[0], ensure_ascii=False)[:250]}`")
        elif isinstance(data, dict):
            keys = list(data.keys())
            lines.append(f"- **구조**: Object (최상위 키 {len(keys)}개: `{', '.join(keys[:15])}`)")
            for k in keys[:5]:
                v = data[k]
                if isinstance(v, list):
                    lines.append(f"  - `{k}`: Array ({len(v)}개 항목)")
                elif isinstance(v, dict):
                    lines.append(f"  - `{k}`: Object (키: {list(v.keys())[:8]})")
                else:
                    lines.append(f"  - `{k}`: {repr(v)[:80]}")
    except Exception as e:
        lines.append(f"- ⚠️ JSON 분석 생략/오류: {e}")
    return "\n".join(lines)


def analyze_sqlite(file_path: Path) -> str:
    lines = [f"### 🗄️ SQLite DB: `{file_path.name}` (`{file_path}`)"]
    try:
        conn = sqlite3.connect(str(file_path))
        cur = conn.cursor()
        tables = [r[0] for r in cur.execute("SELECT name FROM sqlite_master WHERE type='table';").fetchall()]
        lines.append(f"- **테이블 목록**: `{', '.join(tables)}`")
        for t in tables:
            cnt = cur.execute(f"SELECT COUNT(*) FROM '{t}';").fetchone()[0]
            cols = [c[1] + "(" + c[2] + ")" for c in cur.execute(f"PRAGMA table_info('{t}');").fetchall()]
            lines.append(f"  - `{t}` ({cnt}행): `{', '.join(cols)}`")
        conn.close()
    except Exception as e:
        lines.append(f"- ⚠️ DB 스캔 오류: {e}")
    return "\n".join(lines)


def scan_workspace(root_dir: Path) -> str:
    report = [
        "# 🧭 FDE 워크스페이스 & 데이터셋 자동 프로파일링 리포트",
        f"- **스캔 루트**: `{root_dir}`",
        "",
        "## 1. 디렉토리 및 주요 파일 트리"
    ]

    tree_lines = []
    data_reports = []
    readme_excerpt = []

    for dirpath, dirnames, filenames in os.walk(root_dir):
        dirnames[:] = [d for d in dirnames if d not in IGNORE_DIRS]
        rel_dir = Path(dirpath).relative_to(root_dir)
        depth = 0 if str(rel_dir) == "." else len(rel_dir.parts)
        if depth > 3:
            continue

        indent = "  " * depth
        if str(rel_dir) != ".":
            tree_lines.append(f"{indent}📁 `{rel_dir.name}/`")

        for fname in sorted(filenames):
            if fname.startswith(".fde_"):
                continue
            fpath = Path(dirpath) / fname
            fsize_kb = round(fpath.stat().st_size / 1024, 1)
            tree_lines.append(f"{indent}  📄 `{fname}` ({fsize_kb} KB)")

            lower_name = fname.lower()
            if lower_name == "readme.md" and depth == 0:
                try:
                    content = fpath.read_text(encoding="utf-8", errors="replace")
                    readme_excerpt.append(content[:2000])
                except Exception:
                    pass
            elif lower_name.endswith(".csv"):
                data_reports.append(analyze_csv(fpath))
            elif lower_name.endswith(".json") and lower_name not in ("package.json", "package-lock.json", "tsconfig.json"):
                data_reports.append(analyze_json(fpath))
            elif lower_name.endswith((".sqlite", ".db", ".sqlite3")):
                data_reports.append(analyze_sqlite(fpath))

    report.extend(tree_lines if tree_lines else ["- (파일 없음)"])

    if readme_excerpt:
        report.append("\n## 2. 과제 README.md 핵심 발췌")
        report.append("```markdown\n" + readme_excerpt[0] + "\n```")

    report.append("\n## 3. 데이터셋 스키마·결측치·임계치(3-Sigma) 자동 분석")
    if data_reports:
        report.extend(data_reports)
    else:
        report.append("- 별도의 로컬 CSV/JSON/DB 데이터 파일이 감지되지 않았습니다. (프론트엔드/상태머신 중심 과제로 추정)")

    report.append("\n## 4. FDE 아키텍처 설계 권고 (Codex 컨텍스트 주입용)")
    report.append("- 위 데이터 스캔 결과에서 발견된 **결측치(Null/빈 문자열)** 처리 로직을 `/src/data` 파서에 반드시 포함할 것.")
    report.append("- 수치형 컬럼의 **min/max 및 3-Sigma(UCL/LCL)** 값을 `/src/core`의 결정론적 임계치 상수로 활용할 것.")
    report.append("- 정상(Mean 부근), 경고(UCL/LCL 85% 근접), 위반(UCL 초과 또는 결측/오류 포함) 3종 데이터를 `/src/data/samples.js`의 골든 샘플 프리셋으로 구성할 것.")

    return "\n".join(report)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".", help="Workspace root directory")
    parser.add_argument("--out", default=".fde_data_profile.md", help="Output profile markdown path")
    args = parser.parse_args()

    root_path = Path(args.root).resolve()
    result_md = scan_workspace(root_path)
    out_path = Path(args.out).resolve()
    out_path.write_text(result_md, encoding="utf-8")
    print(f"✅ 데이터 프로파일링 완료: {out_path}")
