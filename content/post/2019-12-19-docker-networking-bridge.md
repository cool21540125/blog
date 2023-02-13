---
title: "Docker Networking"
subtitle: "Bridge Network Driver"
date: 2019-12-19
tags: ["docker-networking"]
draft: false
# thumbnail: "images/2019/DockerNetworking.png"
---

![DockerNetworking](/images/2019/DockerNetworking.png)

Docker Networking Drivers 可區分成底下 5 種：

1. bridge (預設)
2. host - 可直接與 Docker Host 映射所有 ports (因只有 Linux 可使用, 故本文略)
3. overlay - 給 Swarm 使用 (因比較進階, 故本文略)
4. macvlan - 可在 Container 內設定 Mac Address (比較涉及網路底層, 故本文略)
5. none - 關閉 Container 的 Networking (因為太自閉了, 故本文略)

底下詳述 Docker Bridge Networks

<!--more-->

## Prerequest

- 安裝好 Docker
- 對 Docker 有初步的認知 (起碼用過 docker run XXX, 然後可以使用裏頭的服務)


## Networking

安裝完 Docker 之後, 電腦裡頭會 `多出一張網卡`

```bash
# Linux 會多出這個 (Bridge Driver 使用)
$ ifconfig docker0
docker0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
        inet 172.17.0.1  netmask 255.255.0.0  broadcast 172.17.255.255
        ether 02:42:99:c8:27:f0  txqueuelen 0  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

# Mac 會多出這個
$ ifconfig bridge0
bridge0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
    options=63<RXCSUM,TXCSUM,TSO4,TSO6>
    ether 32:00:a1:38:4b:01
    Configuration:
        id 0:0:0:0:0:0 priority 0 hellotime 0 fwddelay 0
        maxage 0 holdcnt 0 proto stp maxaddr 100 timeout 1200
        root id 0:0:0:0:0:0 priority 0 ifcost 0 port 0
        ipfilter disabled flags 0x2
    member: en1 flags=3<LEARNING,DISCOVER>
            ifmaxaddr 0 port 13 priority 0 path cost 0
    member: en2 flags=3<LEARNING,DISCOVER>
            ifmaxaddr 0 port 14 priority 0 path cost 0
    member: en3 flags=3<LEARNING,DISCOVER>
            ifmaxaddr 0 port 15 priority 0 path cost 0
    member: en4 flags=3<LEARNING,DISCOVER>
            ifmaxaddr 0 port 16 priority 0 path cost 0
    Address cache:
    nd6 options=201<PERFORMNUD,DAD>
    media: <unknown type>
    status: inactive

# Windows + Hyper-V 會多出這個
$ ipconfig
乙太網路卡 vEthernet (DockerNAT):

   連線特定 DNS 尾碼 . . . . . . . . :
   IPv4 位址 . . . . . . . . . . . . : 10.0.75.1
   子網路遮罩 . . . . . . . . . . . .: 255.255.255.0
   預設閘道 . . . . . . . . . . . . .:
```


## Bridge Networks

> Bridge Network 屬於 Link Layer device. 它隔離了網路區段之間的 資料傳輸 (藉由設定相同的 Bridge, Containers 之間可相互溝通). 在 Docker Host, bridge driver 會被自動安裝. Docker Container 預設上會自動使用「bridge」的 bridge network, 它會自動開放所有 ports 給所有套用相同 Network 的 Container, 且可以 share 彼此的環境變數, 但它 不對外開放.
使用 bridge 的 Containers 之間透過 IP Address 相互溝通, 老舊時期的做法, 則是使用 「--link」(但現在已經不建議).
> 如果建立 Container 沒特別指名 Networking 的方式的話, 預設就是使用 `Default Bridge`

Bridge Driver 可區分成下列 2 者:

- Default Bridge Network
- User-Defined Bridge Network

簡單的說就是 **預設** 跟 **自訂** 啦


### 1. Default Bridge Network

bridge 預設無法讓 Container 傳遞訊息到 外界(outside world), ex: 不同 Docker Hosts 之間的 Container 要相互溝通的話, 做法有下列 2 種:

