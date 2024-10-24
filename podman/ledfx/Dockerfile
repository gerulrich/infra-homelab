FROM python:3.12-bullseye AS builder
WORKDIR /app
ARG LEDFX_VERSION
RUN apt-get update && \
 apt-get install -y \
    gcc \
    cmake \
    make \
    libatlas3-base \
    libavformat58 \
    portaudio19-dev \
    alsa-utils \
    libavcodec-dev \
    libavresample-dev \
    libavformat-dev \
    libaubio-dev \
    libmbedtls-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN pip install numpy wheel
RUN echo "Installing LedFx version ${LEDFX_VERSION}" && \
    pip install ledfx=="${LEDFX_VERSION}"

VOLUME [ "/config" ]

ENTRYPOINT ["ledfx", "-v", "-c", "/config"]