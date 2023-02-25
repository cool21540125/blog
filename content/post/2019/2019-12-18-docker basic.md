+++
title = "Docker 基本入門"
subtitle = "以 nginx 為例"
date = 2019-12-18
tags = ["docker"]
draft = false
thumbnail = "images/2020/docker.jpeg"
+++

這是個 Docker 基本入門文章, 對於已經有用過 Docker 的人來說, 此文幾乎沒有營養成分.

假如你沒碰過 Docker, 但是對於下列有些模糊的概念, 此篇可能適合你花點時間看看:

<!--more-->

## Prerequest

- 若要提供網路服務, 需要讓服務對應到 port 上頭
- 對 TCP/IP 並不是完全的陌生
- 好像有點懂 Nginx(Web Server)
- 知道 Linux 這東西, 對於指令並不是完完全全的陌生
- 知道虛擬化技術這東西, 或者最起碼有聽過虛擬機
- 要有能力把 Docker 安裝起來

![DockerHost](/images/2019/12/docker_host.png)

以上圖來說, 上半部是我們開發常做的方式, ex: 把 Postgres 直接安裝在 *本地主幾(host)*

用戶端存取 Host 上頭的 5432 port, 並可直接存取 Postgres 服務

而下半部, 則是將服務安裝在 Docker Container 裏頭, 然後再透過 *已經安裝好 Docker 的本地主機(docker host)* 來提供此服務

用戶端存取服務的方式, 與上述如出一徹


# Get Started

現在想在本地端架設 Web Service, 但是因為各種原因, 不在本機直接安裝 Nginx...

```bash
$ docker run -d --name my-nginx -p 8888:80 nginx
b4dfde6048b63e15dcb82af50cc78210a7f2592538832447b87569f818b799d3
# Docker 會嘗試搜尋你電腦是否有 nginx 這個 Docker Image(光碟), 若沒有, 會上網把他抓到你電腦上
# 並用上述的 Image, 建立名為 my-nginx 的 Docker Container
# 讓外界可使用 8888 port, 存取到 Container 提供在 80 port 上頭的服務
# 底下看到的那排 b4df...., 就是建立起來的 Docker Container ID
```

在瀏覽器上存取 `http://localhost:8888`, 便可看到 Nginx 的服務

而看到的網頁內容, 便是一開始寫好在 Container 裡頭的東西


## Nginx 放上自己的網頁

底下網頁, 命名為 `index.html`

```html
<!DOCTYPE html>
<html>
<head>
    <title>Nginx 提供的 Web Page</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body>
    <h1>Web Page provided by nginx</h1>
    <p>但你這外行人, 永遠不會知道這東西運行在 Container 之中</p>
</body>
</html>
```

寫好網頁之後, 要把這東西 **放** 到 Container 裏頭

在此之前, 先把剛剛建立(毫無用處)的 Container 移除

```bash
docker rm --force my-nginx
```

然後我們自定義組態檔: `default.conf`

```conf
server {
    listen       80;
    server_name  localhost;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
}
```

借助一開始下載下來的 Docker Image: nginx 撰寫 dockerfile, 命名為 `dockerfile`

```dockerfile
FROM nginx
COPY ./index.html /usr/share/nginx/html
COPY ./default.conf /etc/nginx/conf.d
```

上述 dockerfile, 便是告訴 docker 使用 nginx 這個 Image

然後把目前目錄底下的東西, 在 Container 建立起來以後, 搬到 Container 對應的路徑之中

```bash
docker build . -t my-new-nginx
# 使用目前目錄底下的 dockerfile, 來自行建立 Docker Image, 命名為 my-new-nginx

docker run --name my-nginx -d -p 8888:80 my-new-nginx
# 使用 my-new-nginx 這個 Image, 運行 Container, 命名為 my-nginx, 並且透過 8888 port 來存取裡頭服務
```

如此瀏覽器上, `http://localhost:8888`, 便可看到剛剛寫好的網頁內容


# Reference

- [使用 Docker 建立 nginx 伺服器入門教學](https://blog.techbridge.cc/2018/03/17/docker-build-nginx-tutorial/)