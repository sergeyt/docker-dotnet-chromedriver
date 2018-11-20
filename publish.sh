export DOCKER_ID_USER="sergeyt"
IMAGE=dotnet-node-chromedriver

docker tag $IMAGE $DOCKER_ID_USER/$IMAGE
docker push $DOCKER_ID_USER/$IMAGE
