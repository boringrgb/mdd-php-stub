# mdd-php-stub

Minimal PHP page served by nginx with PHP-FPM, built and deployed by GitHub Actions.

## Run locally

```sh
docker compose up --build
curl http://localhost:8080
```

## Deploy

Push to `main` (or run the workflow manually):

1. Copy the checked-out commit to the server over SSH (`tar`, `.git` excluded).
2. Build the image on the server, `docker compose up -d --build`.
3. `docker image prune -af`.

No registry is involved: the image is built and kept on the server only, and nothing is pushed anywhere.

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

- The server needs Docker with the Compose plugin and outbound access to Docker Hub for the `php:8.3-fpm` base image.
- The build happens on the server, so the first deploy is slower; later deploys reuse the server's build cache. Only the previous image is pruned, not the cache.
- Files are copied over the top of `DEPLOY_PATH`; files deleted from the repo are not removed from the server. Delete them by hand if that matters.
- `docker image prune -af` removes all images unused by running containers on that daemon.
