---
title: 架設私有 PyPI Server
date: 2020-03-05T20:00:00+08:00
tags: ["Python3", "CentOS7", "PyPI-Server"]
draft: false
---
![](/images/2020/03/pypiServer.png)

* 用過 Python 的你或許知道 `pip install XX`, 但是你知道這是什麼原理嗎?
* 整包服務寫好了, 但跨組之間的套件如何相互飲用又可維持不對外開放?
* 網路對外很慢, 打算用私有 PyPI Server 作為快取或許也是個不錯的點子

本文來教你, 在私有環境架一個 PyPI Server

<!--more-->


## 原理解說

我們常常安裝 Python 套件時, 很自然地使用了 `pip install XX`

其實是 pip 指令工具幫你到遠端的 PyPI Repository 尋找並下載 XX 套件, 並安裝到你的環境裡頭

而 XX 等套件, 其實又是其他人透過某些方式(如上圖 `twine upload XX`), 把他們寫好的套件發布到 PyPI Repository 供人家下載

而 PyPI Server 又可架設的方式有很多種, 底下用最簡易的 `pypiserver` 套件來實作


## 情境

以我的環境為例,

我開一台虛擬機, IP 為 192.168.0.105 (模擬 PyPI Server)

而本地端為 192.168.0.100 (模擬 PyPI Client)

底下是模擬的故事情境...

你們公司內部對外網路流量很大, 時常需要去抓東抓西, 因而時不時都需要等個幾秒鐘讓你很不爽

於是想說把常用套件都抓下來放到內部網路的 PyPI Server

到時候大家直接到 私有 PyPI Server 作 pip install 便可省下不少時間了

廢話太多了, 底下開始做吧


## 架設私有 PyPI Server

```bash
# Linux 的 tony 使用者, 在家目錄的 demo-pypi-server 底下
$ mkdir ~/demo-pypi-server
$ cd ~/demo-pypi-server

# 架設 pypi-server 所需的套件
$ python3 -m venv venv
$ source venv/bin/activate
$ pip install pypiserver
$ mkdir packages  # 將來用來當作倉庫的地方


# 隨意去網路上下載幾個套件吧
$ pip install requests
$ pip install beautifulsoup4
$ pip install selenium
$ pip install flask
$ pip install numpy
$ pip install jupyter notebook
$ pip freeze > requirements.txt

# 接著, 讓自己的倉庫當成快取吧
$ pip install pip2pi  # pip2pi 可以把已安裝的套件, 放到自己的 pypi server
$ ls ./packages       # 目前裡頭都是空的唷!!
$ pip2pi ./packages/. -r requirements.txt
$ ls ./packages       # 可以看到你剛剛建立的依賴套件都在裡面了
beautifulsoup4-4.8.2-py3-none-any.whl    passlib-1.7.2-py2.py3-none-any.whl     simple
certifi-2019.11.28-py2.py3-none-any.whl  pypiserver-1.3.2-py2.py3-none-any.whl  soupsieve-2.0-py2.py3-none-any.whl
chardet-3.0.4-py2.py3-none-any.whl       requests-2.23.0-py2.py3-none-any.whl   urllib3-1.25.8-py2.py3-none-any.whl
idna-2.9-py2.py3-none-any.whl            selenium-3.141.0-py2.py3-none-any.whl

# 等下要幫 pypi-server 設定認證所需的套件 (這部分可不作)
$ sudo yum install -y httpd-tools
$ pip install passlib
$ htpasswd -sc .htpasswd demouser
New password:   # 隨意輸入一組密碼, ex: 123
Re-type new password:   # 一樣輸入 123
Adding password for user demouser

# 這便是使用 htpasswd 所授權的用戶
$ cat .htpasswd
demouser:{SHA}QL0AFWMIX8NRZTKeof9cXsvbvu8=
# ↑ 這邊幫你紀錄 user & password(加密過後的喔)

$ ls -al
drwxrwxr-x. 4 tony tony   75  3月  6 01:17 .
drwx------. 5 tony tony  172  3月  6 01:01 ..
-rw-rw-r--. 1 tony tony   44  3月  6 01:17 .htpasswd  # 剛剛建立的認證檔案
drwxrwxr-x. 3 tony tony 4096  3月  6 01:13 packages   # 這裡就是 PyPI Server 的倉庫了
-rw-rw-r--. 1 tony tony  166  3月  6 01:10 requirements.txt
drwxrwxr-x. 5 tony tony   74  3月  6 01:01 venv

# 接著想把服務建在本地端 8000 port
$ sudo firewall-cmd --add-port 8000/tcp
$ pypi-server -p 8000 -P .htpasswd ./packages
# 上面這個指令, 便把 PyPI Server 運行起來了喔
```

打開你的瀏覽器看看吧 -> http://192.168.0.105:8000

![PyPIServer](/images/2020/03/PyPI_Server_Page.png)


## 使用私有 PyPI Server - 下載

本地端的使用方式:

`pip install --extra-index-url http://192.168.0.105:8000/simple/ --trusted-host 192.168.0.105 beautifulsoup4 selenium requests`

- `--extra-index-url`: 告訴 pip, 你要下載的倉庫位置. 沒指定的話, 預設會到 [pypi.org](https://pypi.org/) 下載
- `--trusted-host`: 因為剛架的 Server 並沒做 https, 所以需要加這段

你會發現下載速度快很多啊~~~
![InstallFromPrivatePyPI](/images/2020/03/install_from_privatepypi.png)


## 使用私有 PyPI Server - 上傳

關於底下要做的「上傳」以前, 要先知道如何做「打包」 (你常看到的 XXX.whl)

那就是另一回事了, 自行 Google... 這篇只談 架設 && 使用 PyPI Server

```bash
# 上傳 打包檔 的指令工具
$ pip install twine

### 上傳自行打包好的套件「example_pkg_tonychoucc-0.0.3-py3-none-any.whl」
$ twine upload --repository-url http://192.168.0.105:8000 example_pkg_tonychoucc-0.0.3-py3-none-any.whl
Uploading distributions to http://192.168.0.105:8000
Enter your username: demouser  # 需要自行輸入認證
Enter your password:
Uploading example_pkg_tonychoucc-0.0.3-py3-none-any.whl
100%|█████████████████████████████████████| 7.38k/7.38k [00:59<00:00, 126B/s]
# 因為這樣太麻煩了~~~ 所以乾脆把認證的部分先偷偷弄好, 將來比較省事

$ vim ~/.pypirc
########## 文件內部 ##########
[distutils]
  index-servers =
  mypypi

[mypypi]  # 倉庫名為 mypypi
repository:http://192.168.0.105:8000  # 倉庫位置
username:demouser
password:123
########## 文件內部 ##########

# 如此上傳的方式就乾脆多了, 我只需要指定我要上傳到哪個倉庫, 認證部分都交由 .pypirc 幫忙搞定
$ twine upload -r mypypi example_pkg_tonychoucc-0.0.2-py3-none-any.whl
Uploading distributions to http://192.168.0.105:8000
Uploading example_pkg_tonychoucc-0.0.2-py3-none-any.whl
100%|█████████████████████████████████████| 7.21k/7.21k [00:41<00:00, 180B/s]
```


## 後記

1. 不曉得為什麼, mac 上開 VirtualBox, 常常都會卡住... 速度超慢
2. 最後關於「PyPI」, N年前我看一本書寫說他要唸作「批批」, 而 Youtube 上有人把他唸作「拍拍」, 也有人唸做「拍批」..... 總之不管啦! 你爽就好
