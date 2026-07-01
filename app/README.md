# Chinook htmx Demo

A small Go web app that browses the [Chinook](./Chinook_PostgreSql_SerialPKs.sql) sample
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
Postgres container seeded from `./Chinook_PostgreSql_SerialPKs.sql` on first start
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
`DROP DATABASE IF EXISTS chinook_serial; CREATE DATABASE chinook_serial;`, so the Postgres
container's init connection is pointed at the default `postgres` maintenance
database (`POSTGRES_DB: postgres` in `docker-compose.yml`) — the seed script
creates and populates the `chinook_serial` database itself rather than relying on
`POSTGRES_DB` to do it.

## Running against another Postgres (e.g. the RDS instance in `aws_infra/`)

The seed script's `\c chinook_serial` mid-file means it always ends up creating and
populating a database literally named `chinook_serial` on the target server,
regardless of which dbname you connect with initially — so point the seed
connection at the server's default maintenance DB (`postgres`), then point
the *app* at the `chinook_serial` database that gets created:

```bash
DATABASE_URL=postgres://appadmin:<password>@<rds-endpoint>:5432/postgres ./scripts/seed.sh
DATABASE_URL=postgres://appadmin:<password>@<rds-endpoint>:5432/chinook_serial go run .
```

## Building the image directly (without Compose)

```bash
docker build -t chinook-htmx-demo .
docker run -p 8080:8080 -e DATABASE_URL=postgres://user:pass@host:5432/appdb chinook-htmx-demo
```

## Deploying onto the existing EKS cluster

`k8s/` deploys this app (no more `nginxdemos/hello` placeholder) from an ECR
repo that `aws_infra/ecr.tf` creates. To ship a build:

```bash
cd aws_infra && terraform apply   # creates/updates the ECR repo, among other things
ECR_URL=$(terraform output -raw ecr_repository_url)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin "${ECR_URL%/*}"
docker build -t "$ECR_URL:latest" ../app
docker push "$ECR_URL:latest"
cd ../k8s && terraform apply       # demo_app_image_tag defaults to "latest"
```

`k8s/secret.tf` builds the `DATABASE_URL` the app needs from the RDS outputs
in `aws_infra/` plus `var.demo_app_db_name` (defaults to `chinook_serial`,
matching the database the seed script actually creates — see above). Don't
forget to run `scripts/seed.sh` against the RDS instance before traffic hits
the app, or the queries will return nothing.
