# Use an NVIDIA CUDA base image for GPU acceleration
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

LABEL maintainer="Gemini"
LABEL authors="Masih (updated by Gemini for Kaggle/PyCharm with PyTorch 2 CUDA)"

# Set environment variables for non-interactive apt-get
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies, Python 3.10, build tools, git, SSH, and Docker CLI
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 \
    python3.10-distutils \
    python3.10-dev \
    build-essential \
    git \
    curl \
    openssh-server \
    sudo \
    ca-certificates && \
    # Install pip for Python 3.10 \
    curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10 && \
    # --- Set up and install Docker CLI ---
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    # --- End Docker CLI setup --- \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user 'gemini' with password 'gemini' and sudo access
RUN useradd -m -s /bin/bash gemini && \
    echo "gemini:gemini" | chpasswd && \
    adduser gemini sudo && \
    echo "gemini ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/gemini-nopasswd

# Upgrade pip and install a comprehensive set of ML libraries with CUDA support
# PyTorch 2.x with CUDA 11.8
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
    torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 && \
    pip install --no-cache-dir \
    numpy \
    pandas \
    scikit-learn \
    matplotlib \
    seaborn \
    jupyterlab \
    # TensorFlow will automatically use GPU if CUDA is available \
    tensorflow \
    xgboost \
    lightgbm \
    catboost \
    kaggle

# Configure SSH server for remote connections from IDEs
RUN mkdir -p /var/run/sshd && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Set the working directory
WORKDIR /home/gemini/work

# Expose ports for SSH and JupyterLab
EXPOSE 22
EXPOSE 8888

# Create an entrypoint script to start the SSH server
RUN echo '#!/bin/bash' > /entrypoint.sh && \
    echo 'set -e' >> /entrypoint.sh && \
    echo 'sudo /usr/sbin/sshd' >> /entrypoint.sh && \
    echo 'echo "SSH server is running on port 22. User: gemini, Pass: gemini"' >> /entrypoint.sh && \
    echo 'exec "$@"' >> /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# Default command to start JupyterLab and keep the container running
# Jupyter will be accessible on port 8888
CMD ["/bin/bash", "-c", "echo 'Starting JupyterLab on port 8888...' && jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --NotebookApp.token='' --NotebookApp.password=''"]
