# Lab 2: Simple Antivirus Daemon (CC373 Operating Systems)

A shell-based antivirus daemon that polls a directory, quarantines malicious files, and a restore tool to review quarantined files.

## Folder Hierarchy

Runtime files (not committed): `directory-info.last`, `directory-info.new`, the monitored directory (default `test/`) and the quarantine directory (default `quarantine/`).

## Overview

- `antivirusd.sh dir malicious_dir interval-secs`
  - Takes a snapshot of `dir` with `ls -l` into `directory-info.new` every `interval-secs`.
  - Compares it with `directory-info.last` using `diff`.
  - On the first run (no `.last` file) it scans immediately and creates `.last`.
  - If the snapshots differ, it scans `dir` and then copies `.new` over `.last`. If not, it just waits.
  - Each malicious file is reported (`<file> is malicious and it is DELETED`), copied to `malicious_dir`, and deleted from `dir`.
- `restore.sh dir malicious_dir`
  - Lists the quarantined files (numbered) and asks the user to pick one.
  - Option 1: restore the file back to `dir`. Option 2: delete it permanently. Option 3: leave it and go back to the list.
  - Prints `No malicious files to review.` when the quarantine is empty.

## Prerequisites (Ubuntu)

- `bash`, `grep`, `diff` and `ls` (already installed on Ubuntu)
- `make`

```bash
sudo apt update
sudo apt install make -y
```

## How to Run

1. Clone the repository and enter it:
```bash
   git clone https://github.com/nouraldenmohamed35-hub/9769-lab2.git
   cd 9769-lab2
```
2. Make the scripts executable:
```bash
   chmod +x antivirusd.sh restore.sh
```
3. Create a directory to monitor and add some files:
```bash
   mkdir test
   echo "hello" > test/safe.txt
   echo "this is a virus" > test/bad.txt
   touch test/run.exe
```
4. Start the antivirus (checks every 5 seconds). Stop it with `Ctrl+C`:
```bash
   make
```
   Or directly: `./antivirusd.sh test quarantine 5`
5. Review quarantined files (do not run this at the same time as the daemon):
```bash
   make restore
```
   Or directly: `./restore.sh test quarantine`
6. Custom values:
```bash
   make DIR=mydir MALICIOUS_DIR=q INTERVAL=2
```

The `setup` target runs before both `antivirus` and `restore` and creates the quarantine directory if it does not exist.

## Flagged Lists (where they are defined)

Both lists are hardcoded in `antivirusd.sh`:

- **Flagged keywords** (case-insensitive): the variable `BAD_KEYWORDS` near the top of the file: `virus|trojan|malware|worm|ransomware`
- **Flagged extensions**: the `case` statement inside the `is_malicious` function: `.exe`, `.bat`, `.vbs`, `.scr`, `.ps1`
