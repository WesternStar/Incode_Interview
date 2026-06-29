# Chinook htmx Demo

A small Go web app that browses the [Chinook](../Chinook_PostgreSql.sql) sample
music store database (artists → albums → tracks) using
[htmx](https://htmx.org) for the UI — every interaction is a server-rendered
HTML partial swapped into the page, no client-side JS framework or JSON API.

## How it works

- `main.go` — HTTP server, routes, graceful shutdown.
- `db.go` — `pgx` queries against the `artist`, `album`, and `track` tables.
- `handlers.go` — translates requests into queries and renders templates.
- `templates.go` / `templates/*.html` — `html/template` partials, embedded
  into the binary via `go:embed`.
- `templates/index.html` — full page shell: a search box and three columns
  (artists, albums, tracks).
- `templates/artists.html`, `albums.html`, `tracks.html` — htmx-swapped
  partials returned by `/artists`, `/artists/{id}/albums`,
  `/albums/{id}/tracks`.

Flow: typing in the search box hits `GET /artists?q=...` and swaps the
artist list; clicking an artist hits `GET /artists/{id}/albums` and swaps
the album list; clicking an album hits `GET /albums/{id}/tracks` and swaps
the track table.

## Running locally (Docker Compose)

The simplest way to run this end-to-end: `docker-compose.yml` spins up a
Postgres container seeded from `../Chinook_PostgreSql.sql` on first start
(via the standard `/docker-entrypoint-initdb.d` mechanism), plus the app
itself, wired together with no manual steps.

```bash
docker compose up --build
```

Open http://localhost:8080. To wipe the seeded data and start fresh:

```bash
docker compose down -v
```

Note: the Chinook seed script itself does
`DROP DATABASE IF EXISTS chinook; CREATE DATABASE chinook;`, so the Postgres
container's init connection is pointed at the default `postgres` maintenance
database (`POSTGRES_DB: postgres` in `docker-compose.yml`) — the seed script
creates and populates the `chinook` database itself rather than relying on
`POSTGRES_DB` to do it.

## Running against another Postgres (e.g. the RDS instance in `aws_infra/`)

The seed script's `\c chinook` mid-file means it always ends up creating and
populating a database literally named `chinook` on the target server,
regardless of which dbname you connect with initially — so point the seed
connection at the server's default maintenance DB (`postgres`), then point
the *app* at the `chinook` database that gets created:

```bash
DATABASE_URL=postgres://appadmin:<password>@<rds-endpoint>:5432/postgres ./scripts/seed.sh
DATABASE_URL=postgres://appadmin:<password>@<rds-endpoint>:5432/chinook go run .
```

## Building the image directly (without Compose)

```bash
docker build -t chinook-htmx-demo .
docker run -p 8080:8080 -e DATABASE_URL=postgres://user:pass@host:5432/appdb chinook-htmx-demo
```

## Deploying onto the existing EKS cluster

This app is the natural candidate to replace the placeholder
`nginxdemos/hello` image referenced in [../k8s/variables.tf](../k8s/variables.tf)
(`demo_app_image`). To do so:

1. Build and push this image to a registry the cluster can pull from (e.g.
   ECR in the same AWS account as `aws_infra/`).
2. Point `demo_app_image` (in `k8s/terraform.tfvars`) at that image.
3. Add a `DATABASE_URL` env var to the Deployment in
   [../k8s/app.tf](../k8s/app.tf), built from the existing `db-credentials`
   Secret keys (`host`, `port`, `dbname`, `username`, `password`) that
   `k8s/secret.tf` already populates from the RDS instance in `aws_infra/`.

This isn't wired up yet — happy to do that next if you want the app actually
running on the cluster.
