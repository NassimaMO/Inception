# Developer Documentation

This document explains how to set up, build, and manage the Inception stack from a developer's perspective.

## Prerequisites

- A virtual machine running Debian
- Docker and Docker Compose installed
- The domain `nnassiri.42.fr` resolving to the VM's local IP — add to `/etc/hosts` on your VM:

```
127.0.0.1    nnassiri.42.fr
```

- Docker configured to use `/home/nnassiri/data` as its data root — create or edit `/etc/docker/daemon.json`:

```json
{
  "data-root": "/home/nnassiri/data"
}
```
you must migrate the existing Docker data to the new location before restarting:
```bash
sudo systemctl stop docker
sudo cp -rp /var/lib/docker/. /home/nnassiri/data/
sudo systemctl start docker
```

This ensures named volumes are stored under `/home/nnassiri/data/volumes/` as required by the subject.

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

**`secrets/`** — at the repository root, sensitive values mounted as files inside containers:

```
secrets/
├── db_password.txt          # password for MYSQL_USER
├── db_root_password.txt     # MariaDB root password
└── credentials.txt          # WordPress account passwords:
                              #   ADMIN_PASSWORD=your_admin_password
                              #   REVIEWER_PASSWORD=your_reviewer_password
```

### 2. Git ignore

Confirm `.gitignore` (at repo root) excludes both `secrets/` and `srcs/.env` **before** the first commit that touches either — committing them even once leaves them in Git history permanently.

## Building and launching

Everything goes through the `Makefile` at the repository root, which wraps Docker Compose (`srcs/docker-compose.yml`):

| Command | Effect |
|---|---|
| `make` / `make all` | `build` + `up` |
| `make build` | Builds the 3 images |
| `make up` | Starts the stack |
| `make state` | Shows container status (`docker compose ps`) |
| `make network` | Lists Docker networks (`docker network ls`) |
| `make volumes` | Lists Docker volumes (`docker volume ls`) |
| `make down` | Stops and removes containers, keeps volumes/data |
| `make clean` | `down` + prunes unused Docker images/containers |
| `make fclean` | `clean` + removes all images/volumes + wipes `/home/nnassiri/data/` |
| `make re` | `fclean` + `make` — full rebuild from a clean state |

Use `make re` to re-test first-launch initialization (MariaDB table creation, WordPress install) — the initialization only runs when the volumes are empty.

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

Two services hold persistent state via named volumes managed by Docker:

| Container | Path in container | Volume name | Host path (approximate) | Contents |
|---|---|---|---|---|
| `mariadb` | `/var/lib/mysql` | `srcs_db_volume` | `/home/nnassiri/data/volumes/srcs_db_volume/_data` | Database tables, system tables |
| `wordpress` | `/var/www/html` | `srcs_wp_volume` | `/home/nnassiri/data/volumes/srcs_wp_volume/_data` | WordPress core files, themes, plugins, uploads |

Both entrypoint scripts check whether their data is already present before running initialization. On a fresh empty volume, full initialization runs once and writes to the volume. On every subsequent start, initialization is skipped and the actual service (`mysqld`, `php-fpm`) launches directly as PID 1.

NGINX does not persist application data — its TLS certificate is generated fresh at container startup and lives only inside the container filesystem.

To force full re-initialization (e.g. to reset passwords or the WordPress install), run `make re` — this removes the volumes and rebuilds everything from scratch.