FROM python:bullseye AS builder
WORKDIR /app

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
    libmbedtls-dev

RUN pip install numpy wheel
RUN pip install ledfx

VOLUME [ "/config" ]

ENTRYPOINT ["ledfx", "-v", "-c", "/config"]