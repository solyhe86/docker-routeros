FROM alpine:3.18.3

LABEL maintainer="solyhe"

# For access via VNC
EXPOSE 5900

# Expose Ports of RouterOS
EXPOSE 1194 1701 1723 1812/udp 1813/udp 21 22 23 443 4500/udp 50 500/udp 51 2021 2022 2023 2027 5900 80 8080 8291 8728 8729 8900

# Change work dir (it will also create this folder if is not exist)
WORKDIR /routeros

# Install dependencies
RUN set -xe \
 && apk add --no-cache --update \
    netcat-openbsd \
    busybox-extras iproute2 iputils \
    bridge-utils iptables jq bash python3 \
    libarchive-tools
# 如果 ARCH 变量是 "amd64"，则安装 x86_64 平台的 QEMU 用户空间工具
# 如果 ARCH 变量是 "arm"，则安装 ARM 平台的 QEMU 用户空间工具
# 如果 ARCH 变量是 "arm64"，则安装 ARM64 平台的 QEMU 用户空间工具
ARG ARCH
RUN if [ "$ARCH" = "linux/amd64" ]; then \
        set -xe && apk add --no-cache --update qemu-x86_64 qemu-system-x86_64; \
    elif [ "$ARCH" = "linux/arm/v6" or "$ARCH" = "linux/arm/v7" ]; then \
        set -xe && apk add --no-cache  --update qemu-system-arm; \
    elif [ "$ARCH" = "linux/arm64" ]; then \
        set -xe && apk add --no-cache --update qemu-system-aarch64; \
    fi

# Environments which may be change
ENV ROUTEROS_VERSION="7.11.2"
ENV ROUTEROS_IMAGE="chr-$ROUTEROS_VERSION.vdi"
ENV ROUTEROS_PATH="https://download.mikrotik.com/routeros/$ROUTEROS_VERSION/$ROUTEROS_IMAGE"

# Download VDI image from remote site
RUN wget -qO- "$ROUTEROS_PATH".zip | bsdtar -C /routeros/ -xf- || wget "$ROUTEROS_PATH" -O "/routeros/$ROUTEROS_IMAGE"

# Copy script to routeros folder
ADD ["./scripts", "/routeros"]

ENTRYPOINT ["/routeros/entrypoint.sh"]
