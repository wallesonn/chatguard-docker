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
| `db` | `postgres:17-alpine` | Banco local, volume persistente |

## Deploy no Portainer (fluxo manual)

1. **Stacks → Add stack** — nome da stack: `chatguard`.
2. Em **Build method**, escolha **Web editor** e cole o conteúdo de
   `docker-compose.yml`.
3. Em **Environment variables**, defina no mínimo:
   - `POSTGRES_PASSWORD` — senha forte (troque a padrão);
   - `TRAEFIK_NETWORK` — nome da rede Docker do seu Traefik
     (a mesma usada pelas suas outras stacks).
   Opciais:
   - `APP_IMAGE` — para travar uma versão, ex.: `wallesonnn/chatguard-app:v0.1.0`
     (o padrão é `latest`);
   - `DOMAIN`, `TRAEFIK_ENTRYPOINT`, `CERT_RESOLVER`, `POSTGRES_USER`,
     `POSTGRES_DB`, `POSTGRES_PORT` — todos têm padrões no compose.
4. **Deploy the stack**. Depois de alguns segundos, `https://chatguard.life`
   deve responder; o certificado é gerado pelo Traefik.

> O compose não tem `name:` no topo de propósito: no Portainer, o nome da
> stack define o nome do projeto (e dos recursos: volumes, rede default etc.).

## Alternativa: CLI na VPS

```bash
git clone https://github.com/wallesonn/chatguard-docker.git
cd chatguard-docker
cp .env.example .env    # troque POSTGRES_PASSWORD e confira o restante
docker compose pull
docker compose up -d
```

## Atualizar a versão em produção

1. No repositório do app: `./build.sh vX.Y.Z` (build + push no Docker Hub).
2. No Portainer:
   - **seguindo `latest`**: abra a stack → **Pull and redeploy**;
   - **versão travada**: mude `APP_IMAGE` para a nova versão nas variáveis da
     stack → **Update the stack**.

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