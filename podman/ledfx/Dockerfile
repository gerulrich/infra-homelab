FROM python:3.12-bullseye AS builder
WORKDIR /app
ARG LEDFX_VERSION
RUN apt-get update && \
 apt-get install -y \
    pulseaudio gcc \
    cmake \
    make \
    libatlas3-base \
    libavformat58 \
    portaudio19-dev \
    avahi-daemon alsa-utils \
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

FROM python:3.12-slim AS final
WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        pulseaudio \
        libatlas3-base \
        portaudio19-dev \
        libaubio5 \
        libmbedtls14 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local /usr/local
COPY startup.sh .
VOLUME [ "/config" ]

RUN adduser root pulse-access

EXPOSE 4713

ENTRYPOINT ["/bin/sh", "/app/startup.sh"]