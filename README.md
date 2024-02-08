# horizon-demo

Demo of dockerizing a simple [Golang](https://go.dev) app for Horizon

## The puzzle

This repository is a small and relatively simple demo for the given task:

> Write a dockerfile that builds [an app you can find here](https://github.com/c2h5oh/testapp) and creates an image allowing you to run it. This
> golang app has no CGO dependencies and will be statically linked when built.
>
> Make the resulting image as secure as possible by minimizing its attack surface and utilizing Docker security features. Consider both the app requiring to be run as a privileged and regular user.
>
> Provide docker run command(s) to securely run the container using the image you’ve created and make it available from the host it’s running on.

## Solution approach

After analysing the given application and the task at hand it seems it is relatively simple: the application doesn't have external dependencies, doesn't require storage for data nor any database, doesn't require additional sidecar containers.

The only tricky part here is the `-salt` parameter required for the application, specifically when thinking about the technology in question ([Docker](https://www.docker.com) itself, not any other orchestrator like [Kubernetes](https://kubernetes.io), etc.) and security, given that secrets aren't very well implemented in Docker alone.

This leaves us with three possible solutions, all with their own pros and cons:

- [Docker Swarm](https://docs.docker.com/engine/swarm/)

  - pros:
    - [secrets management](https://docs.docker.com/engine/swarm/secrets/) available
    - potentially production ready solution
  - cons:
    - relatively new solution
    - most complex of the three
    - not recommended for local development

- [Docker Compose](https://docs.docker.com/compose/)

  - pros:
    - capable enough [secrets management](https://docs.docker.com/compose/use-secrets/) available
    - relatively simple for local development
  - cons:
    - external dependencies required (docker-compose)
    - not production ready solution

- [Plain Docker](https://docs.docker.com/engine/reference/builder/)
  - pros:
    - simplest solution of the three
    - suitable for local development
    - no external dependencies
  - cons:
    - no real secrets management available
    - not production ready solution

Given this is a just a demo that isn't ever intended for shared develpment nor production deployment, the plain [Docker](https://www.docker.com) solution was chosen for its ultimate simplicity and easy setup, with caveat that **this particular approach to passing the secret value to the `-salt` parameter should never be done like that in production, as it is prone to being exposed in shell history, etc**.

## How to use it

1. Clone this Git repository to your machine

```sh
$ git clone https://github.com/bartekrutkowski/horizon-demo.git
Cloning into 'horizon-demo'...
remote: Enumerating objects: 4, done.
remote: Counting objects: 100% (4/4), done.
remote: Compressing objects: 100% (4/4), done.
remote: Total 4 (delta 0), reused 0 (delta 0), pack-reused 0
Receiving objects: 100% (4/4), done.
$
```

2. Set the `HORIZON_SALT` enviromental variable with chosen salt value (normally, this would be a secret and should be exposed to the application via relevant secrets management)

```sh
$ export HORIZON_SALT=very-secret-value
$
```

3. Enter the directory and use `make` to fetch the sources, build the image and run the application, all in one step (or run subsequent commands, see `Makefile` for available targets):

```sh
$ cd horizon-demo
$ make run
Performing app sources cleanup

rm -rf ./src
Fetching app sources

mkdir src
curl -H 'Accept: application/vnd.github.v3.raw' -O --output-dir "src/" -L https://api.github.com/repos/c2h5oh/testapp/contents/main.go
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   725  100   725    0     0   2269      0 --:--:-- --:--:-- --:--:--  2272
Creating go.mod file for the app sources

cd ./src && go mod init github.com/c2h5oh/testapp
go: creating new go.mod: module github.com/c2h5oh/testapp
go: to add module requirements and sums:
    go mod tidy
Building docker image from the app sources

docker build . -t horizon-demo:1.0
[+] Building 0.6s (14/14) FINISHED                                                                                                                                  docker:orbstack
 => [internal] load build definition from dockerfile                                                                                                                           0.0s
 => => transferring dockerfile: 448B                                                                                                                                           0.0s
 => [internal] load metadata for docker.io/library/alpine:3.19.1                                                                                                               0.6s
 => [internal] load metadata for docker.io/library/golang:1.22.0                                                                                                               0.6s
 => [internal] load .dockerignore                                                                                                                                              0.0s
 => => transferring context: 2B                                                                                                                                                0.0s
 => [builder 1/6] FROM docker.io/library/golang:1.22.0@sha256:ef61a20960397f4d44b0e729298bf02327ca94f1519239ddc6d91689615b1367                                                 0.0s
 => [stage-1 1/2] FROM docker.io/library/alpine:3.19.1@sha256:c5b1261d6d3e43071626931fc004f70149baeba2c8ec672bd4f27761f8e1ad6b                                                 0.0s
 => [internal] load build context                                                                                                                                              0.0s
 => => transferring context: 875B                                                                                                                                              0.0s
 => CACHED [builder 2/6] WORKDIR /src                                                                                                                                          0.0s
 => CACHED [builder 3/6] COPY src/go.mod ./                                                                                                                                    0.0s
 => CACHED [builder 4/6] RUN go mod download                                                                                                                                   0.0s
 => CACHED [builder 5/6] COPY src .                                                                                                                                            0.0s
 => CACHED [builder 6/6] RUN CGO_ENABLED=0 GOOS=linux go build -o /app -a -ldflags '-extldflags "-static"' .                                                                   0.0s
 => CACHED [stage-1 2/2] COPY --from=builder /app /app                                                                                                                         0.0s
 => exporting to image                                                                                                                                                         0.0s
 => => exporting layers                                                                                                                                                        0.0s
 => => writing image sha256:9241e8a82350b0f60566288c020276223c3a6031eb5628b844656dc5594c493f                                                                                   0.0s
 => => naming to docker.io/library/horizon-demo:1.0                                                                                                                            0.0s
Stopping the app in docker container

docker kill horizon-demo
horizon-demo
Running the app container with docker image

docker run --rm --name horizon-demo -p 8080:80 -e HORIZON_SALT=very-secret-value -d horizon-demo:1.0
03fb42387e3fd4df21345bca43556e86a34bb9f574b6a420d9739f14f9ddb34c
$
```

3. Verify that the container is running properly

```sh
$ docker ps
CONTAINER ID   IMAGE              COMMAND                  CREATED         STATUS         PORTS                                   NAMES
03fb42387e3f   horizon-demo:1.0   "/bin/sh -c '/app -s…"   3 minutes ago   Up 3 minutes   0.0.0.0:8080->80/tcp, :::8080->80/tcp   horizon-demo
$
```

4. Test the application running in the container (subsequent container runs with the same value of `HORIZON_SALT` env variable should yeld the same return value)

```sh
$ curl localhost:8080
46439E9B76DD3708AE978C0588152FCB5F14DB4C137D5B581EF42C61323D7C19
$
```

5. Clean up your environment after the demo

```sh
$ make clean
Stopping the app in docker container

docker kill horizon-demo
horizon-demo
Performing docker image cleanup

docker rmi horizon-demo:1.0
Untagged: horizon-demo:1.0
Deleted: sha256:9241e8a82350b0f60566288c020276223c3a6031eb5628b844656dc5594c493f
Performing app sources cleanup

rm -rf ./src
$ unset HORIZON_SALT
$
```

## Image security

The image is built with the following best practices to provide smallest, as secure as possible Docker container image:

- multi-stage build - using the Go builder image to build the binary and Alpine image to build the smallest image possible, avoiding shipping any unnecessary libraries or binaries, reducing the vulnerability surface
- tagged images - using specific version tags (could be further expanded to speficic hashtags) to ensure immutable build images are used and immutable image is built (could be further expanded to notarizing/signing the resulting image)
- unprivileged user - using `nobody` instead of default `root` user inside the container to run the Go binary (not a big impact in our case, but very important when shipping bigger containers with more binaries, libraries, etc.)
- high TCP port - using `8080/TCP` to pass traffic to internal `80/TCP` port (that's hardcoded in the app, could be improved) should allow running the container in Docker's 'rootless mode' for reduced attack surface in case of the application/image vulnerability

## Requirements

- Unix/Linux system or subsystem (Mac OS, \*BSD, Linux or Windows WSL2)
- [Git](https://git-scm.com)
- [Docker](https://www.docker.com)
- [make](https://www.gnu.org/software/make/)

## License

While I retain [the author's](https://github.com/bartekrutkowski) rights for the repository, the entire repository and all its artifacts are relased under the [BSD 3-Clause license](https://github.com/bartekrutkowski/mini-kube-demo/blob/main/LICENSE) and are free to use.

The task and the application provided is provided by Horizon (et al.) and their author's rights and license should be checked at the source and respected separately to this repository.
