FROM alpine:edge
RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing \
    erlang gleam rebar3 yarn
COPY . /app
WORKDIR /app/client
RUN yarn install && yarn build
WORKDIR /app/server
ENTRYPOINT ["gleam"]
CMD ["run"]
EXPOSE 8000