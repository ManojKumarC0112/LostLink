# LostLink: Unix & Shell Scripting-Powered Campus Lost & Found System

[![Unix](https://img.shields.io/badge/Platform-Linux%20%7C%20POSIX%20%7C%20WSL-blue.svg)](https://www.gnu.org/software/bash/)
[![Language](https://img.shields.io/badge/Language-GNU%20Bash%20%7C%20POSIX%20sh-brightgreen.svg)](https://www.gnu.org/software/bash/)
[![Engine](https://img.shields.io/badge/Core%20Engine-awk%20%7C%20sed%20%7C%20grep%20%7C%20tar-orange.svg)](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/contents.html)
[![Frontend](https://img.shields.io/badge/Frontend-React%2018%20%7C%20TailwindCSS-61DAFB.svg)](https://react.dev/)

> **Academic Course Project**: Unix & Shell Scripting  
> **Team Structure**: 4 Members  
> **Core Architectural Principle**: *Bash is the application; the website is its interface.*  
> **Database**: Flat-file CSV storage with atomic Unix file transactions.

---

## Table of Contents
1. [Project Overview & System Philosophy](#1-project-overview--system-philosophy)
2. [High-Level Architecture](#2-high-level-architecture)
3. [4-Member Team Breakdown & Viva Matrix](#3-4-member-team-breakdown--viva-matrix)
4. [Complete Directory & File Structure](#4-complete-directory--file-structure)
5. [Unix & Shell Scripting Concepts Catalog](#5-unix--shell-scripting-concepts-catalog)
6. [Detailed Module & Script Breakdown](#6-detailed-module--script-breakdown)
7. [Step-by-Step Execution & Testing Guide](#7-step-by-step-execution--testing-guide)
8. [Comprehensive Viva & Oral Defense Q&A](#8-comprehensive-viva--oral-defense-qa)

---

## 1. Project Overview & System Philosophy

Standard academic web development projects typically rely on high-level frameworks (Node.js, Django, Spring) and relational databases (MySQL, PostgreSQL), burying the fundamental operations of an operating system.

**LostLink** is intentionally built around the **Unix Philosophy**:
- **"Write programs that do one thing and do it well."**
- **"Write programs to work together."**
- **"Write programs to handle text streams, because that is a universal interface."**

### Key Engineering Realizations
1. **75% Bash & Unix Commands**: Every business operation — record insertion, validation, multi-criteria keyword search, weighted mathematical matching, claim lifecycle tracking, statistical aggregation, report generation, SHA-256 backup creation, and resource monitoring — is executed in **Bash** using utilities like `awk`, `sed`, `grep`, `sort`, `tar`, and `find`.
2. **Flat-File CSV Storage**: Data is stored in human-readable, portable comma-separated files (`database/*.csv`) without requiring database daemons.
3. **Atomic File Operations**: Eliminates race conditions during file updates via Unix `mktemp` and atomic `mv` operations.
4. **5% Python API Bridge**: A lightweight 150-line HTTP server (`api/server.py`) using Python's standard library to execute the Bash scripts via `subprocess.run` and stream output to HTTP clients.
5. **20% Presentation Layer**: A clean, responsive React 18 single-page dashboard styled with Tailwind CSS to visualize matches, statistics, and system health.
6. **Pure Terminal Interface**: The complete system can be run, demonstrated, and inspected entirely from the terminal (`backend/main.sh`) without starting the browser or web bridge.

---

## 2. High-Level Architecture

```
+-----------------------------------------------------------------------------------+
|                           PRESENTATION TIER (20%)                                 |
|         React 18 SPA · Tailwind CSS · Student & Admin Views · System Dashboard    |
+-----------------------------------------+-----------------------------------------+
                                          | JSON REST API Requests
                                          v
+-----------------------------------------------------------------------------------+
|                             API BRIDGE TIER (5%)                                  |
|         api/server.py · Zero-Dependency Python Bridge · subprocess.run            |
+-----------------------------------------+-----------------------------------------+
                                          | Command Line Arguments & Pipes
                                          v
+-----------------------------------------------------------------------------------+
|                       APPLICATION ENGINE TIER (75% BASH)                          |
|                                                                                   |
|  [Member 1]           [Member 2]              [Member 3]          [Member 4]      |
|  record_manager.sh    search_engine.sh        claim_manager.sh    analytics.sh    |
|  CRUD & Auth          Regex & Sort Filter     Claims & Returns    Hotspots & KPIs |
|                       matching_engine.sh      audit_logger.sh     report_gen.sh   |
|                       Weighted AI Scoring     Event Append Stream backup_rest.sh  |
|                                                                   sys_monitor.sh  |
+-----------------------------------------+-----------------------------------------+
                                          | POSIX System Calls & Text Streams
                                          v
+-----------------------------------------------------------------------------------+
|                        STORAGE & UNIX OS UTILITIES TIER                           |
|  Flat CSV Data (users, lost, found, claims) · logs/audit.log · reports/ · backups |
|  awk · sed · grep · cut · sort · uniq · tr · tar · gzip · sha256sum · find · cron |
+-----------------------------------------------------------------------------------+
```

---

## 3. 4-Member Team Breakdown & Viva Matrix

The workload and technical domains are cleanly separated across four team members:

| Member | Domain & Ownership | Script Responsibilities | Primary Unix Commands | Viva Defense Talking Points |
| :--- | :--- | :--- | :--- | :--- |
| **Member 1** | **Record Management & Flat-File Storage** | `backend/record_manager.sh`<br>`database/lost_items.csv`<br>`database/found_items.csv`<br>`database/users.csv` | `awk`, `sed`, `grep`, `cut`, `mktemp`, `mv`, `tail` | Explains CSV parsing, atomic updates using temporary file replacement (`mktemp` and `mv`), sequential auto-increment ID generation (`LST001`, `FND001`), and string escaping. |
| **Member 2** | **Search Engine & Smart Matching Engine** | `backend/search_engine.sh`<br>`backend/matching_engine.sh` | `awk` associative arrays, `grep -i`, `sort`, `uniq`, `tr`, date math | Explains multi-parameter search filtering, tokenization, stop-word elimination, and the 4-factor weighted scoring algorithm (Category 35%, Keywords 35%, Location 20%, Date 10%). |
| **Member 3** | **Claim Management & Security Audit** | `backend/claim_manager.sh`<br>`backend/audit_logger.sh`<br>`database/claims.csv`<br>`logs/audit.log` | `awk`, `sed`, `tail`, `wc`, redirection (`>>`, `>`), regex anchors | Explains claim state machine (`pending` $\rightarrow$ `approved` $\rightarrow$ `rejected`), multi-file status synchronization (`found` $\rightarrow$ `returned` & `lost` $\rightarrow$ `recovered`), and immutable timestamped audit logging. |
| **Member 4** | **Analytics, Reports, Backups & Monitor** | `backend/analytics.sh`<br>`backend/report_generator.sh`<br>`backend/backup_restore.sh`<br>`backend/system_monitor.sh`<br>`cron/backup_cron.sh` | `tar`, `gzip`, `sha256sum`, `find -mtime`, `cron`, `df`, `free`, `ps`, `uptime` | Explains multi-file metric computation in single `awk` passes, automated report compilation (TXT/HTML), SHA-256 backup integrity verification, rolling 7-day retention with `find`, and daemon cron automation. |

---

## 4. Complete Directory & File Structure

```text
LostLink/
├── backend/
│   ├── main.sh               # Master interactive terminal application (viva menu)
│   ├── utils.sh              # Shared library: paths, ANSI colors, ID generation, JSON serializer
│   ├── record_manager.sh     # [Member 1] CRUD operations for lost/found items & user authentication
│   ├── search_engine.sh      # [Member 2] Multi-criteria search, grep & awk filtering, sort pipelines
│   ├── matching_engine.sh    # [Member 2] Weighted scoring AI matching engine (0-100% confidence)
│   ├── claim_manager.sh      # [Member 3] Claim submission, verification, and status synchronization
│   ├── audit_logger.sh       # [Member 3] Immutable activity logging and stream query
│   ├── analytics.sh          # [Member 4] Recovery rate, category metrics, and loss hotspots
│   ├── report_generator.sh   # [Member 4] Automated TXT and responsive HTML report compiler
│   ├── backup_restore.sh     # [Member 4] Compressed tarballs, SHA-256 signatures, and auto-rotation
│   └── system_monitor.sh     # [Member 4] Real-time CPU, RAM, Disk, and process health diagnostics
├── database/
│   ├── users.csv             # Registered students, security desk staff, and administrators
│   ├── lost_items.csv        # Student reports of missing belongings
│   ├── found_items.csv       # Items turned in to campus security
│   └── claims.csv            # Ownership claim requests and verification status
├── logs/
│   ├── audit.log             # Append-only chronological system event log
│   └── cron.log              # Automated cron task execution output
├── reports/                  # Generated daily, weekly, and monthly reports (.txt & .html)
├── backups/                  # Compressed snapshots (.tar.gz) and checksum signatures (.sha256)
├── cron/
│   └── backup_cron.sh        # Cron execution wrapper script for nightly automation
├── api/
│   ├── server.py             # Lightweight Python bridge passing requests to Bash
│   └── requirements.txt      # Optional requirements (Flask/CORS)
├── frontend/
│   ├── index.html            # Standalone React 18 SaaS Dashboard (Tailwind CSS)
│   └── package.json          # Frontend build manifest
├── .gitignore                # Git ignore rules for clean repo tracking
├── PRESENTATION_GUIDE.md     # Presentation speech, script notes, and viva Q&A
└── README.md                 # Project technical documentation
```

---

## 5. Unix & Shell Scripting Concepts Catalog

Every major concept taught in an undergraduate Unix & Shell Scripting syllabus is applied in production-grade code within this project:

### 1. `awk` as a Full Computational Engine
- **Field & Record Separators**: Parses comma-delimited streams (`-F','`, `OFS=","`).
- **Internal Variables**: Utilizes `NR` (Record count), `NF` (Field count), `FNR` (File record count), and `FILENAME` (Current processing stream).
- **Associative Arrays (Hash Tables)**: Used in `matching_engine.sh` for keyword token dictionary mapping, in `analytics.sh` for category breakdowns, and for campus hotspot frequency counters (`locs[$5]++`).
- **String Functions**: Employs `tolower()`, `split()`, `gsub()`, `index()`, and `substr()`.
- **Mathematical Computation & Formatted Printing**: Floating-point percentage recovery rate calculations and aligned tabular output via `printf`.
- **Zero-Dependency JSON Serialization**: `utils.sh` uses `awk` to convert any standard CSV into an RFC-compliant JSON array.

### 2. Stream Editing (`sed`)
- **Prefix Removal**: Extracts numeric components of alphanumeric keys (`sed "s/^$prefix//"`).
- **Stream Formatting**: Prepends bullet points to hotspot reports (`sed 's/^/  • /'`).
- **Sanitization**: Replaces commas inside user input text to avoid breaking CSV column alignment (`title="${title//,/;}"`).

### 3. Pattern Matching (`grep`)
- **Case-Insensitive Search**: `grep -i` for keyword discovery.
- **Inverted Row Filtering**: `grep -v "^$item_id,"` to delete specific records without modifying surrounding lines.
- **Silent Status Checking**: `if grep -q ...; then` checks for username or item existence using Unix exit codes ($0$ on match, non-zero on miss) without producing unwanted standard output.
- **Regular Expression Anchors**: `^` anchors searches to the beginning of the line to prevent partial string matches.

### 4. Text Wrangling & Sorting Pipelines
- **`cut`**: Extracts specific column subsets (`cut -d',' -f1,5`).
- **`sort`**: Sorts by specific fields (`sort -t',' -k7,7r` for descending dates; `sort -n` for numeric sort; `sort -f` for case-insensitive alphabetic sort).
- **`uniq -c`**: Counts occurrences of adjacent identical lines for statistical distribution.
- **`tr`**: Character translation and deletion (`tr '[:upper:]' '[:lower:]'`, `tr -d '%'`).
- **`wc -l`**: Accurate line counting for database record statistics.
- **`date`**: Timestamp generation (`date "+%Y-%m-%d %H:%M:%S"`), file modification time reading, and epoch approximation.

### 5. Atomic File Operations & Redirection
- **Standard Redirection Operators**: Standard Input (`<`), Output Overwrite (`>`), Append (`>>`), and Error Redirection (`2>&1`).
- **Atomic File Swaps**: Writing directly to an active file (`cat data > data`) truncates the file before reading, causing fatal loss. LostLink creates a secure scratch file with `mktemp`, formats the update, and executes `mv "$temp_file" "$target_csv"`. In POSIX filesystems, `mv` within the same partition is an atomic pointer update.

### 6. Archival, Compression & Cryptographic Integrity
- **`tar` & `gzip`**: Multi-directory snapshots (`tar -czf "$archive" database/ logs/ reports/`).
- **`sha256sum`**: Cryptographic hash calculation. Writes `.sha256` digest files and verifies integrity with `sha256sum -c` before extraction to prevent corrupted restores.
- **`find -mtime`**: Locates and automatically purges archives older than $N$ days (`find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete`).

### 7. Process & Hardware Diagnostics
- **`df -h`**: Inspects disk storage availability, capacity, and percentage used.
- **`free -m`**: Extracts system memory metrics (total, used, free RAM).
- **`ps aux`**: Captures process tables, sorting top resource-consuming jobs.
- **`uptime` & `uname`**: System load averages, running time, host architecture, and kernel versions.

### 8. Automation via `cron`
- System background daemon integration via standard 5-parameter cron syntax:
  ```cron
  0 0 * * * /path/to/LostLink/cron/backup_cron.sh >> /path/to/LostLink/logs/cron.log 2>&1
  ```

---

## 6. Detailed Module & Script Breakdown

### `backend/utils.sh`
- **Dynamic Path Resolution**: `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` ensures scripts execute properly regardless of working directory.
- **Terminal Palette**: ANSI escape variables (`COLOR_CYAN`, `COLOR_GREEN`, `COLOR_RED`, `COLOR_RESET`).
- **`get_next_id "$file" "$prefix"`**: Finds the maximum numeric ID from a CSV and formats the next sequential ID (`LST001`, `FND001`, `CLM001`).
- **`log_audit "$module" "$user" "$details"`**: Writes timestamped entries to `logs/audit.log`.
- **`csv_to_json "$file"`**: Universal `awk` script converting CSV rows into JSON.

### `backend/record_manager.sh` (Member 1)
- Handles user registration, authentication, item insertion, listing, updating, and deletion.
- Enforces data integrity by preventing duplicate usernames and sanitizing commas.
- Uses `awk` and `mktemp` for record updates and `grep -v` for deletions.

### `backend/search_engine.sh` (Member 2)
- Multi-criteria search across lost items, found items, or combined datasets.
- Filters simultaneously by:
  - Free-text Keyword (searches Title, Description, Location, and Category case-insensitively).
  - Category (Exact match or `all`).
  - Location (Partial substring match).
  - Status (`lost`, `found`, `claimed`, `returned`, etc.).
  - Sort Order (`date_desc`, `date_asc`, `title`, `id`).

### `backend/matching_engine.sh` (Member 2)
- Implements an AI-style weighted matching engine in pure `awk`:
  1. **Category Match (35%)**: Exact category match awards 35 points; mismatch awards 0.
  2. **Keyword Match (35%)**: Tokenizes both titles and descriptions, removes common stop words (`the`, `with`, `in`, `and`, `for`), calculates Jaccard keyword overlap ratio, and scales to 35 points.
  3. **Location Match (20%)**: Exact match awards 20 points; shared campus building keywords award 15 points.
  4. **Date Proximity (10%)**: Dates within 2 days award 10 points; within 7 days award 5 points.
- Outputs candidate pairs with match percentage, breakdown, and classification (`HIGH` $\ge 70\%$, `MODERATE` $45-69\%$, `LOW` $25-44\%$).

### `backend/claim_manager.sh` (Member 3)
- Submits claims for found items with student ownership proof.
- Automatically transitions found item status to `claimed`.
- On admin review:
  - If **approved**: found item becomes `returned`, claimant's matching lost item becomes `recovered`, and status timestamps update.
  - If **rejected**: reason is recorded and item becomes claimable again.

### `backend/audit_logger.sh` (Member 3)
- Maintains chronological event stream in `logs/audit.log`.
- Formats logs into structured tables or JSON via `awk`.
- Provides keyword and line-count filtering (`tail -n`, `grep -i`).

### `backend/analytics.sh` (Member 4)
- Computes core KPIs in a single `awk` pass over multiple CSV files:
  - Total Lost, Total Found, Pending Claims, Returned Items, Candidate Matches.
  - Recovery Rate: $\frac{\text{Returned Items}}{\text{Total Lost Items}} \times 100\%$.
- Identifies Top 5 campus loss hotspots using `awk` associative arrays piped to `sort -nr`.

### `backend/report_generator.sh` (Member 4)
- Compiles periodic summaries (Daily, Weekly, Monthly).
- Produces:
  - Formatted terminal report.
  - Timestamped text document in `reports/report_<type>_<timestamp>.txt`.
  - Self-contained styled HTML file in `reports/report_<type>_<timestamp>.html`.

### `backend/backup_restore.sh` (Member 4)
- Creates `.tar.gz` snapshots containing `database/`, `logs/`, and `reports/`.
- Calculates and stores SHA-256 digests (`.sha256`).
- Implements automated rotation via `find -mtime +7 -delete`.
- Verifies SHA-256 checksums before allowing restoration.

### `backend/system_monitor.sh` (Member 4)
- Gathers hardware and operating system metrics using `uname`, `hostname`, `uptime`, `df -h`, `free -m`, and `ps aux`.
- Calculates storage utilization and counts active records in all CSV tables.

### `backend/main.sh` (Master CLI)
- Interactive terminal menu designed for classroom presentations and faculty defense.
- Provides numbered menus for all 7 application domains without screen clutter.
- Handles carriage-return stripping (`${choice//$'\r'/}`) for smooth cross-platform execution on Windows Git Bash, WSL, macOS, and native Linux.

### `api/server.py`
- Minimal Python HTTP bridge implementing `http.server`.
- Routes HTTP requests to corresponding shell scripts using `subprocess.run`.
- Automatically locates the appropriate Bash interpreter across Windows Git Bash, WSL, and Linux `/bin/bash`.
- Serves static frontend files and enables CORS.

---

## 7. Step-by-Step Execution & Testing Guide

### Option A: Pure Terminal Interface (Faculty Viva Demonstration)

Open your terminal (Linux, macOS, WSL, or Git Bash on Windows):

```bash
# 1. Navigate to the project root
cd "c:/Users/manoj/Desktop/unix project"

# 2. Grant execution permissions (Linux/macOS/WSL)
chmod +x backend/*.sh cron/*.sh

# 3. Launch the Master Interactive Terminal Interface
bash backend/main.sh
```

#### Menu Navigation:
```text
================================================================
                   LOSTLINK CAMPUS SYSTEM                       
         Unix & Shell Scripting Application Engine              
================================================================
MAIN APPLICATION MENU:
  [1] Lost & Found Records       (Add, View, Update, Delete)
  [2] Search & Filter Records    (Multi-criteria Unix Filter)
  [3] Smart Matching Engine      (AI Weighted Scoring)
  [4] Claim Management           (Submit & Review Claims)
  [5] Analytics & Reports        (Statistics, Hotspots, Reports)
  [6] Backup & Restore           (Snapshots, SHA-256, Recovery)
  [7] System Monitor & Logs      (CPU, RAM, Disk, Audit Trail)
  [0] Exit
```

---

### Option B: Running Individual Scripts Directly

Any member can demonstrate their individual module from the command line:

```bash
# Member 1: List all lost items
bash backend/record_manager.sh list lost all

# Member 2: Run the Smart Matching Engine
bash backend/matching_engine.sh match-all

# Member 2: Search for items in Library
bash backend/search_engine.sh search all "Library"

# Member 3: View pending claims
bash backend/claim_manager.sh list pending

# Member 3: Inspect recent audit logs
bash backend/audit_logger.sh view 15 all

# Member 4: Calculate Campus Analytics & Recovery Rate
bash backend/analytics.sh stats

# Member 4: Generate a Daily Report (TXT & HTML)
bash backend/report_generator.sh generate daily all admin

# Member 4: Create a Snapshot with SHA-256 Checksum
bash backend/backup_restore.sh create 7

# Member 4: Check System Health & Process Diagnostics
bash backend/system_monitor.sh status
```

---

### Option C: Running the Full Web Stack

1. **Start the API Server**:
   ```bash
   python api/server.py
   ```
2. **Open the Dashboard**:
   Navigate to **`http://localhost:5000`** in your browser.
3. Test creating items, reviewing claims, triggering backups, and viewing live Unix monitor stats directly through the visual dashboard.

---

## 8. Comprehensive Viva & Oral Defense Q&A

### Q1: Why did you use flat CSV files instead of a database like MySQL or SQLite?
> **Answer**: *"The explicit academic purpose of this project is to demonstrate command of Unix shell utilities. In enterprise systems, databases handle indexing and querying. In this project, we demonstrate that core POSIX utilities (`awk`, `sed`, `grep`, `sort`, `cut`, `uniq`) can serve as an application engine. This follows the Unix philosophy that 'text streams are the universal interface'."*

### Q2: How does your system prevent file corruption when two users write to a CSV simultaneously?
> **Answer**: *"We use atomic temporary file replacement. When updating or deleting records in `record_manager.sh` or `claim_manager.sh`, we write the modified stream to a unique temporary file created by `mktemp`. Once the write completes successfully, we replace the target file using `mv`. In POSIX filesystems, `mv` within the same filesystem is an atomic inode pointer update, preventing half-written or corrupted files."*

### Q3: How does the Smart Matching algorithm work under the hood?
> **Answer**: *"It is implemented entirely in POSIX `awk` inside `matching_engine.sh`. It evaluates candidate pairs across four weighted factors:
> 1. Category Match (35 points): Case-insensitive string equality.
> 2. Keyword Overlap (35 points): Tokenizes title and description, filters stop words using an associative array, and computes token intersection ratio.
> 3. Location Proximity (20 points): Checks building token matches.
> 4. Date Proximity (10 points): Computes calendar day differences.
> Total scores above 70% are classified as High Confidence."*

### Q4: How is data integrity guaranteed during backup restoration?
> **Answer**: *"When `backup_restore.sh` creates a tarball (`tar -czf`), it calculates a cryptographic SHA-256 hash and writes it to a `.sha256` digest file. When a restore is requested, the script computes the current SHA-256 hash of the archive and compares it against the stored digest using `awk`. If even a single byte has been modified or corrupted, the restore operation is aborted."*

### Q5: How is automated rotation implemented for backups?
> **Answer**: *"We enforce a 7-day retention policy using the Unix `find` command with the `-mtime` parameter:
> `find "$BACKUP_DIR" -name "lostlink_backup_*.tar.gz" -mtime +7 -delete`
> This automatically identifies and purges archives older than 7 days, preventing disk exhaustion."*

### Q6: What is the purpose of `server.py` if Bash is the application?
> **Answer**: *"Python is used strictly as an HTTP bridge (less than 150 lines of code). It performs zero business logic, matching, or file management. When the browser makes a request, Python executes the corresponding Bash script using `subprocess.run`, captures the standard output generated by `awk`, and sends it back to the client as JSON."*

---

## License & Academic Disclaimer
Developed for the **Unix & Shell Scripting** laboratory course. All core logic is implemented in **GNU Bash and POSIX utilities**.
