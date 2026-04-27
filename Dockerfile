# ComfyUI Docker Build File v1.0.1 by John Aldred
# https://www.johnaldred.com
# https://github.com/kaouthia
#
# Modified by Thomas Dewitte
# https://github.com/dewittethomas

# Use a minimal Python base image (adjust version as needed)
FROM python:3.12-slim-trixie

ENV DEBIAN_FRONTEND=noninteractive
ARG CUDA_VERSION=130

# Allow passing in your host UID/GID (defaults 1000:1000)
ARG UID=1000
ARG GID=1000

# Install OS deps and create the non-root user
RUN apt-get update \
 && apt-get install -y --no-install-recommends git \
 && groupadd --gid ${GID} appuser \
 && useradd --uid ${UID} --gid ${GID} --create-home --shell /bin/bash appuser \
 && rm -rf /var/lib/apt/lists/*

# Install Mesa/GL and GLib so OpenCV can load libGL.so.1 for ComfyUI-VideoHelperSuite
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libgl1 \
      libglx-mesa0 \
      libglib2.0-0 \
      fonts-dejavu-core \
      fontconfig \
 && rm -rf /var/lib/apt/lists/*

# Copy and enable the startup script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to non-root user
USER $UID:$GID

# Set the working directory
WORKDIR /app

# Clone the ComfyUI repository (replace URL with the official repo)
RUN git clone --depth 1 --branch master https://github.com/comfyanonymous/ComfyUI.git

# Change directory to the ComfyUI folder
WORKDIR /app/ComfyUI

RUN pip install --no-cache-dir --upgrade pip

# Install ComfyUI dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Install PyTorch with CUDA support
RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu${CUDA_VERSION}

# (Optional) Clean up pip cache to reduce image size
RUN pip cache purge

# make ~/.local/bin available on the PATH so scripts like tqdm, torchrun, etc. are found
ENV PATH=/home/appuser/.local/bin:$PATH

# Expose the port that ComfyUI will use (change if needed)
EXPOSE 8188

# Run entrypoint first, then start ComfyUI
ENTRYPOINT ["/entrypoint.sh"]
CMD ["python","/app/ComfyUI/main.py","--listen","0.0.0.0"]