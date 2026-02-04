FROM debian:12-slim
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:99

# Create a non-root user for development
RUN useradd -ms /bin/bash dev \
    && mkdir -p /tmp/runtime-root \
    && chown dev:dev /tmp/runtime-root \
    && chmod 700 /tmp/runtime-root

# Install runtime and build dependencies (including SDCC from repos)
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    cmake \
    pkg-config \
    x11vnc \
    xvfb \
    fluxbox \
    supervisor \
    novnc \
    net-tools \
    procps \
    xterm \
    vim \
    wget \
    bzip2 \
    sdcc \
    # OpenMSX dependencies
    libsdl2-dev \
    libsdl2-ttf-dev \
    libglew-dev \
    libpng-dev \
    zlib1g-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libfreetype6-dev \
    libogg-dev \
    libvorbis-dev \
    libtheora-dev \
    tcl8.6-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Switch to dev for cloning and building
USER dev
WORKDIR /home/dev

# Clone and configure openMSX (build as dev, install as root)
RUN git clone --branch RELEASE_20_0 --depth 1 https://github.com/openMSX/openMSX.git /home/dev/openmsx && \
    cd /home/dev/openmsx && \
    ./configure --prefix=/usr/local && \
    make -j$(nproc)

# Install openMSX as root
USER root
RUN cd /home/dev/openmsx && make install

# Cleanup source code
RUN rm -rf /home/dev/openmsx

# Setup openMSX directories with proper permissions
RUN mkdir -p /home/dev/.openMSX/persistent \
    /home/dev/.openMSX/share/systemroms \
    /home/dev/.openMSX/share/settings \
    && chown -R dev:dev /home/dev/.openMSX \
    && chmod -R 755 /home/dev/.openMSX

# Copy startup script
COPY --chown=dev:dev startup.tcl /home/dev/.openMSX/startup.tcl

# Configure Vim for development
RUN echo "set number\nsyntax on\nset expandtab\nset shiftwidth=4\nset softtabstop=4\nset autoindent\n" > /home/dev/.vimrc \
    && chown dev:dev /home/dev/.vimrc

# Create log directories
RUN mkdir -p /var/log/supervisor && \
    chmod 755 /var/log/supervisor

# Copy supervisord configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose noVNC port
EXPOSE 6080

# Run supervisord as root
USER root
WORKDIR /home/dev

# Start supervisord
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
