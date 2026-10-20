# ChatGuard — Stack Docker

Stack da aplicação ChatGuard em Docker: **PostgreSQL** local + integração com o
**Traefik** já existente na VPS, atendendo **chatguard.life** (mesma
infraestrutura das outras stacks da VPS, como o inlaudo).

**Status:** em produção desde 2026-10-19 — `https://chatguard.life` respondendo
com certificado Let's Encrypt válido. Imagem atual:
`wallesonnn/chatguard-app` (tags `v0.1.1` e `latest`).

## Estrutura

```text
chatguard-docker/
├── Dockerfile          # build do Next.js + nginx servindo o export estático
├── docker-compose.yml  # serviços app e db (Postgres) + labels do Traefik
├── nginx.conf          # servidor estático (gzip, cache, vídeo)
├── .env.example        # configuração local (referência; o real não sobe)
└── README.md           # este arquivo
```

> No GitHub, este repositório versiona **apenas** `README.md` e
> `docker-compose.yml`. Os demais arquivos são locais (necessários ao build)
> e ficam fora do versionamento, ignorados pelo `.gitignore` da pasta.

Na raiz do repositório do app há ainda o **`.dockerignore`** (mantém o
contexto de build enxuto **sem excluir `public/videos/`**) e o **`build.sh`**,
que constrói e publica a imagem no Docker Hub.

## Pré-requisitos

- VPS com Docker e Docker Compose.
- Traefik já rodando na VPS com:
  - rede externa **`web`** (hardcoded no compose, como no inlaudo);
  - entrypoint HTTPS **`websecure`**;
  - resolutor de certificados **`lets-encrypt`**.
- DNS: `chatguard.life` apontando para o IP da VPS.
- Para incluir o vídeo: coloque o arquivo em `public/videos/` **antes** do
  build (o vídeo entra na imagem, não sobe para lugar nenhum).

> A regra do Traefik já cobre `chatguard.life` **e** `www.chatguard.life`
> (o DNS do `www` aponta para a VPS; o certificado é emitido com SAN para os
> dois hosts).

## Deploy no Portainer

**Opção 1 — Web editor (colar):**

1. **Stacks → Add stack** — nome da stack: `chatguard`.
2. **Build method: Web editor** — cole o conteúdo de `docker-compose.yml`.

**Opção 2 — Repository (este repo no GitHub):**

1. **Stacks → Add stack** — nome da stack: `chatguard`.
2. **Build method: Repository** — aponte para
   `https://github.com/wallesonn/chatguard-docker`, branch `main`, compose
   path `docker-compose.yml`.

**Em ambos os casos:**

3. Em **Environment variables**, defina no mínimo:
   - `POSTGRES_PASSWORD` — senha forte (troque a padrão);
   - `DOCKER_IMAGE` — opcional, para travar versão
     (ex.: `wallesonnn/chatguard-app:v0.1.1`; padrão: `latest`).
4. **Deploy the stack**. Depois de alguns segundos, `https://chatguard.life`
   deve responder; o certificado é emitido pelo Traefik.

> O compose não tem bloco `build:` de propósito: a imagem é sempre puxada
> pronta do Docker Hub (publicada via `./build.sh`). Um bloco `build:` falha
> no Portainer, porque o repo não contém o código-fonte do app. Para
> atualizar a produção depois de mudanças no repo, use **Update the stack**.

## Alternativa: CLI na VPS

```bash
cd chatguard-docker
cp .env.example .env      # troque POSTGRES_PASSWORD
docker compose pull
docker compose up -d
docker compose ps
```

## Build e atualização da imagem

```bash
# na sua máquina (o vídeo de public/videos/ entra na imagem)
./build.sh vX.Y.Z
```

Depois, no Portainer: **Pull and redeploy** na stack (seguindo `latest`) ou
troque `DOCKER_IMAGE` para a versão exata e faça **Update the stack**.

## Banco de dados (Postgres)

- Banco criado automaticamente na primeira subida com as variáveis
  (`POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`).
- Dados persistidos no volume `pgdata` (sobrevive a `down`/`up`; apague apenas
  de propósito, com `docker compose down -v`).
- **Sem porta publicada no host** — o bloco `ports:` do `db` está desabilitado
  no compose porque a VPS já tem outro Postgres ocupando a 5432. O banco fica
  acessível apenas pela rede interna da stack (host `db`, porta 5432), que é
  o que o backend futuro usa via `DATABASE_URL`.
- Se um dia precisar de acesso pelo host (ferramentas locais), reabilite o
  bloco `ports` comentado usando uma porta livre, ex.: `POSTGRES_PORT=5433`.

> A landing page atual é um **export estático** e ainda não usa o banco: o
> Postgres fica provisionado para quando o backend (cadastro, dashboard,
> listas) entrar. Quando isso acontecer, o Dockerfile troca o estágio final
> por um runtime Node (`next start`) e as rotas de API passam a usar
> `DATABASE_URL`.

## Segurança

- Troque `POSTGRES_PASSWORD` antes do primeiro deploy.
- O `.env` real nunca é versionado; o `.dockerignore` impede que segredos
  entrem no contexto de build.
- O Postgres não publica porta no host — só é alcançável pela rede interna
  da stack.

## Lições do primeiro deploy (2026-10-19)

Problemas encontrados e resolvidos — úteis para os próximos deploys/domínios:

- **Bloco `build:` no compose quebra o Portainer** — ao fazer deploy pelo
  método *Repository*, o Portainer clona só este repo (sem o código-fonte do
  app) e falha em `lstat .../chatguard-docker`. Por isso o compose não tem
  `build:`: a imagem é sempre puxada pronta do Docker Hub.
- **DNS precisa propagar ANTES do deploy** — o Let's Encrypt falhou com
  `no valid A records found` porque o DNS de `chatguard.life` era novo. Após
  5 validações falhas, o LE aplicou rate limit de 1h
  (`too many failed authorizations`). O Traefik retenta sozinho e o
  certificado saiu quando o limite expirou — mas evite o ciclo: confirme
  `dig +short dominio` retornando o IP da VPS antes de subir a stack.
- **Porta 5432 do host ocupada** — outro Postgres da VPS já a usa; o
  mapeamento de porta do `db` ficou desabilitado (ver seção Banco de dados).
- **`traefik.enable=false` no `db`** — o Traefik da VPS usa
  `exposedByDefault`, então tentava rotear o Postgres e logava
  `unable to find the IP address` a cada scan. A label desliga isso; aplique
  em qualquer serviço não-público que entrar na stack.