#### 法一:

在 Docker Host 做底下 2 個設定:

```bash
# 1. 在 `OS Level` 設定 routing
$ sysctl net.ipv4.conf.all.forwarding=1
# ex: 讓 Linux kernel 允許 IP routing

# 2. 設定「iptables FORWARD policy」為 ACCEPT(原為 DROP)
$ sudo iptables -P FORWARD ACCEPT
```

#### 法二:

改用 `overlay network1`

```bash
# 語法: 指定 Network, 並且開放 Port號 映射, 建立 Container
$ docker create --name <Container Name> --network <Network Name> --publish <Host Port>:<Container Port>

# 範例~
$ docker create --name my-nginx --network my-net --publish 8080:80 nginx:latest
# 使用名為 nginx:latest 的 Image 來建立名為 my-nginx 的 Container, 此 Container 使用名為 my-net 的自定義 Network,
# Docker Host端 可透過 8080 port 來用 Container 內的 80 port 所提供的服務.
```

Docker Bridge Network 可再區分成 2 類:

  - Default Bridge: 用於開發環境, 生產環境完全不建議使用.
  - User-Defined Bridge: 用於生產環境, 同一台 Docker host 要讓 Containers 相互通訊.

> Bridge networks are usually used when your applications run in standalone containers that need to communicate.
> Use user-defined bridge networks shows how to create and use your own custom bridge networks, to connect containers running on the same Docker host. This is recommended for standalone containers running in production.

### 2. User-Defined Bridge Network

> user-defined bridge 已經自動做好了 Automatic Service Discovery, 也就是說,
Containers 之間可透過 `ip` 或 `ContainerName` 相互通訊 (Default Bridge 則只能使用 ip)

```bash
### 建立自訂義的 Bridge Network
$ docker network create --driver bridge alpine-net
# 或
$ docker network create -d bridge alpine-net
# 或
$ docker network create alpine-net

### 查看自定義的網卡 alpine-net
$ docker network inspect alpine-net
[
    {
        "Name": "alpine-net",
        "Id": "2e2529cab4...",
        "Created": "2018-06-19T21:56:36.142750051+08:00",
        "Scope": "local",
        "Driver": "bridge",     # Network Driver 為 bridge
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.18.0.0/16",  # Network Name 為 172.18.0.0/16
                    "Gateway": "172.18.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {},
        "Options": {},
        "Labels": {}
    }
]

### 使用 alpine image 建立 4 個 Container, 並指定 network driver
$ docker run -dit --name alpine1 --network alpine-net alpine ash    # alpine1 指定 alpine-net 網卡
$ docker run -dit --name alpine2 --network alpine-net alpine ash    # alpine2 指定 alpine-net 網卡
$ docker run -dit --name alpine3 alpine ash                         # alpine2 不指定網卡 (預設採用 bridge)
$ docker run -dit --name alpine4 --network alpine-net alpine ash    # alpine4 指定 alpine-net 網卡
$ docker network connect bridge alpine4                             # alpine4 額外附加 bridge 網卡
# 使用 ash (而非 bash) 來作為預設執行的程式
# 使用 alpine image 建立 Containers
# 預設上, 都會附加 bridge network

$ docker ps
CONTAINER ID    IMAGE     COMMAND    CREATED    STATUS    PORTS    NAMES
e5f58da319fa    alpine    "ash"      (pass)     (pass)    alpine4           # 172.18.0.4/16     172.17.0.3/16
5e8bbe5278ac    alpine    "ash"      (pass)     (pass)    alpine3           #                   172.17.0.2/16
20a3f3cfa029    alpine    "ash"      (pass)     (pass)    alpine2           # 172.18.0.3/16
3e0817ad0f2a    alpine    "ash"      (pass)     (pass)    alpine1           # 172.18.0.2/16

# alpine1, alpine2, alpine4 附加了 "alpine-net network"    subnet: 172.18.0.0/16
# alpine3, alpine4          附加了 "bridge     network"    subnet: 172.17.0.0/16
# 以上 4個 Containers 都具有對外網路的功能(都可以 ping google.com)
```
