# srafq

**srafq** is a tiny, Linux-only Bash helper to fetch SRA/ENA reads with **Aspera** (if available) and cleanly fall back to **fasterq-dump**.  
It resolves run metadata via **ENA (HTTP, metadata only)**, creates sane per-accession output folders, and records failures/retries.

## Features
- Aspera (`ascp`) first; automatic fallback to `fasterq-dump`
- Clean per-accession output dirs; paired/single layouts handled
- Failure log and retry list: `data/srafq.failed.tsv` and `data/srafq.retry.txt`
- Quick Aspera sanity check (ascp + private key)
- ShellCheck-cleaned script; CI included

## Requirements
- Linux, Bash ≥ 4
- `sra-tools` (for `fasterq-dump`)
- `curl`
- Recommended: `ascp` + `asperaweb_id_dsa.openssh` (for high speed)
- Optional: `pigz` (faster compression), `jq` (only if you customize JSON handling)

## Quick start
```bash
chmod +x srafq
export ASCP_KEY="$CONDA_PREFIX/etc/asperaweb_id_dsa.openssh"
ASCP_LIMIT_M=150m THREADS=8 ./srafq -i SRR_List.txt -o data
```

**No Aspera available?**
```bash
ASCP_BIN=none THREADS=8 ./srafq -i SRR_List.txt -o data
```

**Force layout & re-fetch**
```bash
LAYOUT_MODE=PAIRED RESUME_MODE=force ./srafq -i SRR_List.txt -o data
```

**Retry only failed ones**
```bash
RETRIES=5 ./srafq -i data/srafq.retry.txt -o data
```

## Output example
```
data/
└── SRR10479824/
    ├── SRR10479824_1.fastq.gz
    └── SRR10479824_2.fastq.gz
```

## Notes
- Network transfers use **Aspera** when present; **HTTP is used only for ENA metadata**.
- If corporate networks block SSH/Aspera, the script falls back to `fasterq-dump`.
- See the README for all environment variables and usage details.

## Links
- Source code: https://github.com/KentaroMiya/srafq
- README: https://github.com/KentaroMiya/srafq#readme

## How to cite
If you use this software, please cite the Zenodo DOI: **10.5281/zenodo.17067028**  
(Also see `CITATION.cff` in the repository.)
