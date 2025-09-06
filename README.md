# srafq 0.0.1 — Robust SRA/ENA FASTQ Fetcher (Linux Only)

![ShellCheck](https://github.com/KentaroMiya/srafq/actions/workflows/shellcheck.yml/badge.svg)

> **srafq** resolves SRR/DRR/ERR accessions via ENA and downloads FASTQ files.  
> It prefers **Aspera (ascp)** when available and **falls back to SRA Tools (`fasterq-dump`)**.  
> **No direct HTTP/FTP file downloads are used** in this version (HTTP is used only to query ENA metadata).

<p align="left">
  <img alt="linux-only" src="https://img.shields.io/badge/OS-Linux-only" />
  <img alt="bash>=4" src="https://img.shields.io/badge/Bash-%E2%89%A54-blue" />
  <img alt="ascp-optional" src="https://img.shields.io/badge/Aspera-optional-lightgrey" />
</p>

---

## Features
- ENA filereport lookup (HTTP metadata only) and layout detection (PAIRED/SINGLE)
- **Aspera-first** transfer; automatic retry & MD5 verification (when available)
- **Fallback** to `fasterq-dump` (SRA Tools) if Aspera is unavailable
- Integrity checks (`pigz -t`/`gzip -t`) when MD5 is not provided
- Resume behavior (`RESUME_MODE=skip` by default)
- Simple logs & retry list generation

---

## Installation (Conda)

### Minimal (works out of the box)
```bash
mamba create -n srafq -c conda-forge -c bioconda sra-tools pigz curl -y  || conda create -n srafq -c conda-forge -c bioconda sra-tools pigz curl -y
conda activate srafq
```

- **sra-tools**: required for `fasterq-dump` fallback (core path without Aspera)  
- **pigz**: fast compression & `-t` integrity check (falls back to `gzip` if absent)  
- **curl**: **only used to query ENA metadata** (not for file transfers)

### Aspera (ascp) — optional but recommended for speed
Install one of the following if you want Aspera transfers:
```bash
# Conda package (Linux):
conda install -y hcc::aspera-cli  # or: conda install -y -c hcc aspera-cli
```

Then set the key (often bundled in the conda env):
```bash
export ASCP_KEY="$CONDA_PREFIX/etc/asperaweb_id_dsa.openssh"
chmod 600 "$ASCP_KEY"
```

A tiny wrapper ensures your key is always used, even if downstream tools drop -i:
```bash
mkdir -p ~/bin
cat > ~/bin/ascp-forcekey <<'SH'
#!/usr/bin/env bash
set -euo pipefail
REAL_ASCP="$(command -v ascp)"
KEY="${ASCP_KEY:-$HOME/asperaweb_id_dsa.openssh}"
args=(); skip=0
for a in "$@"; do
  if [[ $skip -eq 1 ]]; then skip=0; continue; fi
  if [[ "$a" == "-i" ]]; then skip=1; continue; fi
  if [[ "$a" == -i* ]]; then continue; fi
  args+=("$a")
done
exec "$REAL_ASCP" -i "$KEY" "${args[@]}"
SH
chmod +x ~/bin/ascp-forcekey
export ASCP_BIN="$(command -v ascp-forcekey)"   # otherwise leave unset to auto-detect `ascp`
```
> If you **do not** want Aspera, set `ASCP_BIN=none` at run time and srafq will use **SRA Tools only**.

---

## Quick Start

1. Prepare a plain-text list of accessions (one per line, `#` lines are ignored), e.g.
   ```text
   SRR10479824
   SRR10479825
   DRR502916
   SRR14715112
   ```
   If the file came from Windows, normalize line endings:
   ```bash
   sed -i 's/\r$//' SRR_List.txt
   ```

2. Run srafq:
   ```bash
 # Typical run with bandwidth cap and more threads
 export ASCP_KEY="$CONDA_PREFIX/etc/asperaweb_id_dsa.openssh"
 ASCP_LIMIT_M=150m THREADS=8 ./srafq -i SRR_List.txt -o data

   # Aspera disabled (SRA Tools only via fasterq-dump)
   ASCP_BIN=none THREADS=8 ./srafq -i SRR_List.txt -o data
   
   # Force layout and re-fetch
   LAYOUT_MODE=PAIRED RESUME_MODE=force ./srafq -i SRR_List.txt -o data
   
   # If some accessions failed, retry with more attempts
   RETRIES=5 ./srafq -i data/srafq.retry.txt -o data
   ```

---

## CLI
```text
Usage: srafq -i ACCESSION_LIST -o OUTDIR

Options:
  -i, --input FILE        Accession list (SRR/DRR/ERR per line)
  -o, --outdir DIR        Output directory
  -h, --help              Short help
      --help-long         Detailed help (env, modes, outputs, examples)
      --show-env          Print effective settings and exit
      --version           Print version and exit
```

### Key Environment Variables (Linux)
| Variable        | Default   | Description |
| --------------- | --------- | ----------- |
| `RESUME_MODE`   | `skip`    | Skip re-downloading if files look OK (`force` to re-download) |
| `THREADS`       | `4`       | Threads for `fasterq-dump` and `pigz` |
| `SKIP_TECHNICAL`| `false`   | Adds `--skip-technical` to `fasterq-dump` |
| `RETRIES`       | `3`       | Retries on transfer/integrity failure |
| `ASCP_BIN`      | autodetect| Path to `ascp` (unset/invalid → Aspera not used) |
| `ASCP_KEY`      | _(unset)_ | DSA key (e.g. `$CONDA_PREFIX/etc/asperaweb_id_dsa.openssh`) |
| `ASCP_LIMIT_M`  | _(unset)_ | Bandwidth cap, e.g. `150m` (~150 Mbit/s) |
| `LAYOUT_MODE`   | _(unset)_ | Force `PAIRED` or `SINGLE` if needed |
| `DEBUG`         | `0`       | Set `1` to enable `bash -x` tracing |

---

## How It Works (high level)
1. Query ENA `filereport` for `fastq_aspera`, `fastq_md5`, and `library_layout` (HTTP **metadata** only).  
2. Determine layout: trust `library_layout` when present; otherwise infer from URLs/filenames. `LAYOUT_MODE` overrides all.  
3. Choose execution mode:
   - `aspera_paired` / `aspera_single` when Aspera URLs are available
   - `fqdump_split` (PAIRED/UNKNOWN) or `fqdump` (SINGLE) when Aspera is not available
4. After download, verify integrity with MD5 (if provided). On mismatch, remove and retry (up to `RETRIES`).  
   If no MD5 is provided by ENA, fall back to `pigz -t`/`gzip -t` integrity check.

---

## Troubleshooting (Linux)

### A. Aspera fails or UDP/33001 is blocked
- Ensure `ascp` exists (`which ascp`) and key permissions are correct (`chmod 600 "$ASCP_KEY"`).  
- If the network blocks Aspera (UDP/33001), run **SRA Tools only**:
  ```bash
  ASCP_BIN=none ./srafq -i SRR_List.txt -o data
  ```

### B. `fasterq-dump` is slow or flaky
- Use fast local scratch for temp/cache:
  ```bash
  export TMPDIR=/scratch/tmp_srafq
  export PREFETCH_DIR=$HOME/ncbi/public/sra
  mkdir -p "$TMPDIR" "$PREFETCH_DIR"
  ```
- Increase `THREADS` (and `PIGZ_THREADS`) while monitoring I/O.

### C. No MD5 provided by ENA
- We rely on `pigz -t`/`gzip -t` for a lightweight integrity check.
- For stricter checks, compute `md5sum` manually after the run.

### D. Re-running failures only
- `OUTDIR/srafq.retry.txt` collects failures; re-run just those:
  ```bash
  RETRIES=5 ./srafq -i data/srafq.retry.txt -o data
  ```

---

## Outputs
```
<OUTDIR>/
  srafq.log
  srafq.retry.txt
  srafq.failed.tsv
  <ACCESSION>/*.fastq.gz
  .tmp/<ACCESSION>/
  .srafq.lock
```

---

## License
See `LICENSE` for details.

## Acknowledgements
- ENA (EMBL-EBI) for programmatic access to metadata
- NCBI SRA Tools team for `fasterq-dump`
