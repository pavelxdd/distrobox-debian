# distrobox-debian

## build image

````bash
docker compose build --pull distrobox-debian
````

or

````bash
podman-compose build --pull distrobox-debian
````

## run in distrobox

````bash
distrobox create -n debian -i docker.io/pavelxdd/distrobox-debian:sid
distrobox enter debian
````
