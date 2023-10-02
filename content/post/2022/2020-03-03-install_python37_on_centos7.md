---
title: 在 CentOS7 上 安裝 Python3.7
date: 2020-03-03T23:00:00+08:00
tags: ["Python3", "CentOS7"]
draft: false
---

本文說明在全新的 CentOS7 裡頭, 安裝 Python3.7 && python-pip

<!--more-->

## 安裝

底下以 root 執行

```python
### 安裝 可以編譯 Python3 的必要套件 && 其他必要工具
yum install -y zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gcc make libffi-devel
# libffi-devel 專門給 python3.7

### 為了後續方便安裝「python-pip」
yum -y install epel-release

### 安裝 pip
yum install -y python-pip

### 下載 Python3.7.3 tar ball
yum install -y wget
wget https://www.python.org/ftp/python/3.7.3/Python-3.7.3.tgz

### 解壓縮 && 進入後編譯
tar zxf Python-3.7.3.tgz
cd Python-3.7.3
./configure
# configure 會執行一下子

### 開始 Compile (會執行比較久)
make && make install

### root 環境變數 (一般使用者可直接使用...)
echo 'PYTHON_HOME=/usr/local/bin' >> ~/.bash_profile
echo 'PATH=${PYTHON_HOME}:${PATH}' >> ~/.bash_profile
source ~/.bash_profile
```

## 後續

最後面一段的環境變數, 基本上可以不用作

(因為應該不會有人專程用 root 來寫 python3 吧?)

當然後續再依自己喜好, 選擇自己喜歡的虛擬環境控管方式 (venv, virtualvenv, pipenv, ...)

然後就沒有然後了

打開你的 IDE 開始寫程式吧
