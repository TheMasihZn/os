# Project Overview

This repository contains configurations and Docker setups for various operating system environments and development tools. It primarily features a customizable Alpine Linux desktop environment accessible via XRDP, and a specialized Docker environment for Kaggle competitions with GPU support.

## Main Components

### 1. Alpine Linux Desktop Environment

This section describes the main Docker environment configured at the root of the repository.

*   **Purpose:** Provides a lightweight Alpine Linux desktop experience with KDE Plasma, accessible remotely via XRDP. It includes pre-configured tools and a `gemini` user.
*   **Features:**
    *   Alpine Linux base
    *   KDE Plasma Desktop Environment
    *   XRDP for remote access
    *   `gemini` user with `sudo` privileges (password: `gemini`)
    *   `WinSur-kde` theme pre-installed
*   **Usage (Build & Run):**
    ```bash
    # Build the image
    docker build -t alpine-kde-xrdp .

    # Run the container
    docker run -d --name alpine-desktop -p 3389:3389 alpine-kde-xrdp
    ```
*   **Accessing the Desktop:** Connect to `localhost:3389` using an RDP client. Use username `gemini` and password `gemini`.

### 2. Kaggle GPU Docker Environment

This environment is tailored for data science and machine learning tasks, especially for Kaggle competitions. It includes PyTorch with CUDA support, JupyterLab, and SSH access.

For detailed instructions on building, running, and accessing this environment, please refer to:
[kaagle/README.md](kaagle/README.md)

## Project Structure

*   `.`: Root directory containing the Alpine Linux Desktop Environment Dockerfile and entrypoint script.
*   `kaagle/`: Contains the Dockerfile and related files for the Kaggle GPU Docker Environment.
*   `os.iml`, `.idea/`: Project configuration files (e.g., for IntelliJ IDEA).
