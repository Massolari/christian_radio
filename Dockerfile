FROM alpine:edge

# Usar o RENDER_GIT_COMMIT que é fornecido automaticamente pelo Render
ARG RENDER_GIT_COMMIT=dev

RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing \
    erlang gleam rebar3 yarn git

COPY . /app
WORKDIR /app/client

RUN yarn install && yarn build

ENV GIT_COMMIT_HASH=${RENDER_GIT_COMMIT}
WORKDIR /app/server
RUN gleam build
ENTRYPOINT ["gleam"]
CMD ["run"]
EXPOSE 8000