# Lab 2: Simple Antivirus Daemon (CC373 Operating Systems)

A shell-based antivirus daemon that polls a directory, quarantines malicious files, and a restore tool to review quarantined files.

## Folder Hierarchy

```
9769-lab2/
├── antivirusd.sh       # the antivirus daemon
├── antivirus-cron.sh   # single-run version for cron (Bonus 1)
├── restore.sh          # interactive restore tool
├── Makefile            # targets: setup, antivirus, restore
├── README.md           # this file
└── .gitignore          # ignores test data and runtime files
```

Runtime files (not committed): `directory-info.last`, `directory-info.new`, `whitelist.txt`, the monitored directory (default `test/`) and the quarantine directory (default `quarantine/`).

## Overview

- `antivirusd.sh dir malicious_dir interval-secs`
  - Takes a snapshot of `dir` with `ls -l` into `directory-info.new` every `interval-secs`.
  - Compares it with `directory-info.last` using `diff`.
  - On the first run (no `.last` file) it scans immediately and creates `.last`.
  - If the snapshots differ, it scans `dir` and then regenerates `.last` from the current contents of `dir`. If not, it just waits.
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
   chmod +x antivirusd.sh antivirus-cron.sh restore.sh
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

Both lists are hardcoded in `antivirusd.sh` (and repeated in `antivirus-cron.sh`):

- **Flagged keywords** (case-insensitive): the variable `BAD_KEYWORDS` near the top of the file: `virus|trojan|malware|worm|ransomware`
- **Flagged extensions**: the `case` statement inside the `is_malicious` function: `.exe`, `.bat`, `.vbs`, `.scr`, `.ps1`

## Bonus 1: Cron Job

`antivirus-cron.sh dir malicious_dir` is a single-run version of the daemon (no loop, no sleep). It takes a snapshot, compares it with `directory-info.last`, scans if the listing changed (or on the first run), and quarantines malicious files. It stores its snapshot files next to the script.

### Prerequisites

- The `cron` service is installed and running.
- The scripts are executable (`chmod +x antivirus-cron.sh`).
- The monitored directory exists. Use absolute paths in the crontab, because cron does not run from the project folder.
- Do not run the daemon (`antivirusd.sh`) and the cron job on the same folder at the same time, since they share the `directory-info.*` files.

### Step-by-step setup

1. Install and start cron:
   ```bash
   sudo apt install cron -y
   sudo systemctl enable --now cron
   systemctl is-active cron      # should print: active
   ```
2. Make the script executable:
   ```bash
   chmod +x antivirus-cron.sh
   ```
3. Open your crontab (choose nano if asked):
   ```bash
   crontab -e
   ```
4. Add this line at the end (replace `/home/user` with your own home directory):
   ```
   * * * * * sleep 23; /home/user/9769-lab2/antivirus-cron.sh /home/user/9769-lab2/test /home/user/9769-lab2/quarantine >> /home/user/antivirus-cron.log 2>&1
   ```
5. Save and exit, then verify:
   ```bash
   crontab -l
   ```
6. Watch the log:
   ```bash
   tail -f ~/antivirus-cron.log
   ```
7. To stop the job, remove the line with `crontab -e` (or run `crontab -r` to remove the whole crontab).

Cron's smallest unit is one minute, so `* * * * *` starts the job at second 0 of every minute and `sleep 23` delays the scan until second 23.

### Cron expression: every 3rd Friday of the month at 12:31 AM

```
31 0 15-21 * * [ "$(date +\%u)" = 5 ] && /home/user/9769-lab2/antivirus-cron.sh /home/user/9769-lab2/test /home/user/9769-lab2/quarantine >> /home/user/antivirus-cron.log 2>&1
```

- `31 0` means minute 31 of hour 0 (12:31 AM).
- `15-21` is the day-of-month range. The 3rd Friday of any month always falls between the 15th and the 21st.
- The month field is `*` (every month).
- When both day-of-month and day-of-week are restricted, cron runs the job if either one matches. So the day-of-week field is left as `*`, and the weekday is checked in the command instead: `date +%u` prints 5 for Friday.
- `%` has a special meaning in a crontab, so it is escaped as `\%`.

## Bonus 2: Whitelist

Files restored through `restore.sh` are remembered as safe, so later scans skip them even though they still match a flagged extension or keyword.

### How a file gets added to the whitelist

In `restore.sh`, when the user chooses option 1 (Restore), the file is moved back to `dir` and its file name is appended as one line to `whitelist.txt`:

```bash
echo "$file" >> "$whitelist"
```

`whitelist.txt` is created automatically in the same folder as the scripts (the first time a file is restored). Choosing option 2 (delete) or option 3 (leave) does not change it.

### How the daemon checks it during a scan

At the start of `is_malicious` (in both `antivirusd.sh` and `antivirus-cron.sh`), the file name is looked up in `whitelist.txt`:

```bash
if [ -f "$whitelist" ] && grep -qxF "$file" "$whitelist"; then
    return 1
fi
```

`grep -x` matches the whole line and `-F` treats the name as a plain string. If the name is found, the function returns 1 (not malicious) and neither the extension nor the keyword rules are checked.

### Persistence

The whitelist is a plain file on disk, so it is still respected after the daemon is stopped and restarted. To remove a file from the whitelist, delete its line from `whitelist.txt`.
