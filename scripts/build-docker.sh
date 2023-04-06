#!/usr/bin/env bash
#
# Build Docker image to run FastChat and optionally copy a model into the image
#

usage() {
    cat<<EOF

Description:
    Build Docker image to run FastChat and optionally copy a model into the image

Usage:
    $0 <image> [model-directory]

Args:
    image-name      : (required) Name of the Docker image to create
    model-directory : (optional) Relative path to the individual model to include in the image (do not specify to skip model copy)

Examples:
    Create Docker image named 'vicuna-gptq' and no model (must mount the model when running the Docker image)
        $0 vicuna-gptq

    Create Docker image named 'vicuna-gptq' and copy the specified model from models/ directory
        $0 vicuna-gptq vicuna-13b-GPTQ-4bit-128g

EOF
    exit 1
}

set -e

IMAGE_NAME=${1:-}
MODEL_COPY=${2:-}

if [ -z "${IMAGE_NAME}" ]; then
    echo "ERROR: Must specify an image name as the first arg"
    usage
fi

# No Dockerfile in current directory, move one level up from "scripts" subdirectory if we're there
if [ ! -f Dockerfile ] && [ ${basename `pwd`} = "scripts" ]; then
    cd ..
fi

if [ ! -f Dockerfile ]; then
    echo "ERROR: Unable to find Dockerfile, please run from FastChat root directory"
    usage
fi

if [ -n "${MODEL_COPY}" ]; then
    BUILD_ARG="--build-arg MODEL_COPY=$MODEL_COPY"
fi

# Do not quote the BUILD_ARG variable below, it must rename unquoted
sudo DOCKER_BUILDKIT=1 docker build ${BUILD_ARG:-} -t $IMAGE_NAME .
