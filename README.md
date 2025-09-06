# srafq 0.0.1 — Robust SRA/ENA FASTQ fetcher (Aspera‑first; `fasterq-dump` fallback)

**srafq** takes a list of SRA accessions (SRR/DRR/ERR), resolves metadata via ENA, and downloads the FASTQ files safely.
It prefers **Aspera (ascp)** whenever available and falls back to **`fasterq-dump`**.

## Install (conda)
```bash
# Create and activate an environment
mamba create -n srafq -c conda-forge -c bioconda sra-tools pigz curl flock ||     conda  create -n srafq -c conda-forge -c bioconda sra-tools pigz curl flock
conda activate srafq

# Aspera CLI (includes ascp v3 and the DSA key)
conda install -y hcc::aspera-cli
# (equivalently) conda install -y -c hcc aspera-cli
```

## Prepare the script
Save the srafq script in this repository to your working directory and make it executable:
```bash
chmod +x ./srafq
```

### Aspera key and (optional) wrapper
Most installations ship the Aspera DSA key inside your conda env:
```bash
export ASCP_KEY="$CONDA_PREFIX/etc/asperaweb_id_dsa.openssh"
head -n1 "$ASCP_KEY"   # should print: -----BEGIN DSA PRIVATE KEY-----
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

## Quick start
Put accessions (one per line) in `SRR_List.txt` (lines starting with `#` are ignored). Normalize CRLF if needed:
```bash
sed -i 's/\r$//' SRR_List.txt
```

Run:
```bash
ASCP_LIMIT_M=150m THREADS=8 ./srafq -i SRR_List.txt -o data
```

## CLI
```text
Usage: srafq -i ACCESSION_LIST -o OUTDIR

Options:
  -i, --input FILE        Accession list file (one SRR/DRR/ERR per line)
  -o, --outdir DIR        Output directory
  -h, --help              Short help
      --help-long         Detailed help (env, modes, outputs, examples)
      --show-env          Print effective settings and exit
      --version           Print version and exit
```

### Environment variables
| Variable | Default | Description |
|---|---|---|
| `RESUME_MODE` | `skip` | `skip` to keep valid files; `force` to re-fetch |
| `THREADS` | `4` | Threads for `fasterq-dump` and `pigz` |
| `SKIP_TECHNICAL` | `false` | When `true`, pass `--skip-technical` to `fasterq-dump` |
| `RETRIES` | `3` | Per-file retries for transfer/MD5 mismatch |
| `ASCP_BIN` | auto `ascp` | Path/command to Aspera client (e.g. `ascp-forcekey`) |
| `ASCP_KEY` | _(unset)_ | Path to Aspera DSA key (typ. `$CONDA_PREFIX/etc/asperaweb_id_dsa.openssh`) |
| `ASCP_LIMIT_M` | _(unset)_ | Bandwidth cap, e.g. `150m` (= ~150 megabits/s) |
| `LAYOUT_MODE` | _(unset)_ | Force `PAIRED` or `SINGLE` layout |
| `DEBUG` | `0` | `1` to enable `bash -x` tracing |

## How it decides what to do
1) Query ENA `filereport` for **fastq_aspera**, **fastq_md5**, **library_layout** (column‑order tolerant).  
2) Determine layout:
   - Use `library_layout` if it is `PAIRED` or `SINGLE`.
   - If unknown, infer **PAIRED** if there are ≥2 Aspera URLs or the filename looks R1‑like (e.g. `_1.fastq.gz`).
   - `LAYOUT_MODE=PAIRED|SINGLE` overrides everything.
3) Choose a mode:
   - `aspera_paired`   → if layout is `PAIRED` and ≥2 Aspera URLs
   - `aspera_single`   → if layout is `SINGLE` and ≥1 Aspera URL
   - `fqdump_split`    → otherwise when layout is `PAIRED` or `UNKNOWN`
   - `fqdump`          → otherwise when layout is `SINGLE`
4) After each Aspera transfer, verify MD5 (if provided). On mismatch the file is deleted and the transfer is retried up to `RETRIES` times.
   - On final failure, the accession is appended to `OUTDIR/srafq.retry.txt` and details are recorded in `OUTDIR/srafq.failed.tsv`.

## Signals, locking, and resume
- Sending `Ctrl-C` stops child jobs cleanly and finalizes `srafq.retry.txt` / `srafq.failed.tsv`.
- A per‑OUTDIR advisory flock prevents concurrent runs in the same output directory.
- `RESUME_MODE=skip` avoids re-downloading when the expected MD5 already matches.

## Examples
```bash
# Typical run with bandwidth cap and more threads
export ASCP_KEY="$CONDA_PREFIX/etc/asperaweb_id_dsa.openssh"
ASCP_LIMIT_M=150m THREADS=8 ./srafq -i SRR_List.txt -o data

# Force layout and re-fetch
LAYOUT_MODE=PAIRED RESUME_MODE=force ./srafq -i SRR_List.txt -o data

# If some accessions failed, retry with more attempts
RETRIES=5 ./srafq -i data/srafq.retry.txt -o data

# Inspect effective settings
./srafq --show-env
```

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

## License
See `LICENSE`.
