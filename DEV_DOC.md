# Developer Documentation

This document explains how to set up, build, and manage the Inception stack from a developer's perspective.

## Prerequisites

- A virtual machine running Debian or Alpine
- Docker and Docker Compose installed
- The domain `nnassiri.42.fr` resolving to the VM's local IP address (added manually to `/etc/hosts` on the host you're testing from — this is outside Docker, a system-level step)

## Setting up the environment from scratch

### 1. Configuration files

Two sets of files must be created before the first build — neither is versioned in Git.

**`srcs/.env`** — non-sensitive configuration, read by Docker Compose:

```env
DOMAIN_NAME=nnassiri.42.fr
MYSQL_DB=wordpress
MYSQL_USER=nassima_user
WP_ADMIN_EMAIL=your.email@example.com
```

**`secrets/`** — at the repository root, sensitive values, never read directly by Compose (mounted as files in containers):

```
secrets/
├── db_password.txt          # password for MYSQL_USER
├── db_root_password.txt     # MariaDB root password
└── credentials.txt          # WordPress account passwords, KEY=value format:
                              #   ADMIN_PASSWORD=...
                              #   REVIEWER_PASSWORD=...
```

### 2. Git ignore

Confirm `.gitignore` (at repo root) excludes both `secrets/` and `srcs/.env` **before** the first commit that touches either — committing them even once leaves them in Git history permanently.

## Building and launching

Everything goes through the `Makefile` at the repository root, which wraps Docker Compose (`srcs/docker-compose.yml`):

| Command | Effect |
|---|---|
| `make` / `make all` | Builds the 3 images and starts the stack (detached) |
| `make state` | Shows container status (`docker compose ps`) |
| `make network` | Lists Docker networks (`docker network ls`) |
| `make volumes` | Lists Docker volumes (`docker volume ls`) |
| `make down` | Stops and removes containers, keeps volumes/data |
| `make clean` | `down` + prunes unused Docker images/containers |
| `make fclean` | `clean` + removes all images/volumes + wipes `/home/nnassiri/data/` |
| `make re` | `fclean` + `make` — full rebuild from a clean state |

`make re` is the command to use whenever you want to re-test the first-launch initialization logic (MariaDB table creation, WordPress install) — since that logic only runs when the bind-mounted data directories are empty.

## Managing containers and volumes

```bash
docker compose -f srcs/docker-compose.yml logs -f <service>
# follow logs for a single service: nginx, wordpress, or mariadb
```

```bash
docker exec -it <container_name> bash
# get a shell inside a running container, e.g. to inspect files or test a command manually
```

```bash
docker network inspect inception
# verify which containers are attached to the custom bridge network
```

When debugging a startup failure, check services in dependency order: **MariaDB first**, then **WordPress**, then **NGINX** — since WordPress's entrypoint waits on MariaDB, and NGINX forwards PHP requests to WordPress. A failure in MariaDB tends to surface as a timeout or 502 further down the chain, not as an obvious error in NGINX's own logs.

## Where data is stored and how it persists

Two services hold persistent state, via bind mounts to the host filesystem (as required by the subject, under `/home/nnassiri/data/`):

| Container | Mounted path (in container) | Host path | Contents |
|---|---|---|---|
| `mariadb` | `/var/lib/mysql` | `/home/nnassiri/data/db` | Database tables, system tables |
| `wordpress` | `/var/www/html` | `/home/nnassiri/data/wp` | WordPress core files, themes, plugins, uploads |

Both entrypoint scripts (`requirements/mariadb/tools/entrypoint.sh`, `requirements/wordpress/tools/entrypoint.sh`) check whether their respective data directory is already populated before running any initialization (`mysql_install_db`, `wp core install`, etc.). This makes the setup idempotent: on a fresh/empty volume, the full initialization runs once; on every subsequent container start, it's skipped and the actual service (`mysqld`, `php-fpm`) is launched directly — which is also why `make fclean` (wiping the host data directories) is required to force re-initialization during development.

NGINX does not persist any application data — it only holds its TLS certificate (generated at container startup, not bind-mounted) and reads its configuration from the image itself.
