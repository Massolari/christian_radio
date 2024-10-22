serve:
	make -j 2 server client
client:
	cd client && yarn dev
server:
	cd server && gleam run

build:
	make -j 2 build-server build-client
build-client:
	cd client && yarn build
build-server:
	cd server && gleam build

.PHONY: serve client server
