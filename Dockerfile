FROM erlang:27-alpine

# Usar o RENDER_GIT_COMMIT que é fornecido automaticamente pelo Render
ARG RENDER_GIT_COMMIT=dev

RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing \
    gleam rebar3 pnpm git

COPY . /app
WORKDIR /app/client

RUN pnpm install && pnpm run build

ENV GIT_COMMIT_HASH=${RENDER_GIT_COMMIT}
WORKDIR /app/server
RUN gleam build
ENTRYPOINT ["gleam"]
CMD ["run"]
EXPOSE 8000