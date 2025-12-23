FROM node:18-alpine

# add curl for healthcheck
RUN apk add --no-cache curl tini

WORKDIR /usr/local/app

# have nodemon available for local dev use (file watching)
RUN npm install -g nodemon

COPY package*.json ./

RUN npm ci && \
 npm cache clean --force && \
 mv /usr/local/app/node_modules /node_modules

COPY . .

ENV PORT=80
EXPOSE 80

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "server.js"]
