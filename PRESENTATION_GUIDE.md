# LostLink: Presentation & Viva Guide
## Unix & Shell Scripting Project Defense

---

## 1. Executive Summary for Evaluators

> *"Good morning/afternoon, Professors. Today our team presents **LostLink** — a Campus Lost & Found Management System. While many campus systems are developed as standard web applications, our project is fundamentally designed around **Unix & Shell Scripting**. In LostLink, **Bash is the application engine, and flat CSV files form our database**. The web dashboard is simply a visual presentation layer that triggers and visualizes the output of our shell scripts."*

---

## 2. Master Table of Unix Concepts Used

| # | Unix / Shell Topic | Specific Tools & Syntax Used | Project Location | Purpose & Implementation |
|---|-------------------|------------------------------|------------------|--------------------------|
| **1** | **Advanced Stream Processing (`awk`)** | Associative arrays, `FS`/`OFS`, `NR`, `NF`, `gsub()`, `index()`, `printf` | `matching_engine.sh`<br>`analytics.sh`<br>`utils.sh` | • Weighted AI matching score calculation<br>• Campus KPI metrics & recovery rate<br>• Dynamic CSV-to-JSON serialization without 3rd party tools |
| **2** | **Stream Editing (`sed`)** | `s/find/replace/`, regex character stripping | `main.sh`<br>`record_manager.sh`<br>`analytics.sh` | • Formatting terminal outputs<br>• ID prefix extraction (`sed "s/^LST//"`)<br>• Sanitizing delimiters |
| **3** | **Pattern Searching (`grep`)** | `grep -i`, `grep -v`, `grep -q`, `^` anchor | `search_engine.sh`<br>`record_manager.sh`<br>`audit_logger.sh` | • Substring and case-insensitive record search<br>• Inverted filtering for record deletion<br>• Silent existence checks (`if grep -q ...`) |
| **4** | **Data Wrangling & Pipelines** | `cut`, `sort -t',' -k...`, `uniq -c`, `tr` | `search_engine.sh`<br>`analytics.sh`<br>`utils.sh` | • Multi-column sorting (by date, title, ID)<br>• Frequency counting for campus loss hotspots<br>• String case translation (`tr '[:upper:]' '[:lower:]'`) |
| **5** | **Atomic File Operations & I/O** | `mktemp`, `mv`, `>`, `>>`, `<` | `record_manager.sh`<br>`claim_manager.sh`<br>`audit_logger.sh` | • Race-condition-free CSV updates via atomic temporary swaps<br>• Append-only immutable audit trail logging |
| **6** | **Archival & Compression** | `tar -czf`, `tar -xzf`, `gzip` | `backup_restore.sh` | • Full system state snapshots (`database/`, `logs/`, `reports/`)<br>• Safe extraction and restoration |
| **7** | **Cryptographic Integrity** | `sha256sum`, `shasum -a 256` | `backup_restore.sh` | • SHA-256 checksum generation (`.sha256`)<br>• Tamper and corruption verification before restoring |
| **8** | **Retention & Cleanup** | `find -mtime +N -delete` | `backup_restore.sh` | • Automated rolling backup retention policy (auto-purging files older than 7 days) |
| **9** | **Scheduled Automation** | `cron`, `crontab` syntax | `cron/backup_cron.sh` | • Unattended nightly automated backup execution and cron logging |
| **10** | **Process & Resource Monitoring** | `df -h`, `free -m`, `ps aux`, `uptime`, `uname` | `system_monitor.sh` | • Server diagnostics, CPU/RAM/Disk health checks, top running processes |
| **11** | **Shell Programming Constructs** | Functions, `local`, `${VAR:-def}`, `$?`, `case`, `while` | `main.sh`<br>`utils.sh` | • Modular code architecture, ANSI terminal coloring, menu routing, portable path discovery |

---

## 3. Deep-Dive Explanations of Core Unix Concepts

### 1. `awk` as a Mathematical & AI Matching Engine
Most people only use `awk` to print columns (`awk '{print $1}'`). In LostLink, **`awk` is used as a complete programming language**:
* **Associative Arrays:** Tokenizes titles and descriptions into dictionaries in memory, removes common English stop words (`the`, `with`, `and`), and calculates keyword intersection ratios.
* **Date Math & Scoring:** Parses `YYYY-MM-DD` strings, computes approximate elapsed day differences, and calculates a multi-factor weighted match score:
  $$\text{Score} = \text{Category}(35) + \text{Keywords}(35) + \text{Location}(20) + \text{Date}(10) = 100\%$$
* **Zero-Dependency JSON Serialization:** `utils.sh` contains an `awk` parser that reads any CSV table with headers and outputs valid RFC-compliant JSON arrays for the API bridge.

### 2. Atomic Flat-File Database Updates
When modifying a record in a CSV file (e.g., updating a claim status from `pending` to `approved`), directly writing to the file can cause corruption if interrupted.
LostLink uses POSIX-standard atomic file swaps:
```bash
temp_file=$(mktemp)
awk -F',' -v id="$item_id" -v nst="$new_status" '
BEGIN { OFS="," }
{ if ($1 == id) $9 = nst; print $0 }
' "$CSV_FILE" > "$temp_file" && mv "$temp_file" "$CSV_FILE"
```
The `mv` command is an atomic filesystem operation in Unix, ensuring the database is never left in a partial state.

