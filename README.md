# ChatGuard — Deploy Docker

Stack de **implantação** da landing page do ChatGuard em produção (VPS):
aplicação + Postgres atrás do Traefik, atendendo **chatguard.life**.

> Este repositório **não constrói** nada. A imagem `wallesonnn/chatguard-app`
> é construída e publicada no Docker Hub a partir do repositório do app, via
> `./build.sh <versão>`. Aqui ela apenas é puxada e executada.

## Serviços

| Serviço | Imagem | Função |
|---|---|---|
| `app` | `wallesonnn/chatguard-app` (Docker Hub) | Landing estática servida por nginx |
| `db` | `postgres:17-alpine` | Banco local, volume persistente `pgdata` |

## Passos na VPS

```bash
git clone https://github.com/wallesonn/chatguard-docker.git
cd chatguard-docker
cp .env.example .env    # troque POSTGRES_PASSWORD e confira o restante
docker compose pull
docker compose up -d
```

Depois de alguns segundos, `https://chatguard.life` deve responder. O Traefik
gera o certificado automaticamente (resolutor configurado no `.env`).

### Verificações úteis

```bash
docker compose ps        # status dos serviços
docker compose logs -f app
docker compose logs -f db
docker compose config    # valida a configuração interpolada
```

## Atualizar a versão em produção

1. No repositório do app: `./build.sh vX.Y.Z` (build + push no Docker Hub).
2. Nesta VPS, uma das opções:
   - **Seguindo o `latest`**: `docker compose pull && docker compose up -d`
   - **Versão travada**: defina `APP_IMAGE=wallesonnn/chatguard-app:vX.Y.Z`
     no `.env` e rode `docker compose up -d`.

## Requisitos

- VPS com Docker e Docker Compose.
- Traefik já rodando com: rede dos serviços (padrão `traefik-public`),
  entrypoint HTTPS (padrão `websecure`) e resolutor Let's Encrypt (padrão `le`).
- DNS: `chatguard.life` apontando para o IP da VPS.
- Porta do Postgres exposta apenas em `127.0.0.1` (remova o bloco `ports` do
  serviço `db` se não precisar acessá-la pelo host).

## Segurança

- Troque `POSTGRES_PASSWORD` antes do primeiro deploy.
- O `.env` real é ignorado pelo `.gitignore` — nunca é versionado.