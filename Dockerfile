FROM alpine:latest
LABEL authors="Masih"

# Install KDE Plasma, XRDP, and other necessary packages
RUN apk update && \
    apk add --no-cache \
    plasma-desktop-meta \
    xrdp \
    xorgxrdp \
    sudo \
    git \
    dbus \
    dbus-x11 \
    kf5-kconfig-extra-tools \
    && rm -rf /var/cache/apk/*

RUN useradd -m -s /bin/bash gemini && \
    echo "gemini:gemini" | chpasswd && \
    adduser gemini wheel && \
    sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers && \
    git clone https://github.com/yeyushengfan258/WinSur-kde.git /home/gemini/WinSur-kde && \
    chown -R gemini:gemini /home/gemini/WinSur-kde && \
    su - gemini -c "cd /home/gemini/WinSur-kde && ./install.sh" && \
    rm -rf /home/gemini/WinSur-kde

# Expose the RDP port
EXPOSE 3389

# Set the entrypoint to a startup script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
