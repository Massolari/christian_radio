FROM alpine:edge

# Usar o RENDER_GIT_COMMIT que é fornecido automaticamente pelo Render
ARG RENDER_GIT_COMMIT=dev

RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing \
    erlang gleam rebar3 yarn git

COPY . /app
WORKDIR /app/client

# Passar o hash do commit como GIT_COMMIT_HASH para o Vite
ENV GIT_COMMIT_HASH=${RENDER_GIT_COMMIT}
RUN yarn install && yarn build

WORKDIR /app/server
RUN gleam build
ENTRYPOINT ["gleam"]
CMD ["run"]
EXPOSE 8000