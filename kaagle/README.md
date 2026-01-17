# Kaggle GPU Docker Environment

This setup provides a Dockerized environment for Kaggle competitions, featuring PyTorch 2 with CUDA support, JupyterLab, and SSH access for IDE integration.

## 1. Prerequisites

1.  **Docker Desktop:** Must be installed and running, using the WSL 2 backend.
2.  **NVIDIA Drivers:** Your host machine must have the latest NVIDIA GPU drivers installed.

## 2. Build the Image

```bash
docker build -t kaggle-cuda-env .
```

## 3. Run the Container

This command starts the container with GPU access and the necessary port mappings.

```bash
docker run -d --name my-cuda-kaggle-container --gpus all -p 2222:22 -p 8888:8888 -v //var/run/docker.sock:/var/run/docker.sock kaggle-cuda-env
```
- `--gpus all`: Enables GPU access.
- `-p 2222:22`: Maps port for SSH.
- `-p 8888:8888`: Maps port for JupyterLab.
- `-v //var/run/docker.sock...`: Enables Docker-in-Docker.

## 4. Access the Environment

*   **JupyterLab:** Open your browser to `http://localhost:8888`.

*   **SSH & PyCharm Remote Interpreter:**
    - **Host:** `localhost`
    - **Port:** `2222`
    - **Username:** `gemini`
    - **Password:** `gemini`

*   **Direct Shell Access:**
    ```bash
    docker exec -it my-cuda-kaggle-container bash
    ```

## 5. Verify GPU Support

To confirm PyTorch can see the GPU, run the following inside the container's shell:

```bash
python -c "import torch; print(f'PyTorch version: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}')"
```
The output should show `CUDA available: True`.
