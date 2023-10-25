# 第一阶段：用于ARM平台
FROM arm32v7/alpine:3.18.3 AS arm-stage

# 在此阶段安装ARM平台特定的QEMU组件
RUN apk add --no-cache --update qemu-system-arm

# 第二阶段：用于ARM64平台
FROM arm64v8/alpine:3.18.3 AS arm64-stage

# 在此阶段安装ARM64平台特定的QEMU组件
RUN apk add --no-cache --update qemu-system-aarch64

# 第三阶段：用于x86_64平台
FROM alpine:3.18.3 AS x86_64-stage

# 在此阶段安装x86_64平台特定的QEMU组件
RUN apk add --no-cache --update qemu-x86_64 qemu-system-x86_64

# 最终阶段：选择要使用的阶段，根据平台
# 你可以通过在构建时指定不同的目标平台来选择相应的阶段
FROM alpine:3.18.3 AS final

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


# Environments which may be change
ENV ROUTEROS_VERSION="7.11.2"
ENV ROUTEROS_IMAGE="chr-$ROUTEROS_VERSION.vdi"
ENV ROUTEROS_PATH="https://download.mikrotik.com/routeros/$ROUTEROS_VERSION/$ROUTEROS_IMAGE"

# Download VDI image from remote site
RUN wget -qO- "$ROUTEROS_PATH".zip | bsdtar -C /routeros/ -xf- || wget "$ROUTEROS_PATH" -O "/routeros/$ROUTEROS_IMAGE"

# Copy script to routeros folder
ADD ["./scripts", "/routeros"]

ENTRYPOINT ["/routeros/entrypoint.sh"]
