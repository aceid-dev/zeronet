ARG PYTHON_VERSION=3.12
ARG PIP_VERSION=24.2
ARG SETUPTOOLS_VERSION=75.0.0

FROM python:${PYTHON_VERSION}-slim AS build

ARG ZERONET_REPO_URL=https://github.com/ZeroNetX/ZeroNet.git
ARG ZERONET_REPO_REF=6dc1ebd93ff488dd5d8fe42242fa435a199a7833
ARG PIP_VERSION
ARG SETUPTOOLS_VERSION

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    libffi-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

RUN git clone "${ZERONET_REPO_URL}" /zeronet \
    && git -C /zeronet checkout "${ZERONET_REPO_REF}" \
    && git -C /zeronet submodule update --init --recursive

WORKDIR /zeronet

COPY constraints.txt /tmp/constraints.txt

RUN python3 -m venv /zeronet/venv \
    && . /zeronet/venv/bin/activate \
    && python3 -m pip install --upgrade \
        "pip==${PIP_VERSION}" \
        "setuptools==${SETUPTOOLS_VERSION}" \
    && python3 -m pip install \
        --no-cache-dir \
        -c /tmp/constraints.txt \
        -r /zeronet/requirements.txt

FROM python:${PYTHON_VERSION}-slim

ARG OCI_SOURCE=https://github.com/aceid-dev/zeronet
ARG ENABLE_TOR=1
ARG ZERONET_CONFIG_FILE=/data/zeronet.conf
ARG ZERONET_DATA_DIR=/data
ARG ZERONET_FILESERVER_PORT=26552
ARG ZERONET_UI_HOSTS=
ARG ZERONET_UI_EXTRA_HOSTS=
ARG ZERONET_UI_IP=0.0.0.0
ARG ZERONET_UI_PORT=43110
ARG ZERONET_EXTRA_ARGS=

LABEL org.opencontainers.image.source="${OCI_SOURCE}"

COPY --from=build /zeronet /zeronet
COPY docker_entrypoint.sh /docker_entrypoint.sh

RUN apt-get update && apt-get install -y --no-install-recommends \
    tor \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && printf 'ControlPort 9051\nCookieAuthentication 1\n' >> /etc/tor/torrc \
    && chmod +x /docker_entrypoint.sh

ENV ENABLE_TOR=${ENABLE_TOR}
ENV HOME=/zeronet
ENV ZERONET_CONFIG_FILE=${ZERONET_CONFIG_FILE}
ENV ZERONET_DATA_DIR=${ZERONET_DATA_DIR}
ENV ZERONET_FILESERVER_PORT=${ZERONET_FILESERVER_PORT}
ENV ZERONET_UI_HOSTS=${ZERONET_UI_HOSTS}
ENV ZERONET_UI_EXTRA_HOSTS=${ZERONET_UI_EXTRA_HOSTS}
ENV ZERONET_UI_IP=${ZERONET_UI_IP}
ENV ZERONET_UI_PORT=${ZERONET_UI_PORT}
ENV ZERONET_EXTRA_ARGS=${ZERONET_EXTRA_ARGS}

VOLUME ["${ZERONET_DATA_DIR}"]

EXPOSE ${ZERONET_UI_PORT} ${ZERONET_FILESERVER_PORT}

WORKDIR /zeronet

CMD ["/docker_entrypoint.sh"]
