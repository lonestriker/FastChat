#!/usr/bin/env bash
#
# Run Docker image to run the controller, worker and gradio web server
#

set -e

usage() {
    cat<<EOF

Description:
    Run Docker image to run the controller, worker and gradio web server

Usage:
    $0

Required env variables:
    IMAGE_NAME : Docker image name
    MODEL_PATH : Path to model starting from the models/ directory itself, or a HuggingFace username/model_name
    MODEL_NAME : Name of the model (only used in Gradio web page to reference the MODEL_PATH)

Optional env variables:
    MODELS_MOUNT : models diretory to mount (if model is not in the image)
    SHARE        : set to any non-empty value to share Gradio connection

Example:
  export MODEL_PATH=vicuna-13b-GPTQ-4bit-128g
  export MODEL_NAME=vicuna-gptq
  export IMAGE_NAME=vicuna-fastchat-small
  export MODELS_MOUNT=$HOME/models
  $0

EOF
    exit 1
}


if [ -z "${MODEL_PATH:-}" ] || [ -z "${MODEL_NAME}" ]; then
    echo "ERROR: Must set MODEL_PATH and MODEL_NAME env variables"
    usage
fi

if [ -n "${MODELS_MOUNT}" ]; then
    MODELS_MOUNT="-v $MODELS_MOUNT:/FastChat/models"
fi

if [ -n "${SHARE:-}" ]; then
    SHARE="-e SHARE=$SHARE"
fi

sudo docker run -it --rm --gpus all ${MODELS_MOUNT:-} -p 7860:7860 -e MODEL_PATH=$MODEL_PATH -e MODEL_NAME=$MODEL_NAME $SHARE $IMAGE_NAME "$@"

