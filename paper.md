---
title: 'srafq: Fast, robust fetching of SRA/ENA reads with Aspera-first fallback'
tags:
  - bioinformatics
  - sequencing
  - SRA
  - ENA
  - Bash
authors:
  - name: Kentaro Miyamoto
    orcid: 0000-0001-5302-2607
    affiliation: 1
affiliations:
  - name: Research Department, R&D Division, Miyarisan Pharmaceutical Co., Ltd., Saitama, Japan
    index: 1
date: 2025-09-08
bibliography: paper.bib
---

# Summary
*srafq* is a tiny, Linux-only Bash helper that retrieves sequencing reads from
SRA/ENA using **Aspera (`ascp`) when available**, and cleanly falls back to
`fasterq-dump` otherwise. It resolves run metadata via ENA over HTTP (metadata only),
creates per-accession output directories, and records failures/retries for robust
batch processing. The tool aims to reduce operational friction when preparing
read sets for downstream analysis on clusters or corporate networks where Aspera
may be blocked or intermittent.

# Statement of need
Fetching public read archives reproducibly and at scale is still error-prone,
owing to heterogeneous run layouts (single/paired), transient transfer errors,
and environment constraints (e.g., firewall-constrained Aspera). *srafq*
reduces the burden for practitioners who need a simple, automatable way to
populate analysis workspaces with FASTQ files:

1. **Aspera-first** transfers with **automatic fallback** to `fasterq-dump`.
2. Layout-aware directory structure per accession (single/paired).
3. Explicit **failure/retry ledgers** to resume long jobs deterministically.
4. Simple configuration via environment variables; a single self-contained script.

# Functionality
- Detects Aspera (`ascp`) + private key and uses it when present; otherwise runs `fasterq-dump`.
- Resolves run metadata through ENA's HTTP API (metadata only).
- Writes outputs under `OUTDIR/<accession>/` with `_1/_2` naming for paired-end runs.
- Records failures in `data/srafq.failed.tsv` and a retry list at `data/srafq.retry.txt`.
- Includes ShellCheck-cleaned code and CI linting.

Example:
```bash
export ASCP_KEY="$CONDA_PREFIX/etc/asperaweb_id_dsa.openssh"
ASCP_LIMIT_M=150m THREADS=8 ./srafq -i SRR_List.txt -o data
```

# Quality control
We provide continuous integration that runs ShellCheck over the script and a
smoke job ensuring `--help` and `--version` execute on each push/PR.
The repository contains example command lines and a small `SRR_List.txt` for
manual dry-runs. Users are encouraged to report issues and contribute tests
for edge cases (e.g., mixed layouts, controlled network environments).

# Availability
- **Source code**: https://github.com/KentaroMiya/srafq
- **Archive/DOI**: 10.5281/zenodo.17067028  (versioned release archived on Zenodo; corresponding to v0.0.1)
- **License**: MIT

# Acknowledgements
We thank the SRA/ENA teams and the maintainers of sra-tools.
We also acknowledge IBM Aspera for providing the `ascp` client implementing
the FASP high-speed transfer protocol used by *srafq*. "Aspera" and "FASP"
are trademarks of IBM. *srafq* is an independent open-source project and is
not affiliated with or endorsed by IBM. Users should obtain and use `ascp`
under its respective license.
# References
