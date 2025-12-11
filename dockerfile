# syntax=docker/dockerfile:1

# Etapa 1: instalar dependencias
FROM node:20-alpine AS deps

WORKDIR /usr/src/app
ENV NODE_ENV=production

# Copiamos solo los archivos de dependencias
COPY package*.json ./

# Instalamos dependencias de producción
RUN npm ci --omit=dev || npm install --omit=dev

# Etapa 2: imagen final (runtime)
FROM node:20-alpine AS runner

WORKDIR /usr/src/app
ENV NODE_ENV=production

# Copiamos node_modules ya instalados
COPY --from=deps /usr/src/app/node_modules ./node_modules

# Copiamos el resto del código de la app
COPY . .

# Puerto en el que corre la app
EXPOSE 8000

# Comando de arranque
CMD ["npm", "start"]