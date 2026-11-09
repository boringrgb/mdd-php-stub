# mdd-php-stub

Minimal PHP page served by nginx with PHP-FPM, built and deployed by GitHub Actions.

## Run locally

```sh
docker compose up --build
curl http://localhost:8080
```

## Deploy

Push to `main` (or run the workflow manually):

1. Build image, push `ghcr.io/<owner>/<repo>:{latest,<sha>}`.
2. Copy `docker-compose.yml` to the server, `docker compose pull` + `up -d`.
3. `docker image prune -af`.

### Secrets

| Secret | Value |
| --- | --- |
| `SSH_HOST` | Server hostname or IP |
| `SSH_USER` | SSH user with Docker access |
| `SSH_KEY` | Private key |
| `SSH_PORT` | Optional, default `22` |
| `DEPLOY_PATH` | Absolute target directory on server |

Variable: `APP_PORT` (host port, default `8080`).

## Caveats

- GHCR image is private; the deploy logs in with `GITHUB_TOKEN`. Make the package public or use a long-lived token if that fails.
- `docker image prune -af` removes all images unused by running containers on that daemon.
