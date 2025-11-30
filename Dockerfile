# ============ Development ============
FROM node:20-alpine AS dev
WORKDIR /app

RUN apk add --no-cache libc6-compat

# Corepack + pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Install all dependencies (including dev)
COPY package.json pnpm-lock.yaml ./
RUN pnpm install

# Copy source code
COPY . .

EXPOSE 3000
CMD ["pnpm", "dev"]

# ============ Production ============
# Install dependencies only when needed
FROM node:20-alpine AS deps
RUN apk add --no-cache libc6-compat

WORKDIR /app

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

COPY package.json pnpm-lock.yaml ./
RUN pnpm i --frozen-lockfile

# Build the app
FROM node:20-alpine AS builder
WORKDIR /app
RUN apk add --no-cache libc6-compat
RUN corepack enable && corepack prepare pnpm@latest --activate

COPY . .
COPY --from=deps /app/node_modules ./node_modules

RUN pnpm build

# Production image
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000

COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json /app/pnpm-lock.yaml ./

# Install only production dependencies
RUN corepack enable && corepack prepare pnpm@latest --activate
RUN pnpm install --prod --frozen-lockfile

EXPOSE 3000

CMD ["pnpm", "start"]
