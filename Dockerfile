# Images:
#   1,05 GB : nvidia/cuda:11.7.1-runtime-ubuntu22.04
#   2.36 GB : nvidia/cuda:11.7.1-devel-ubuntu22.04
#   3.44 GB : nvidia/cuda:11.7.1-cudnn8-devel-ubuntu22.04

FROM nvidia/cuda:11.7.1-cudnn8-devel-ubuntu22.04

RUN apt update && \
    apt install -y \
    git-lfs \
    python3 \
    python3-venv \
    python3-pip \
    screen

RUN python3 -m pip install -U pip setuptools wheel

RUN mkdir /FastChat

# Copy just the pyproject.toml file so we do not unnecessarily run the pip install for other changes
COPY pyproject.toml /FastChat
WORKDIR /FastChat

RUN pip install -e .

RUN \
    mkdir repositories && \
    cd repositories && \
    git clone https://github.com/oobabooga/GPTQ-for-LLaMa.git -b cuda

RUN \
    cd repositories/GPTQ-for-LLaMa && \
    env TORCH_CUDA_ARCH_LIST="8.6+PTX" python3 setup_cuda.py install

# Hack to copy model into image or not, models copied from models directory only
ARG MODEL_COPY=.insert_your_models_here
RUN mkdir /FastChat/models
COPY models/${MODEL_COPY} models/${MODEL_COPY}/

# Copy the rest of the files skipping models (TODO: add new directories if created, too lazy to generate Dockerfile)
COPY Dockerfile download-model.py LICENSE pyproject.toml README.md /FastChat/
COPY assets/ /FastChat/assets/
COPY docs/ /FastChat/docs/
COPY fastchat/ /FastChat/fastchat/
COPY playground/ /FastChat/playground/
COPY scripts/ /FastChat/scripts/
RUN rm -rf *.log /root/.cache/pip

COPY scripts/run-fastchat.sh /usr/local/bin/

CMD [ "/FastChat/scripts/run-fastchat.sh" ]

# To build:
#   Manual:
#     sudo env DOCKER_BUILDKIT=1 docker build -t vicuna-fastchat-small .
#   Script:
#     ./scripts/build-docker.sh vicuna-fastchat-small <image-name> </path/to/model/dir/to/copy>
#
# To run service, must mount target model with -v option (specify a command like 'bash' at the end of the command to debug):
#   export MODEL_PATH=vicuna-13b-GPTQ-4bit-128g
#   export MODEL_NAME=vicuna-gptq
#   export IMAGE_NAME=vicuna-fastchat-small
#   export MODELS_MOUNT=$HOME/models
#   
#   Manual:
#     sudo docker run -it --rm --gpus all -v $MODELS_MOUNT:/FastChat/models -p 7860:7860 -e MODEL_PATH=$MODEL_PATH -e MODEL_NAME=$MODEL_NAME $IMAGE_NAME
#   Script:
#     ./scripts/run-docker
