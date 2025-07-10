#!/bin/sh
LOGFILE="/tmp/uci-defaults-log.txt"
echo "Starting 99-custom.sh at $(date)" >> $LOGFILE

uci set firewall.@zone[1].input='ACCEPT'

uci add dhcp domain
uci set "dhcp.@domain[-1].name=time.android.com"
uci set "dhcp.@domain[-1].ip=203.107.6.88"

SETTINGS_FILE="/etc/config/pppoe-settings"
if [ ! -f "$SETTINGS_FILE" ]; then
    echo "PPPoE settings file not found. Skipping." >> $LOGFILE
else
   . "$SETTINGS_FILE"
fi

count=0
ifnames=""
for iface in /sys/class/net/*; do
  iface_name=$(basename "$iface")
  if [ -e "$iface/device" ] && echo "$iface_name" | grep -Eq '^eth|^en'; then
    count=$((count + 1))
    ifnames="$ifnames $iface_name"
  fi
done
ifnames=$(echo "$ifnames" | awk '{$1=$1};1')

if [ "$count" -eq 1 ]; then
   uci set network.lan.proto='dhcp'
else
   wan_ifname=$(echo "$ifnames" | awk '{print $1}')
   lan_ifnames=$(echo "$ifnames" | cut -d ' ' -f2-)

   uci set network.wan=interface
   uci set network.wan.device="$wan_ifname"
   uci set network.wan.proto='dhcp'

   uci set network.wan6=interface
   uci set network.wan6.device="$wan_ifname"
   uci set network.wan6.proto='dhcpv6'
   uci set network.wan6.reqprefix='auto'
   uci set network.wan6.reqaddress='try'
   uci set network.wan6.auto='1'

   section=$(uci show network | awk -F '[.=]' '/\.@?device\[\d+\]\.name=.br-lan.$/ {print $2; exit}')
   if [ -z "$section" ]; then
      echo "error：cannot find device 'br-lan'." >> $LOGFILE
   else
      uci -q delete "network.$section.ports"
      for port in $lan_ifnames; do
         uci add_list "network.$section.ports"="$port"
      done
      echo "ports of device 'br-lan' are update." >> $LOGFILE
   fi

   uci set network.lan.proto='static'
   uci set network.lan.ipaddr='192.168.3.1'
   uci set network.lan.netmask='255.255.255.0'
   uci del dhcp.lan.ra_slaac
   uci set dhcp.lan.limit='100'
   uci set dhcp.lan.leasetime='24h'
   uci set dhcp.lan.force='1'
   uci set dhcp.lan.netmask='255.255.255.0'
   uci add_list dhcp.lan.dhcp_option='6,192.168.3.1'
   echo "set 192.168.3.1 at $(date)" >> $LOGFILE
   echo "print enable_pppoe value=== $enable_pppoe" >> $LOGFILE
   if [ "$enable_pppoe" = "yes" ]; then
      echo "PPPoE is enabled at $(date)" >> $LOGFILE
      uci set network.wan.proto='pppoe'
      uci set network.wan.username=$pppoe_account
      uci set network.wan.password=$pppoe_password
      uci set network.wan.peerdns='1'
      uci set network.wan.auto='1'
      # 仍然允许 wan6 保持 dhcpv6
      echo "PPPoE configuration completed successfully." >> $LOGFILE
   else
      echo "PPPoE is not enabled. Skipping configuration." >> $LOGFILE
   fi

   # 启用 LAN 的 IPv6 分发功能
   uci set dhcp.lan.dhcpv6='server'
   uci set dhcp.lan.ra='server'
   uci set dhcp.lan.ra_management='1'
   uci set dhcp.lan.ndp='hybrid'

   # 设置防火墙允许 IPv6 转发
   uci add firewall zone
   uci set firewall.@zone[-1].name='wan6'
   uci set firewall.@zone[-1].network='wan6'
   uci set firewall.@zone[-1].input='REJECT'
   uci set firewall.@zone[-1].output='ACCEPT'
   uci set firewall.@zone[-1].forward='REJECT'
   uci set firewall.@zone[-1].masq='1'
   uci set firewall.@zone[-1].mtu_fix='1'

   uci add firewall forwarding
   uci set firewall.@forwarding[-1].src='lan'
   uci set firewall.@forwarding[-1].dest='wan6'
fi

# 添加docker zone
uci add firewall zone
uci set firewall.@zone[-1].name='docker'
uci set firewall.@zone[-1].input='ACCEPT'
uci set firewall.@zone[-1].output='ACCEPT'
uci set firewall.@zone[-1].forward='ACCEPT'
uci set firewall.@zone[-1].device='docker0'

uci add firewall forwarding
uci set firewall.@forwarding[-1].src='docker'
uci set firewall.@forwarding[-1].dest='lan'

uci add firewall forwarding
uci set firewall.@forwarding[-1].src='docker'
uci set firewall.@forwarding[-1].dest='wan'

uci add firewall forwarding
uci set firewall.@forwarding[-1].src='lan'
uci set firewall.@forwarding[-1].dest='docker'

uci set dropbear.@dropbear[0].Interface=''

FILE_PATH="/etc/openwrt_release"
NEW_DESCRIPTION="Compiled by wongkoon"
sed -i "s/DISTRIB_DESCRIPTION='[^']*'/DISTRIB_DESCRIPTION='$NEW_DESCRIPTION'/" "$FILE_PATH"

uci commit
exit 0
