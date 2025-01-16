#!/bin/bash

echo "编译固件大小为: $PROFILE MB"
echo "Include Docker: $INCLUDE_DOCKER"

# 输出调试信息
echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始编译..."



# 定义所需安装的包列表 下列插件你都可以自行删减
PACKAGES=""
PACKAGES="$PACKAGES curl"
PACKAGES="$PACKAGES luci-i18n-diskman-zh-cn"
PACKAGES="$PACKAGES luci-i18n-firewall-zh-cn"
PACKAGES="$PACKAGES luci-i18n-filebrowser-go-zh-cn"
PACKAGES="$PACKAGES luci-app-argon-config"
PACKAGES="$PACKAGES luci-i18n-argon-config-zh-cn"
PACKAGES="$PACKAGES luci-app-opkg"
PACKAGES="$PACKAGES luci-i18n-ttyd-zh-cn"
PACKAGES="$PACKAGES luci-app-openclash"
PACKAGES="$PACKAGES luci-i18n-homeproxy-zh-cn"
PACKAGES="$PACKAGES luci-i18n-ddns-go-zh-cn"
PACKAGES="$PACKAGES luci-proto-wireguard"
PACKAGES="$PACKAGES openssh-sftp-server"
PACKAGES="$PACKAGES luci-app-vlmcsd"
# 增加几个必备组件 方便用户安装iStore
PACKAGES="$PACKAGES fdisk"
PACKAGES="$PACKAGES script-utils"
PACKAGES="$PACKAGES luci-i18n-samba4-zh-cn"
PACKAGES="$PACKAGES nano"
PACKAGES="$PACKAGES 7z"
PACKAGES="$PACKAGES pv"
PACKAGES="$PACKAGES gzip"
PACKAGES="$PACKAGES curl"
PACKAGES="$PACKAGES yq"
PACKAGES="$PACKAGES jq"
PACKAGES="$PACKAGES coreutils-nohup"
PACKAGES="$PACKAGES coreutils"
PACKAGES="$PACKAGES qrencode"
PACKAGES="$PACKAGES busybox"
PACKAGES="$PACKAGES python3"
PACKAGES="$PACKAGES python3-pip"
PACKAGES="$PACKAGES python3-yaml"
PACKAGES="$PACKAGES python3-flask"
PACKAGES="$PACKAGES python3-aiohttp"
PACKAGES="$PACKAGES bash"
PACKAGES="$PACKAGES uci"
PACKAGES="$PACKAGES shadow"
PACKAGES="$PACKAGES shadow-utils"
PACKAGES="$PACKAGES shadow-chpasswd"

# 判断是否需要编译 Docker 插件
if [ "$INCLUDE_DOCKER" = "yes" ]; then
    PACKAGES="$PACKAGES luci-i18n-dockerman-zh-cn"
    echo "Adding package: luci-i18n-dockerman-zh-cn"
fi

# 构建镜像
echo "$(date '+%Y-%m-%d %H:%M:%S') - Building image with the following packages:"
echo "$PACKAGES"

make image PROFILE="generic" PACKAGES="$PACKAGES" FILES="/home/build/immortalwrt/files" ROOTFS_PARTSIZE=$PROFILE

if [ $? -ne 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Build failed!"
    exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Build completed successfully."
