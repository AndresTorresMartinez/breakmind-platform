FROM node:20-alpine AS builder

WORKDIR /app

COPY pnpm-lock.yaml .
COPY pnpm-workspace.yaml .
COPY package.json .
COPY tsconfig.json .
COPY apps/landing/package.json ./apps/landing/
COPY apps/landing/tsconfig.json ./apps/landing/

RUN npm install -g pnpm && pnpm install --frozen-lockfile

COPY apps/landing ./apps/landing

WORKDIR /app/apps/landing

RUN pnpm build

FROM node:20-alpine

WORKDIR /app

COPY --from=builder /app/pnpm-lock.yaml .
COPY --from=builder /app/pnpm-workspace.yaml .
COPY --from=builder /app/package.json .
COPY --from=builder /app/tsconfig.json .
COPY --from=builder /app/apps/landing/package.json ./apps/landing/

RUN npm install -g pnpm && pnpm install --frozen-lockfile --prod

COPY --from=builder /app/apps/landing/.next ./apps/landing/.next
COPY --from=builder /app/apps/landing/public ./apps/landing/public

WORKDIR /app/apps/landing

EXPOSE 3000

CMD ["pnpm", "start"]
