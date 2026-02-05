# ==============================================================================
# Stage 1: Build hex2bin with older GCC (Debian 10)
# ==============================================================================
FROM debian:10-slim AS hex2bin-builder

RUN echo "deb http://archive.debian.org/debian buster main" > /etc/apt/sources.list \
    && echo "deb http://archive.debian.org/debian-security buster/updates main" >> /etc/apt/sources.list

RUN apt-get update && apt-get install -y \
    wget \
    bzip2 \
    gcc \
    make \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN wget -O /tmp/Hex2bin-2.5.tar.bz2 https://sourceforge.net/projects/hex2bin/files/latest/download \
    && tar -xjf /tmp/Hex2bin-2.5.tar.bz2 -C /tmp \
    && cd /tmp/Hex2bin-2.5 \
    && make \
    && mkdir -p /tmp/hex2bin-bin \
    && cp hex2bin /tmp/hex2bin-bin/

# ==============================================================================
# Stage 2: Build openMSX 21 using Ubuntu 22.04 + GCC 13
# ==============================================================================
FROM ubuntu:22.04 AS openmsx-builder

ENV DEBIAN_FRONTEND=noninteractive

# Install GCC 13 from toolchain PPA
RUN apt-get update && apt-get install -y software-properties-common \
    && add-apt-repository ppa:ubuntu-toolchain-r/test -y \
    && apt-get update && apt-get install -y \
    gcc-13 g++-13 git build-essential cmake pkg-config \
    libsdl2-dev libsdl2-ttf-dev libglew-dev libpng-dev zlib1g-dev \
    libgl1-mesa-dev libglu1-mesa-dev libfreetype6-dev \
    libogg-dev libvorbis-dev libtheora-dev tcl8.6-dev python3 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-13 100 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Clone and build openMSX 21
RUN git clone --branch RELEASE_21_0 --depth 1 https://github.com/openMSX/openMSX.git /tmp/openmsx \
    && cd /tmp/openmsx \
    && CXXFLAGS="-std=c++2b" ./configure --prefix=/usr/local --bindir=/usr/local/bin \
    && make -j$(nproc) \
    && make install

# ==============================================================================
# Stage 3: Final Debian 12 runtime
# ==============================================================================
FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:99

# Copy hex2bin from builder stage
COPY --from=hex2bin-builder /tmp/hex2bin-bin/hex2bin /usr/local/bin/

# Copy openMSX binaries from Ubuntu builder
COPY --from=openmsx-builder /usr/local /usr/local
COPY --from=openmsx-builder /opt/openMSX /opt/openMSX

# Copy newer C++ libraries from Ubuntu (for GLIBCXX_3.4.31 and 3.4.32)
COPY --from=openmsx-builder /usr/lib/aarch64-linux-gnu/libstdc++.so.6* /usr/lib/aarch64-linux-gnu/
COPY --from=openmsx-builder /lib/aarch64-linux-gnu/libgcc_s.so.1 /lib/aarch64-linux-gnu/

# Create non-root user
RUN useradd -ms /bin/bash dev \
    && mkdir -p /tmp/runtime-root \
    && chown dev:dev /tmp/runtime-root \
    && chmod 700 /tmp/runtime-root

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    x11vnc xvfb fluxbox supervisor novnc net-tools procps \
    xterm vim sdcc python3 \
    libsdl2-2.0-0 libsdl2-ttf-2.0-0 libglew2.2 libpng16-16 zlib1g \
    libgl1 libglu1-mesa libfreetype6 \
    libogg0 libvorbis0a libvorbisenc2 libtheora0 tcl8.6 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Setup openMSX directories
RUN mkdir -p /home/dev/.openMSX/persistent \
    /home/dev/.openMSX/share/systemroms \
    /home/dev/.openMSX/share/settings \
    && chown -R dev:dev /home/dev/.openMSX \
    && chmod -R 755 /home/dev/.openMSX

# Copy startup script
COPY --chown=dev:dev startup.tcl /home/dev/.openMSX/startup.tcl

# Configure Vim
RUN echo "set number\nsyntax on\nset expandtab\nset shiftwidth=4\nset softtabstop=4\nset autoindent\n" > /home/dev/.vimrc \
    && chown dev:dev /home/dev/.vimrc

# Create log directories
RUN mkdir -p /var/log/supervisor && chmod 755 /var/log/supervisor

# Copy supervisord configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose noVNC port
EXPOSE 6080

# Set working directory
WORKDIR /home/dev

# Start supervisord
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
