---
# author: TonyChou
title: "Python base image 切勿使用 alpine"
date: 2020-10-28
tags: ["docker"]
# categories: ["docker"]
draft: false
thumbnail: "images/2020/docker.png"
---

看了許多 docker 官網使用 python 做的範例, 經常看到使用 alpine base image.

使用過程發現 它(alpine) 真的很雷

本文大致說明為何

<!--more-->

## 動機

看了一大堆教學指南, 大家都說 image 最好能夠盡量的輕量, 能夠幫助你完成快速的建置, 測試, 部署....

所以多半情況下, 都傻傻的跟風, 選擇了帶有 *alpine* 的 Docker Image

但是它真的有比較快嗎? 

經過不曉得 N 次的使用後, 經常發現在建置過程中就掛掉了, 例如

![](/images/2020/DockerImage-alpine_error.png)

一下子 pip 問題, 一下子 wheel 問題, 一下子這啥 egg_info..... OK fine!

> 如果使用 Golang 的話, alpine 讚讚讚

> 如果使用 Python 的話, 千萬別用 alpine


## Image 建置的 Python 底層環境

為啥網路上那麼多阿貓阿狗的文章, 都使用 alpine Image?

底下使用 Ubuntu18.04 及 alpine 來做比較

![AlpineImage](/images/2020/DockerImage-alpine.png)
![UbuntuImage](/images/2020/DockerImage-ubuntu.png)

OK, alpine 確實比人家快, 7.83ms vs 20.42ms, 快很多很多

而且 Image Size 也比人家小一點 135MB vs 151MB, 小了人家 10% 以上

> alpine 暫時領先


## 環境底下安裝依賴套件

ubuntu base image 底下安裝 python3.8 && pip, 這動作完全不考慮

所以底下我們直接比較一下 `python:3.8-alpine` & `python:3.8-slim` & `python:3.8`

1. 首先我們來看看 `python:3.8-alpine`

![AlpineImage1](/images/2020/DockerImage-alpine1.png)

注意! 這邊抓的是 matplotlib-3.3.2.tar.gz, 此為 原始碼 編譯安裝 (pip install 的方式, 可分為 source code 及 wheel)

然後底下這張圖只是呈現他後半部掛掉了

![AlpineImage2](/images/2020/DockerImage-alpine2.png)

alpine 一如既往讓人失望, 必須解決一堆相依性問題

2. 再來我們看看 `python:3.8-slim`

![slimImage](/images/2020/DockerImage-slim.png)

3. 接著則是最完整的 `python:3.8`

![Python38Image](/images/2020/DockerImage-python38.png)

比較表如下:

Image             | Building time | Size
----------------- |:-------------:|:--------:
python:3.8-alpine | x             | x
python:3.8-slim   | 19.97s        | 268MB
python:3.8        | 20.01s        |  1.04G

至於 `python:3.8-slim` 總是優於 `python:3.8` ? 這我目前還不知道就是了

但相信大包總會有它比較優的地方, 但好在哪邊不是這篇文章的重點


## Note

回憶一下剛剛我們安裝的套件, 我們下載的是 `xxx.whl` 

![Python38whl](/images/2020/DockerImage-python38-whl.png)

它是預先被編譯好了 binary.

大多數的 Linux distributions 使用 GNU version 的 standard C library, 也就是 `glibc`

python wheel 也是使用這東西來做編譯

然而 alpine base image 裡頭裝的是 `musl` (另一種的 C library)

雖說兩者 (musl 與 glibc) 幾乎可以互相兼容

但以目前的情況來看, 兩者間的一點點差異就會造成問題, 使得結果無法正常預期

> Don't use Alpine Linux for Python images


# Reference

- [Using Alpine can make Python Docker builds 50× slower](https://pythonspeed.com/articles/alpine-docker-python/)
