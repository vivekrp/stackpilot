# Use the official Ubuntu base image
FROM ubuntu:mantic

RUN apt-get update -y && apt-get upgrade -y && apt-get install -y \
    curl \
    git \
    wget \
    unzip \
    vim \
    build-essential \
    gnupg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory to /app
WORKDIR /app

RUN if command -v sudo &>/dev/null && [ "$(id -u)" -ne 0 ]; then \
    echo "ENV SUDO=sudo" >> /etc/environment; \
    else \
    echo "ENV SUDO=" >> /etc/environment; \
    fi

# Install Homebrew, set up the environment, and install packages with brew in one RUN command
RUN yes | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /root/.bashrc && \
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && \
    brew install gcc gh


RUN (curl -Ls --tlsv1.2 --proto "=https" --retry 3 https://cli.doppler.com/install.sh || wget -t 3 -qO- https://cli.doppler.com/install.sh) | $SUDO sh
# Install bun and use it to install @antfu/ni in one RUN command
RUN curl -fsSL https://bun.sh/install | bash && \
    export PATH="$HOME/.bun/bin:$PATH" && \
    bun i -g @antfu/ni

# Use /bin/sh as the entry point to keep the container running
ENTRYPOINT ["/bin/bash"]