# distrobox-debian

## build docker image

````bash
echo "MAKEFLAGS=-j$(nproc --all)" > .env
docker compose build --pull distrobox-debian
````

## run in distrobox

````bash
distrobox create -n debian -i docker.io/pavelxdd/distrobox-debian:sid
distrobox enter debian
````
