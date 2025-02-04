#!/bin/bash

# squid entrypoint
if [ "$1" = 'squid' ]; then
    chown -R proxy.proxy /data
    chown proxy.proxy /dev/stdout

    . /usr/share/squid-deb-proxy/init-common.sh
    pre_start
    post_start

    if [ -n "$http_proxy"  ]; then
      echo "Detected proxy setting: $http_proxy"
      proxy_host=$(echo $http_proxy | sed 's/\(http[:][/][/]\)\?\([^:/]\+\)\([:]\([0-9]\+\)[/]\?\)\?/\2/g')
      proxy_port=$(echo $http_proxy | sed 's/\(http[:][/][/]\)\?\([^:/]\+\)\([:]\([0-9]\+\)[/]\?\)\?/\4/g')
      tee -a /etc/squid-deb-proxy/squid-deb-proxy.conf <<-EOF
cache_peer $proxy_host parent $proxy_port 0 no-query default
acl all src all
http_access allow all
never_direct allow all
EOF

    fi

    if [ "$USE_ACL" = "0" ]; then
        echo "[WARN] No mirror acl active"
        sed -i '/to_archive_mirrors/c\# No mirror acl active.' /etc/squid-deb-proxy/squid-deb-proxy.conf
    fi

    if [ "$USE_AVAHI" = "1" ]; then
        echo "[WARN] enabling avahi daemon"
        avahi-daemon -D
    fi

    exec /usr/sbin/squid3 -N -f /etc/squid-deb-proxy/squid-deb-proxy.conf
fi

exec "$@"
