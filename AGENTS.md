# AGENTS.md

Static PHP site in Apache via Docker, deployed by GitHub Actions.

## Layout

- `index.php` — the page; serves as `index.php` in `/var/www/html`
- `Dockerfile` — `php:8.3-fpm` + nginx + supervisord; add PHP extensions here
- `docker/nginx.conf` — server block; PHP is proxied to `127.0.0.1:9000`
- `docker/supervisord.conf` — runs `php-fpm` and `nginx` in the container
- `docker-compose.yml` — `web` service; image `${IMAGE_NAME:-mdd-php-stub:latest}`, host port `${APP_PORT:-8080}`
- `.github/workflows/deploy.yml` — copy source over SSH → build on server → prune
- `README.md` — usage, secrets, caveats

## Conventions

- Keep files minimal; no frameworks or build step.
- No registry: the server builds the copied source locally and runs `${IMAGE_NAME}` from the compose file.
- Deploy runs `docker compose up -d --build --remove-orphans`, then `docker image prune -af` (build cache is kept).
- `docker image prune -af` deletes all images unused by running containers — never widen its scope.

## Checks

```sh
docker compose config
php -l index.php
docker compose up --build   # then: curl localhost:8080
```

YAML must parse: `ruby -ryaml -e 'YAML.load_file(".github/workflows/deploy.yml")'`

## Do not

- Commit secrets; server access lives in GitHub secrets (`SSH_HOST`, `SSH_USER`, `SSH_KEY`, `SSH_PORT`, `DEPLOY_PATH`).
- Change the deployment path or port default without updating `README.md`.
