# 第一阶段：获取构建平台信息并选择QEMU版本
FROM --platform=$BUILDPLATFORM alpine:3.18.3 AS qemu

ARG BUILDPLATFORM
# 根据构建平台选择适当的QEMU版本并下载
RUN if [ "$BUILDPLATFORM" = "linux/amd64" ]; then \
        QEMU_ARCH="x86_64"; \
    elif [ "$BUILDPLATFORM" = "linux/arm64" ]; then \
        QEMU_ARCH="aarch64"; \
    elif [ "$BUILDPLATFORM" = "linux/arm/v6" ]; then \
        QEMU_ARCH="arm"; \
    elif [ "$BUILDPLATFORM" = "linux/arm/v7" ]; then \
        QEMU_ARCH="arm"; \
    else \
        echo "Unsupported platform" && exit 1; \
    fi

RUN curl -L -o /usr/bin/qemu-static \
    https://github.com/multiarch/qemu-user-static/releases/download/v6.2.0/qemu-$QEMU_ARCH-static && \
    chmod +x /usr/bin/qemu-$QEMU_ARCH-static

# 第二阶段：构建你的应用程序或执行其他操作
FROM --platform=$BUILDPLATFORM alpine:3.18.3
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
    netcat-openbsd \  # qemu-x86_64 qemu-system-x86_64 qemu-system-aarch64 qemu-system-arm
    busybox-extras iproute2 iputils \
    bridge-utils iptables jq bash python3 \
    libarchive-tools


# Environments which may be change
ENV ROUTEROS_VERSION="7.11.2"
ENV ROUTEROS_IMAGE="chr-$ROUTEROS_VERSION.vdi"
ENV ROUTEROS_PATH="https://download.mikrotik.com/routeros/$ROUTEROS_VERSION/$ROUTEROS_IMAGE"

# Download VDI image from remote site
RUN wget -qO- "$ROUTEROS_PATH".zip | bsdtar -C /routeros/ -xf- || wget "$ROUTEROS_PATH" -O "/routeros/$ROUTEROS_IMAGE"

# Copy script to routeros folder
ADD ["./scripts", "/routeros"]
# 复制来自第一阶段的QEMU二进制文件
COPY --from=qemu /usr/bin/qemu-static /usr/bin/

ENTRYPOINT ["/routeros/entrypoint.sh"]
