IMAGES=(
    node:21
    node:21-alpine
    node:21-slim
)

for image in "${IMAGES[@]}"; do
    docker pull $image
done

docker image ls
