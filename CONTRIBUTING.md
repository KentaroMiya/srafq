# Contributing to srafq

Thanks for considering a contribution! This project is a tiny, Linux‑only Bash helper for robustly fetching SRA/ENA reads. Contributions are welcome via issues and pull requests (PRs).

- Repository: <https://github.com/KentaroMiya/srafq>
- License: MIT (by contributing you agree your changes are provided under the MIT license)
- Primary branch: `main`

## Ways to contribute

- **Bug report** – unexpected behavior, errors, or documentation gaps.
- **Feature proposal** – small, focused enhancements that keep the tool simple.
- **Documentation** – improvements to README, examples, comments, or messages (`--help`).

Please avoid sharing credentials or sensitive data. For security issues, **do not open a public issue**; instead, use GitHub “Security advisories” or contact the maintainer privately via GitHub.

## Getting started (development)

Requirements (Linux):
- Bash ≥ 4, `curl`, [`sra-tools`](https://github.com/ncbi/sra-tools)
- Optional: IBM Aspera `ascp` + `asperaweb_id_dsa.openssh` (for high‑speed downloads)
- Recommended for contributors: `shellcheck`, `pigz`

Example setup via conda/mamba:
```bash
mamba create -n srafq -c conda-forge -c bioconda sra-tools pigz curl shellcheck || conda create -n srafq -c conda-forge -c bioconda sra-tools pigz curl shellcheck
conda activate srafq
```

Run locally:
```bash
chmod +x ./srafq
./srafq --help
./srafq --version
```

### Linting (ShellCheck)

CI runs ShellCheck on each push/PR. Please lint locally before opening a PR:

```bash
shellcheck --version   # 0.8+ is fine; CI currently uses 0.11.x
shellcheck -S warning ./srafq
```

### Quick “smoke” test

Ensure that help/version run successfully:
```bash
bash ./srafq --help || true
bash ./srafq --version || true
```

If you add new flags or change behavior, also update the README usage examples and `--help` text in the script.

## Bash style guide (short)

Keep the script readable and ShellCheck‑friendly.

- Use `set -Eeuo pipefail` near the top.
- Prefer `[[ ... ]]` over `[ ... ]`; always **quote** variables (`"$var"`).
- Declare and assign **separately** to avoid masking statuses (avoids SC2155).
- Use `local` inside functions; avoid implicitly global variables.
- Prefer arrays for lists; avoid word‑splitting surprises.
- Avoid backticks `cmd`; use `$(cmd)`.
- Use `case` for option parsing; keep error messages clear and actionable.
- Keep external dependencies minimal (no non‑portable bashisms beyond Bash ≥ 4).

Function skeleton:
```bash
my_func() {
  local arg="$1"
  # ...
  return 0
}
```

## Pull request workflow

1. **Create a branch** off `main` (e.g., `feat/foo-bar` or `fix/xyz`).  
2. Make small, focused commits with clear messages (present tense).  
3. Run **ShellCheck** and the smoke commands locally.  
4. Update docs if behavior or flags changed (README + `--help`).  
5. Add a line to **CHANGELOG.md** under `Unreleased` (or create one if missing).  
6. Push and open a **PR** describing _what changed_ and _why_.

CI will run automatically (ShellCheck + smoke). Please keep GitHub Actions pinned by **commit SHA** when updating workflows.

## Versioning & releases

- We aim for semantic versioning (MAJOR.MINOR.PATCH) where possible.
- To publish a release:
  1. Update `CHANGELOG.md` and, if needed, the version string in docs.
  2. Tag on GitHub (e.g., `v0.0.2`) and publish a release.
  3. Zenodo will archive the release and mint a **version DOI**.  
     Add/refresh the DOI in `CITATION.cff` and README badge if needed.

## Trademarks & third‑party tools

“Aspera” and “FASP” are trademarks of IBM. *srafq* is an independent open‑source project and does not bundle `ascp`. Users should install and use `ascp` under its license. We also rely on NCBI `sra-tools` and ENA’s HTTP API for metadata.

## Code of Conduct

We follow the [JOSS Code of Conduct](https://joss.theoj.org/about#code_of_conduct). Please be respectful and constructive in all interactions.

## Acknowledgement of contributions

All contributors are listed in GitHub’s contributor graph. Substantial changes may be credited in the CHANGELOG and in release notes.

---

Thank you for helping make **srafq** better!
