.PHONY: fetch-src create-go-mod clean-src build-image run-docker stop-docker run

fetch-src: clean-src
	@echo "Fetching app sources\n"
	mkdir src
	curl -H 'Accept: application/vnd.github.v3.raw' -O --output-dir "src/" -L https://api.github.com/repos/c2h5oh/testapp/contents/main.go

create-go-mod:
	@echo "Creating go.mod file for the app sources\n"
	-cd ./src && go mod init github.com/c2h5oh/testapp

clean-src:
	@echo "Performing app sources cleanup\n"
	rm -rf ./src

build-image:
	@echo "Building docker image from the app sources\n"
	docker build . -t horizon-demo:1.0

clean-image:
	@echo "Performing docker image cleanup\n"
	docker rmi horizon-demo:1.0

run-docker: stop-docker
	@echo "Running the app container with docker image\n"
	docker run --rm --name horizon-demo -p 8080:80 -e HORIZON_SALT=${HORIZON_SALT} -d horizon-demo:1.0

stop-docker:
	@echo "Stopping the app in docker container\n"
	-docker kill horizon-demo

clean: stop-docker clean-image clean-src

run: fetch-src create-go-mod build-image run-docker
