version=0.1

build:
	docker image build -t druntime:${version} --build-arg VERSION=${version} .

run: build
	docker run -it --name druntime druntime:${version} /bin/bash

start_container: 
	docker start -a -i `docker ps -l | grep druntime | awk '{print $$1}'`

bash:
	docker exec -it druntime /bin/bash

clean:
	docker rm -f druntime
	docker image rm druntime:${version}
