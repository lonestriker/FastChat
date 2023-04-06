#!/usr/bin/env bash
#
# Run controller, worker and gradio web server
#
# Must set env variables:
#   MODEL_PATH : Path to model starting from the models/ directory itself, or a HuggingFace username/model_name
#   MODEL_NAME : Name of the model (only used in Gradio web page to reference the MODEL_PATH)
#
# Optional:
#   SHARE      : set to any non-empty value to share Gradio connection
#

set -e

# To enable a default model to download or run
#MODEL_PATH=${MODEL_PATH:-anon8231489123/vicuna-13b-GPTQ-4bit-128g}
#MODEL_NAME=${MODEL_NAME:-vicuna-gptq}

if [ -z "${MODEL_PATH:-}" ] || [ -z "${MODEL_NAME}" ]; then
    echo "ERROR: Must set MODEL_PATH and MODEL_NAME env variables"
    exit 1
fi

if [ -n "${SHARE:-}" ]; then
    SHARE="--share"
fi

function cleanup {
    echo "Killing controller"
    kill -9 $PID_C
    echo "Killing worker"
    kill -9 $PID_W
    echo "Killing gradio"
    kill -9 $PID_G
}
trap cleanup EXIT SIGINT

python3 -m fastchat.serve.controller --host "127.0.0.1" &
PID_C=$!
sleep 5
python3 -m fastchat.serve.model_worker --model-path $MODEL_PATH --model-name $MODEL_NAME --wbits 4 --groupsize 128 --host "127.0.0.1" --worker-address "http://127.0.0.1:21002" --controller-address "http://127.0.0.1:21001" &
PID_W=$!
sleep 10
python3 -m fastchat.serve.gradio_web_server --controller-url "http://127.0.0.1:21001" --host 0.0.0.0 ${SHARE:-} &
PID_G=$!
wait $PID_G
