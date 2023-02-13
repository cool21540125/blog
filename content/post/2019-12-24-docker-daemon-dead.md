+++
title = "Docker Daemon 掛掉 - 問題排解"
# subtitle:
date = 2019-12-24
tags = ["docker"]
draft = false
+++

起初不知為何的, 把 Docker 搞掛掉了, 然後一直 `systemctl restart docker` 都無解

但之後想一想, 剛剛只是做了 `docker build`, `docker run`, 會不會是 Container 出問題導致 Docker Daemon 掛掉?

於是開始了下面的解法

<!--more-->

節錄了其中幾段 Log


### Terminal 1

```bash
$ docker ps
Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?

$ systemctl status docker
● docker.service - Docker Application Container Engine
   Loaded: loaded (/usr/lib/systemd/system/docker.service; enabled; vendor preset: disabled)
   Active: inactive (dead) (Result: exit-code) since Tue 2019-12-24 13:40:18 CST; 2min 8s ago
     Docs: https://docs.docker.com
  Process: 21233 ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock (code=exited, status=1/FAILURE)
 Main PID: 21233 (code=exited, status=1/FAILURE)
    Tasks: 0
   Memory: 0B
   CGroup: /system.slice/docker.service

Dec 24 13:40:18 tgfc-220 systemd[1]: docker.service: main process exited, code=exited, status=1/FAILURE
Dec 24 13:40:18 tgfc-220 systemd[1]: Failed to start Docker Application Container Engine.
Dec 24 13:40:18 tgfc-220 systemd[1]: Unit docker.service entered failed state.
Dec 24 13:40:18 tgfc-220 systemd[1]: docker.service failed.
Dec 24 13:40:18 tgfc-220 systemd[1]: Stopped Docker Application Container Engine.
Dec 24 13:42:24 tgfc-220 systemd[1]: Dependency failed for Docker Application Container Engine.
Dec 24 13:42:24 tgfc-220 systemd[1]: Job docker.service/start failed with result 'dependency'.
# 上面的資訊似乎價值有限

$ journalctl -f
...(略)...
Dec 24 13:52:20 tgfc-220 systemd[1]: Failed unmounting /var.
Dec 24 13:52:20 tgfc-220 systemd[1]: Failed unmounting /var.
Dec 24 13:52:20 tgfc-220 umount[15579]: umount: /home: target is busy.
Dec 24 13:52:20 tgfc-220 umount[15579]: (In some cases useful info about processes that use
Dec 24 13:52:20 tgfc-220 umount[15579]: the device is found by lsof(8) or fuser(1))
Dec 24 13:52:20 tgfc-220 systemd[1]: Failed unmounting /home.
Dec 24 13:52:20 tgfc-220 umount[15582]: umount: /home: target is busy.
Dec 24 13:52:20 tgfc-220 umount[15582]: (In some cases useful info about processes that use
Dec 24 13:52:20 tgfc-220 umount[15582]: the device is found by lsof(8) or fuser(1))
...(略)...
```

### Terminal 2

```bash
$ systemctl start docker
```

# 那, 我到底都幹了什麼?

稍早掛掉以前, 我依照下面的 Dockerfile 來建立 Image

```bash
FROM centos:centos7

ENV TZ Asia/Taipei
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ENV PY_VERSION=3.7.4
RUN set -ex && \
    yum install -y wget tar libffi-devel zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gcc make initscripts && \
    wget https://www.python.org/ftp/python/${PY_VERSION}/Python-${PY_VERSION}.tgz && \
    tar -zxvf Python-${PY_VERSION}.tgz && \
    cd Python-${PY_VERSION} && \
    ./configure prefix=/usr/local/python3 && \
    make && \
    make install && \
    make clean && \
    rm -rf /Python-${PY_VERSION}* && \
    yum install -y epel-release && \
    yum install -y python-pip && \
    yum clean all

ENV PATH "$PATH:/usr/local/python3/bin"

RUN pip3 install --upgrade pip

RUN mkdir /etc/app

COPY sys.conf /etc/app
COPY daemon.conf /etc/app

# 就是這邊出了問題!!
RUN sudo groupadd docker
RUN adduser --system app
RUN sudo usermod -aG docker app
RUN mkdir -p /home/app /var/app /var/log/app

# .... 其他... (略)...

CMD ["systemctl", "restart", "appd.service"]
```

然後很理所當然的來執行

```bash
$ docker run -d \
   --restart=always \
   --name=monitor_site \
   --hostname=app-site-monitoring \
   --privileged=true \
   monitor_site /usr/sbin/init
# 然後 Docker Daemon 就掛掉了

### 但依然可以重啟它, 只是重啟後馬上又掛掉
$ docker restart docker
```

直到我有把上面的 Dockerfile 改一改, 然後在建立另一個 Image, 執行 `docker run` 以後就整個死掉

以上敘述大概是整個事件的還原


# 那, 怎麼救回來?

想一想, 如果是 Container 掛掉導致 Docker Daemon 掛掉, 那就把 Container 移除不就好了!!

```bash
$ docker rm --force monitor_site
# 乾~ 對齁, Docker 掛了, 指令無法使用
```

經過 Google 之後發現, Container 存在於 `/var/lib/docker` 之中

```bash
$ ls -l /var/lib/docker/containers
drwx------. 4 root root 237 Dec 24 13:52 27edb86d856b422956434cc80c885ac5c64a598e3a5b222fffc0fafe046a0da0
drwx------. 4 root root 237 Dec 24 13:52 4e2d8099f383ee38c85e6970c00c85d50ff8f9d086f32552caa1661d1d8eb752
drwx------. 4 root root 237 Dec 24 13:52 5555ff882b9456cd8c11573f3b7d83149231629ce5df5b42f2e48870b3c60e63
drwx------. 4 root root 237 Dec 24 13:52 6e1a346731b2e1ffb524ba934f0a0a49bd4adc077e8e439aff7af6cf2d708d07
# 然後再一個一個進去, 找出出問題的 Container
# 把整個資料夾移除即可. (但為了保險起見, 建議先把上面的資料夾 mv 到其他地方)

### 假設是 6e1a346731b2e1ffb524ba934f0a0a49bd4adc077e8e439aff7af6cf2d708d07 出問題
$ mv ./6e1a346731b2e1ffb524ba934f0a0a49bd4adc077e8e439aff7af6cf2d708d07 /root/.

$ systemctl restart docker
```

如此一來, Docker Daemon 就救回來了!!  哈雷嚕雅!!


# Notes

把 Container 移除前, 請確保當初有把裏頭的東西 `-v` 映射出來, 做好備份再移除... 不然後果自行負責...
