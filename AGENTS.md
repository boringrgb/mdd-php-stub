# AGENTS.md

Static PHP site in Apache via Docker, deployed by GitHub Actions.

## Layout

- `index.php` — the page; serves as `index.php` in `/var/www/html`
- `Dockerfile` — `php:8.3-apache`; add PHP extensions here
- `docker-compose.yml` — `web` service; image `${IMAGE_NAME:-mdd-php-stub:latest}`, host port `${APP_PORT:-8080}`
- `.github/workflows/deploy.yml` — build → push to GHCR → SSH deploy → prune
- `README.md` — usage, secrets, caveats

## Conventions

- Keep files minimal; no frameworks or build step.
- Image tags are `latest` and the commit SHA; the server runs `${IMAGE_NAME}` from the compose file.
- Deploy runs `docker compose pull && up -d --no-build`, then `docker image prune -af`.
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
