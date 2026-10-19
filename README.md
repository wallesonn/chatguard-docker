# ChatGuard — Stack Docker

Stack completa para rodar a aplicação ChatGuard em Docker, com **PostgreSQL**
como banco de dados local e integração com o **Traefik** já existente na VPS,
atendendo o domínio **chatguard.life**.

## Estrutura

```text
chatguard-docker/
├── Dockerfile          # build do Next.js + nginx servindo o export estático
├── docker-compose.yml  # serviços app e db (Postgres) + labels do Traefik
├── nginx.conf          # servidor estático (gzip, cache, vídeo)
├── .env.example        # configuração (copie para .env)
└── README.md           # este arquivo
```

Na raiz do repositório também há um **`.dockerignore`** — ele mantém o contexto
de build enxuto **sem excluir `public/videos/`**, para que o vídeo local entre
na imagem — e o **`build.sh`**, que constrói e publica a imagem no Docker Hub.

## Pré-requisitos

- VPS com Docker e Docker Compose.
- Traefik já rodando na VPS, com:
  - uma rede Docker para os serviços (padrão aqui: `traefik-public`);
  - um entrypoint HTTPS (padrão aqui: `websecure`);
  - um resolutor de certificados Let's Encrypt (padrão aqui: `le`).
- DNS: `chatguard.life` apontando para o IP da VPS.
- Para incluir o vídeo: coloque o arquivo em `public/videos/` **antes** do build.

> Se o nome da rede, do entrypoint ou do resolutor do seu Traefik for
> diferente, ajuste no `.env` — tudo é parametrizado.

## Configuração

```bash
cd chatguard-docker
cp .env.example .env
# edite o .env: troque POSTGRES_PASSWORD e confira DOMAIN/TRAEFIK_NETWORK
```

## Subindo a stack

```bash
docker compose build   # build local (inclui o vídeo de public/videos/)
docker compose up -d   # sobe app + db
docker compose ps      # confere o status
```

Depois de alguns segundos, `https://chatguard.life` deve responder. O Traefik
gera o certificado automaticamente (resolutor configurado no `.env`).

### Verificações úteis

```bash
docker compose logs -f app    # logs da aplicação
docker compose logs -f db     # logs do Postgres
docker compose config         # valida a configuração interpolada
```

## Banco de dados (Postgres)

- Banco criado automaticamente na primeira subida com as variáveis do `.env`
  (`POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`).
- Dados persistidos no volume `pgdata` (sobrevive a `down`/`up`; apague apenas
  de propósito, com `docker compose down -v`).
- Acesso do host via `127.0.0.1:5432` (somente loopback).
- O backend da aplicação conversa com o banco pelo host `db` na rede interna.

> A landing page atual é um **export estático** e ainda não usa o banco: o
> Postgres fica provisionado nesta stack para quando o backend (cadastro,
> dashboard, listas) entrar. Quando isso acontecer, o Dockerfile deve trocar o
> estágio final por um runtime Node (`next start`) e as rotas de API passam a
> usar `DATABASE_URL`.

## Fluxo com registro de imagens (recomendado)

O script **`build.sh`** (na raiz do repositório) constrói a imagem e publica no
Docker Hub — recomendado quando o vídeo precisa ser incluído no build:

```bash
# na sua máquina (o vídeo em public/videos/ entra na imagem)
./build.sh v1.0.0

# na VPS
docker compose pull
docker compose up -d
```

## Segurança

- Troque `POSTGRES_PASSWORD` antes do primeiro deploy.
- O `.env` não é versionado (ignorado pelo `.gitignore`); o `.dockerignore`
  impede que segredos entrem no contexto de build.
- A porta do Postgres só é exposta no loopback (`127.0.0.1`); remova o bloco
  `ports` do serviço `db` se não precisar acessá-lo pelo host.