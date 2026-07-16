# Local Bench Lifecycle Runbook

**Audience**: Developers bootstrapping local Frappe runtime for a client or product.

**Purpose**: Create, use, and tear down a disposable local Bench under `benches/`. Treat the Bench as runtime state — never commit it.

---

## Prerequisites

| Requirement | Check |
|-------------|-------|
| Frappe Bench CLI installed | `bench --version` |
| Python 3.10+ and `pip` | `python3 --version` |
| MariaDB or PostgreSQL server | `mysql --version` or `psql --version` |

> **Note**: Supported Frappe version and toolchain are not yet pinned in this repository (see [Deferrals](../../README.md#deferrals)). Verify compatibility before bootstrapping.

---

## Create a Bench

### Automated (recommended)

```bash
./scripts/bootstrap-bench.sh <client>
```

The script:
1. Validates `<client>` is a safe alphanumeric name.
2. Confirms the target path resolves under `benches/<client>-bench/`.
3. Checks that `bench` is on `PATH`.
4. Creates the directory and runs `bench init`.

### Manual

```bash
# From repository root
mkdir -p benches/<client>-bench
bench init benches/<client>-bench
```

---

## Use a Bench

Always enter the Bench directory and use bare `bench` commands:

```bash
cd benches/<client>-bench
```

### Fetch and install a custom app

```bash
bench get-app <repository-url>
bench --site <site-name> install-app <app-name>
```

### Common operations

| Action | Command |
|--------|---------|
| Create a development site | `bench new-site <site-name> --db-type mariadb` |
| Start development server | `bench start` |
| Run migrations | `bench --site <site-name> migrate` |
| Run console | `bench --site <site-name> console` |
| List apps in site | `bench --site <site-name> list-apps` |
| Build frontend assets | `bench build` |

### Explicit `--site <site>` Rule

**Every site-scoped command MUST include `--site <site-name>`.** Do not rely on a default site context. This keeps operations explicit, auditable, and prevents accidental operations on the wrong site.

Correct:
```bash
bench --site client-x-dev migrate
bench --site client-x-dev console
```

Incorrect (no explicit site):
```bash
bench migrate        # WRONG — which site?
bench console        # WRONG — ambiguous target
```

### DocType Creation — Never Manual

Frappe migrations create DocType directories. **Never create a DocType folder by hand.** Always use:

```bash
bench --site <site-name> make-app <app-name>
# then define the DocType via the app's doctypes/ directory
# and run:
bench --site <site-name> migrate
```

---

## Manage Multiple Sites

A single Bench can host multiple development sites:

```bash
bench new-site site-alpha --db-type mariadb
bench new-site site-beta --db-type mariadb
bench --site site-alpha install-app my-app
bench --site site-beta install-app my-app
bench --site site-alpha migrate
```

Each site is isolated within the Bench's `sites/` directory.

---

## Teardown a Bench

### Automated (recommended)

```bash
./scripts/remove-bench.sh <client>
```

The script:
1. Validates the client name.
2. Confirms the path is under `benches/`.
3. Asks for explicit confirmation (`yes`).
4. Removes the entire Bench directory.

### Manual

```bash
rm -rf benches/<client>-bench
```

> **Warning**: This permanently deletes all sites, databases, apps, and configuration within the Bench. There is no recovery.

---

## Troubleshooting

| Issue | Likely Cause | Resolution |
|-------|--------------|------------|
| `bench: command not found` | Bench CLI not installed or not on PATH | `pip install frappe-bench` |
| `bench init` fails | Missing system dependencies | Check Python, Node.js, Redis, MariaDB versions |
| Site creation fails | Database server not running | Start `mariadbd` or `postgresql` service |
| Port already in use | Another Bench or service running | Stop the other service or change port |
| Migration errors | App incompatibility or DB schema drift | Verify Frappe version matches app requirements |

---

## References

- [Architecture: Control-Plane Topology](../architecture/control-plane-adr.md)
- [Script: bootstrap-bench.sh](../../scripts/bootstrap-bench.sh)
- [Script: remove-bench.sh](../../scripts/remove-bench.sh)
