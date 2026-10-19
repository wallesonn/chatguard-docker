# syntax=docker/dockerfile:1

# ---------- Dependências ----------
FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

# ---------- Build do Next.js (export estático em /app/out) ----------
# O vídeo em public/videos/ entra pelo contexto de build e é copiado para
# out/ pelo next build — não precisa de nada especial aqui.
FROM node:22-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

# ---------- Runtime: serve o export estático ----------
# A aplicação atual é uma página estática (output: 'export'), então o
# runtime é o nginx servindo out/. Quando o backend (cadastro/API) entrar,
# trocar este estágio por `next start` e adicionar as rotas dinâmicas.
FROM nginx:1.27-alpine AS runner
COPY --from=builder /app/out /usr/share/nginx/html
COPY chatguard-docker/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80