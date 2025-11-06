FROM asia-east1-docker.pkg.dev/appier-docker/dockerhub-remote-repository-asia-east1/python:3.11-slim-bookworm

COPY . /src

RUN apt-get update && apt-get install -y \
    # Runtime utilities
    libmagic-dev \
    make \
    # vim \
    git \
    wget \
    unzip \
    # Build tools for libvmaf (Netflix VMAF requirement)
    nasm \
    ninja-build \
    meson \
    doxygen \
    xxd \
    # Build tools for ffmpeg
    pkg-config \
    yasm \
    build-essential \
    # Video codec libraries (for encoding/decoding video formats)
    libx264-dev \
    libx265-dev \
    libvpx-dev \
    # Audio codec libraries (for encoding/decoding audio formats)
    libmp3lame-dev \
    libopus-dev \
    libvorbis-dev \
    && rm -rf /var/lib/apt/lists/*

# Stage 1: Build and install libvmaf (following Netflix VMAF pattern)
RUN git clone --depth 1 --branch v3.0.0 https://github.com/Netflix/vmaf.git /tmp/vmaf && \
    cd /tmp/vmaf/libvmaf && \
    meson setup build --buildtype release && \
    ninja -vC build && \
    ninja -vC build install && \
    ldconfig && \
    rm -rf /tmp/vmaf

# Stage 2: Build ffmpeg with libvmaf support (Netflix pattern, without NVIDIA GPU components)
# This is required because Debian's pre-built ffmpeg doesn't include --enable-libvmaf
ARG FFMPEG_TAG=n7.1
RUN wget https://github.com/FFmpeg/FFmpeg/archive/${FFMPEG_TAG}.zip && \
    unzip ${FFMPEG_TAG}.zip && \
    cd FFmpeg-${FFMPEG_TAG} && \
    ./configure \
    --enable-gpl \
    --enable-libvmaf \
    --enable-libx264 \
    --enable-libx265 \
    --enable-libvpx \
    --enable-libmp3lame \
    --enable-libopus \
    --enable-libvorbis \
    --disable-stripping && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    cd .. && \
    rm -rf FFmpeg-${FFMPEG_TAG} ${FFMPEG_TAG}.zip

WORKDIR /src

RUN chmod +x ./scripts/get_video_meta.sh
RUN chmod +x ./scripts/get_vmaf_score.sh

CMD ["tail", "-f", "/dev/null"]
