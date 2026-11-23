<div align="center">

# Solr Managed Schema Pull / Push Automation

**Pull, back up, and push managed-schema changes across SolrCloud configsets.**

![Bash](https://img.shields.io/badge/Bash-4EAA25?style=flat-square) ![Apache Solr](https://img.shields.io/badge/Apache_Solr-e18536?style=flat-square) ![Status-Historical](https://img.shields.io/badge/Status-Historical-64748b?style=flat-square)

[Motivation](#why-i-built-it) · [Workflow](#what-the-script-actually-does) · [Limitations](#important-limitations) · [Improvements](#what-i-would-change-today)

</div>

---

A small Bash utility I built to reduce repetitive Apache SolrCloud work when handling `managed-schema` files across multiple configsets.

> **Status:** Historical / learning automation project. The script reflects the environment and assumptions it was originally written for. It is useful as an example of my earlier operations-automation work, but it should be reviewed and hardened before use in another environment.

## Why I Built It

Working with many Solr configsets can turn a simple schema change into a repetitive process:

1. identify the target configsets,
2. download each `managed-schema`,
3. edit the files,
4. back up the current remote version,
5. upload the new version,
6. reload each affected collection/configset.

This script was my attempt to turn that repeated operational sequence into one predictable command flow.

## What the Script Actually Does

The script accepts two actions:

```bash
bash pull-push-managed-schema-solr.sh pull
bash pull-push-managed-schema-solr.sh push
```

It reads the targets from a local `list.txt` file.

### `pull`

For every entry in `list.txt`, the script:

1. creates a date-based working directory,
2. creates one subdirectory per target,
3. copies `managed-schema` from ZooKeeper using the Solr CLI,
4. stores the result under:

```text
managed-schema-new-YYYYMMDD/<target>/managed-schema
```

The intention is that the downloaded files can then be reviewed or edited locally before being pushed back.

### `push`

For every entry in `list.txt`, the script:

1. creates a date-based backup directory,
2. pulls the currently deployed `managed-schema` into that backup,
3. uploads the local edited schema from `managed-schema-new-YYYYMMDD/`,
4. calls the Solr Collections API to reload the target.

Backups are written under:

```text
managed-schema-backup-YYYYMMDD/<target>-backup/
```

So the basic safety idea was:

```text
Current remote schema
        ↓
Backup first
        ↓
Push edited schema
        ↓
Reload
```

## Environment Assumptions

The script was written around a specific Linux + SolrCloud environment and makes several assumptions:

- SolrCloud is in use.
- ZooKeeper is available through the Solr CLI.
- `jcmd` can identify the ZooKeeper process/configuration.
- `hostname -I` returns the address that should be used for ZooKeeper access.
- the Solr installation directory and HTTP port can be inferred from Java process arguments.
- a `list.txt` file already exists in the working directory.
- the edited schemas are stored in the same date-based directory created by the `pull` operation.
- collection reload is available through the local Solr Collections API.

## Important Limitations

This repository intentionally documents the script as it exists instead of presenting it as production-ready.

### 1. `list.txt` is required but is not included

The script immediately executes:

```bash
awk '1' $pwd/list.txt
```

but the current repository contains only the script and README. A target list therefore has to be created manually before running it.

Example:

```text
configset-a
configset-b
configset-c
```

The script calls these entries `collections`, but the ZooKeeper path being accessed is:

```text
zk:/configs/<name>/managed-schema
```

so operationally the list needs to match the config names available under SolrCloud's `/configs` tree.

### 2. Pull and push are coupled to the current date

The local edit directory is named using:

```bash
DATE=$(date +%Y%m%d)
```

Both `pull` and `push` use that value.

That means a pull performed on one day and a push performed on another day will point at different directories unless the files are moved or the script is adjusted.

### 3. Environment discovery is brittle

The script infers Solr information from fixed fields in `ps` output, including positions such as:

```bash
awk '{print$49}'
awk '{print$41}'
```

Those positions depend on the exact Java command line and can break when startup arguments or process layout changes.

A more robust version should discover configuration through explicit parameters, environment variables, or structured process inspection.

### 4. Authentication is embedded in the command

The committed script contains a placeholder-style credential string in the reload request:

```text
user:passowrd
```

Real credentials should never be committed to source code. A production version should obtain secrets from a protected runtime source such as environment variables or an external secret store.

### 5. Error handling is minimal

Most Solr CLI output is redirected to `/dev/null`, and the script does not stop when an individual copy or reload operation fails.

This means the final `finished` message does not prove that every target succeeded.

A hardened version should capture per-target results and fail explicitly when a backup, upload, or reload does not complete successfully.

### 6. Backup exists, but rollback is manual

The push flow preserves the previous remote schema before making a change, which is a useful safety step.

However, this repository does not contain an automated rollback action. Restoring from the backup would still require a separate manual operation or another script.

### 7. The shebang is malformed

The first line is currently:

```bash
# !bin/bash
```

instead of:

```bash
#!/bin/bash
```

So invoking the file directly may not select Bash correctly. Running it explicitly with `bash` avoids that particular issue.

## What I Would Change Today

If I rebuilt this utility now, I would keep the original operational idea but make the execution much more deterministic:

- pass Solr/ZooKeeper locations explicitly instead of scraping `ps`,
- validate every prerequisite before touching remote configuration,
- separate configset discovery from the action itself,
- use a stable workspace/run ID instead of coupling files to the current date,
- make backup, push, reload, verification, and rollback explicit phases,
- capture a result for every target,
- stop or safely continue according to a defined failure policy,
- keep credentials outside the repository,
- add `set -euo pipefail` where appropriate,
- quote paths and variables consistently,
- provide a dry-run mode,
- verify the deployed schema after upload,
- provide a deterministic rollback command.

A safer flow would look more like:

```text
Validate environment
        ↓
Resolve exact targets
        ↓
Pull current schemas
        ↓
Create immutable backup
        ↓
Validate proposed files
        ↓
Push one target
        ↓
Verify
        ↓
Reload
        ↓
Verify again
        ↓
Continue / stop according to policy
```

## What This Project Represents

This is one of my older Bash automation projects from my Application Support / Linux operations work.

The code is small, but the underlying instinct is still central to how I work today:

> **If the same operational sequence has to be performed repeatedly, make the sequence explicit and automate the repetitive part.**

My approach has evolved since then. Today I put much more emphasis on deterministic inputs, validation gates, observable outcomes, failure handling, and rollback.

That evolution is part of why I keep projects like this public: they show the progression from simple operational scripting toward more deliberate systems and automation engineering.
