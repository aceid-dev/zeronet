# zeronet

Repositorio standalone para construir y publicar una imagen Docker de ZeroNetX.

## Ficheros

- `.env`
- `compose.yaml`
- `Dockerfile`
- `docker_entrypoint.sh`
- `constraints.txt`
- `.gitignore`
- `.github/workflows/publish.yml`

## Configuracion

Todo el proyecto toma sus variables de `.env`. Ahí se centralizan:

- imagen y plataformas
- versiones de Alpine, pip y setuptools
- `OCI_SOURCE`
- `ZERONET_REPO_URL`
- `ZERONET_REPO_REF`
- variables de runtime de ZeroNet para Compose
- red Docker fija para la UI

El upstream queda fijado ahora en `ZERONET_REPO_REF=6dc1ebd93ff488dd5d8fe42242fa435a199a7833`.

## Build local

La forma recomendada en local es Compose, porque ya reutiliza `.env` sin repetir todos los `--build-arg`.

```bash
docker compose build
```

Si usas `docker-compose` clasico:

```bash
docker-compose build
```

Si quieres seguir usando `docker build` directamente:

```bash
set -a
. ./.env
set +a

docker build \
  --build-arg ALPINE_VERSION \
  --build-arg PIP_VERSION \
  --build-arg SETUPTOOLS_VERSION \
  --build-arg OCI_SOURCE \
  --build-arg ZERONET_REPO_URL \
  --build-arg ZERONET_REPO_REF \
  -t "${IMAGE_NAME}:${IMAGE_TAG}" \
  .
```

## Ejecutar

```bash
docker compose up -d
```

Con `docker-compose` clasico:

```bash
docker-compose up -d
```

Con esta configuracion, la UI:

- escucha dentro de Docker en `http://zeronet:43110/`
- escucha dentro del contenedor en `http://10.0.6.10:43110/`
- se publica en la maquina host solo en `http://127.0.0.1:43110/` y `http://localhost:43110/`

Para parar y borrar el contenedor:

```bash
docker compose down
```

Para este aislamiento, `docker compose` es el flujo soportado. Con `docker run` directo tendrias que recrear manualmente la red, la IP fija y el bind de `127.0.0.1`.

## Publicacion

El publish se mantiene en GitHub Actions con [`.github/workflows/publish.yml`](/www/zeronet/.github/workflows/publish.yml#L1).

Eso se queda fuera de `docker compose` a proposito, porque el workflow ya resuelve:

- `buildx` multiarquitectura
- tags automáticos
- labels OCI
- push a GHCR

La imagen publicada sigue siendo portable: la IP fija y el cierre de la UI al host local solo se aplican en runtime desde `compose.yaml`.

## Nota

Antes de publicar, revisa `.env` si cambian el namespace de GHCR, `OCI_SOURCE`, las plataformas o el commit upstream de ZeroNet.
