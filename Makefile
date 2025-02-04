serve:
	make -j 2 server client
client:
	cd client && pnpm run dev
server:
	cd server && gleam run

build:
	make -j 2 build-server build-client
build-client:
	cd client && pnpm run build
build-server:
	cd server && gleam build

.PHONY: serve client server
