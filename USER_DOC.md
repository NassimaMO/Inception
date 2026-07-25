# User Documentation

This document explains how to use the Inception stack as an end user or administrator — no technical Docker knowledge required.

## What this stack provides

The Inception stack is a self-hosted WordPress website, made of three services running together:

| Service | Role |
|---|---|
| **NGINX** | The only entry point to the website. Handles HTTPS (encrypted connections) on port 443. |
| **WordPress** | The actual website / blogging platform — pages, articles, admin panel. |
| **MariaDB** | The database storing all WordPress content (articles, users, settings). |

You never interact with WordPress or MariaDB directly — everything goes through NGINX, at the address below.

## Starting and stopping the stack

From the root of the repository:

```bash
make          # builds and starts all services
```

```bash
make down     # stops the services (data is kept)
```

```bash
make re       # full reset: stops everything, wipes all data, rebuilds from scratch
```

`make re` is destructive — it deletes the database and all WordPress files. Use it only when you intentionally want a fresh start.

## Accessing the website

| What | Address |
|---|---|
| Website | `https://nnassiri.42.fr` |
| Admin panel | `https://nnassiri.42.fr/wp-admin` |

Your browser will show a security warning ("connection not private" or similar) the first time you visit. This is expected — the site uses a self-signed certificate (valid for this local/educational setup, not issued by a public certificate authority). You can safely proceed past the warning for this project.

## Accounts

Two WordPress accounts are configured:

| Username | Role |
|---|---|
| `nassima` | Administrator — full access to the admin panel |
| `reviewer` | Author — can write/manage content, no admin access |

Note: per project requirements, the administrator username intentionally does not contain "admin" or "administrator".

## Locating and managing credentials

All passwords are stored locally, outside of the Git repository, in two places:

- `secrets/` — at the repository root. Contains the database passwords (`db_password.txt`, `db_root_password.txt`) and the WordPress account passwords (`credentials.txt`, in `KEY=value` format: `ADMIN_PASSWORD=...`, `REVIEWER_PASSWORD=...`).
- `srcs/.env` — non-sensitive configuration (domain name, database name, admin email).

These files are never committed to Git. If you need to check or change a password, edit the relevant file directly, then run `make re` to apply the change (since credentials are only read on first initialization of each container).

## Checking that everything is running correctly

```bash
make state
```

This shows the status of all three containers. You should see all of them as `Up` (or `running`). If one shows `Restarting` or `Exited`, something went wrong at startup — see `DEV_DOC.md` for how to investigate.

You can also simply open `https://nnassiri.42.fr` in a browser — if the WordPress homepage loads, the whole stack (NGINX → WordPress → MariaDB) is working end to end.