### 3. Unix Pipelines for Campus Analytics
In `analytics.sh`, we compute campus loss hotspots without using any database query engines:
```bash
awk -F',' 'FNR > 1 { locs[$5]++ } END { for (l in locs) printf "%d|%s\n", locs[l], l }' "$LOST_CSV" \
  | sort -t'|' -k1,1nr \
  | head -n 5
```
* **Step 1:** `awk` builds an in-memory frequency map of locations ($5).
* **Step 2:** `sort -k1,1nr` sorts numerically in descending order.
* **Step 3:** `head -n 5` extracts the top 5 incident locations on campus.

### 4. Integrity-Verified Backup & Retention
In `backup_restore.sh`:
* Creates a compressed tarball: `tar -czf lostlink_backup_TIMESTAMP.tar.gz database/ logs/ reports/`
* Computes cryptographic signature: `sha256sum archive.tar.gz > archive.tar.gz.sha256`
* Enforces retention policy using `find`:
  ```bash
  find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete
  ```
* Before restoring, it runs `sha256sum -c` to ensure the backup has not suffered bit rot or tampering.

---

## 4. Member-by-Member Presentation Speech Guide

### Member 1: Architecture, Record Management & Auth
* **Script:** `record_manager.sh`
* **Speech:**
  > *"I handled the foundational data storage and record lifecycle. Instead of using SQL or cloud databases, our system uses flat CSV files adhering to Unix philosophy — text streams are universal. I wrote functions to add, list, update, and delete lost and found items. I implemented atomic updates using `mktemp` and `mv` so files are never corrupted. I also built sequential ID generation (`LST001`, `FND001`) by extracting the maximum numeric ID using `cut`, `sort -n`, and `tail`."*

### Member 2: Search Engine & Smart Matching Engine
* **Scripts:** `search_engine.sh`, `matching_engine.sh`
* **Speech:**
  > *"I developed the search and matching algorithms using `awk`, `grep`, and `sort`. In `search_engine.sh`, our script supports multi-parameter filtering across categories, dates, and locations case-insensitively. In `matching_engine.sh`, I created a weighted scoring engine that compares lost and found items. It scores them based on 4 criteria: category match (35%), keyword token overlap using associative arrays (35%), campus location proximity (20%), and date proximity (10%). Matches above 70% are classified as High Confidence."*

### Member 3: Claim Processing & Audit Logging
* **Scripts:** `claim_manager.sh`, `audit_logger.sh`
* **Speech:**
  > *"I managed the claim verification workflow and system auditing. When a student submits a claim with proof of ownership, `claim_manager.sh` updates the found item status and logs the event. When an administrator approves the claim, the script atomically transitions the item status to `returned` and marks the associated lost item as `recovered`. Every critical action is recorded in an immutable audit log (`logs/audit.log`) using Unix timestamping and append redirection (`>>`), with fast log querying powered by `tail` and `grep`."*

### Member 4: Analytics, Automated Reports, Backups & Monitoring
* **Scripts:** `analytics.sh`, `report_generator.sh`, `backup_restore.sh`, `system_monitor.sh`, `cron/backup_cron.sh`
* **Speech:**
  > *"I was responsible for business intelligence, reporting, backup integrity, and system health. Using `awk`, `wc`, and `sort`, `analytics.sh` computes campus recovery rates and identifies loss hotspots. `report_generator.sh` automatically compiles daily, weekly, and monthly reports in both formatted TXT and responsive HTML. I also implemented enterprise backup automation using `tar`, `gzip`, SHA-256 checksums, and `cron` scheduling with a 7-day retention policy via `find -mtime`."*

---

## 5. Potential Professor Viva Questions & Exact Answers

**Q1: Why did you use CSV files instead of MySQL or SQLite?**  
* **Answer:** *"The core objective of this project is to demonstrate mastery of Unix utilities. By using flat CSV files, we are able to leverage Unix text-processing commands like `awk`, `sed`, `grep`, `cut`, `sort`, and `uniq` to handle data manipulation directly, adhering to the Unix philosophy that 'text is the universal interface'."*

**Q2: How do you prevent race conditions or partial writes when updating a CSV?**  
* **Answer:** *"We use atomic temporary file replacement. We stream the updated data into a temporary file using `mktemp`, and upon successful execution, we use `mv` to overwrite the target CSV. In POSIX filesystems, `mv` within the same filesystem is an atomic inode operation."*

**Q3: How does the Smart Matching algorithm calculate keyword similarity?**  
* **Answer:** *"In `matching_engine.sh`, we use `awk` to convert titles and descriptions to lowercase, strip punctuation, filter out common stop-words, and store unique tokens into associative arrays. We then measure the token intersection over the total unique tokens and scale it to a 35-point score."*

**Q4: How do you ensure backups aren't corrupted when restoring?**  
* **Answer:** *"Every time `backup_restore.sh` creates a tarball (`tar -czf`), it immediately computes and stores a cryptographic hash using `sha256sum`. Before restoring, the script validates the current archive against the stored hash. If even a single byte differs, restoration halts."*
