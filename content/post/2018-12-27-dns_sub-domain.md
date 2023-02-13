---
title: DNS - 子網域自治區
# subtitle: DNS - 子網域自治區
date: 2018-12-27
tags: ["dns", "apache"]
draft: false
---

![SubDomain](/images/2018/12/sub-domain.png)

延續 [DNS - 基礎實作](/post/2018-12-25-dns_basic), 現在我們要自己人管自己人!!  ~~台灣獨立!? 台灣自治!?~~

<!--more-->

# Story

現在我們公司的 Domain 為 `orz.com`, 而我想在此 Domain 之下, 弄出自己的 Sub-domain.

將來就由 `dns.wow.orz.com` 來主管 `wow.orz.com` 這個領域囉!!

- 上層 DNS Server : `192.168.124.64/24` : dns7.orz.com
- 下層 DNS Server : `192.168.124.102/24` : dns.wow.orz.com
- 下層 DNS 管轄的 Web Server : `192.168.124.104/24` : www.wow.orz.com

> 管轄 `wow.orz.com` 的主機, 不一定得命名為 `xxx.wow.orz.com`*. 另外, 此文並非 [DNS - master/slave 架構](/post/2018-12-26-dns_master-slave) 的延續文章*

# Prerequest

- 需要有一點點的 Apache 概念~
- 開設 3 台 VM
    - 上層 DNS : 192.168.124.64, dns7.orz.com, 掌管 orz.com
    - 下層 DNS : 192.168.124.102, dns.wow.orz.com, 掌管 wow.orz.com
    - Web Server : 192.168.124.104, www.wow.orz.com, 提供 Web Service


# Implementation

1. 上層 DNS 設定 (dns7.orz.com)
2. 下層 DNS 設定 (dns.wow.orz.com)
3. 子網域 Web Server (www.wow.orz.com)


## 1. 上層 DNS 設定 (dns7.orz.com)

dns7.orz.com:

```sh
$# vim /var/named/named.orz.com
# 1. 修改 SOA 部份的 Serial
# 2. 新增兩筆 RR
wow.orz.com.        IN  NS  dns.wow.orz.com.
dns.wow.orz.com.    IN  A   192.168.124.102

$# systemctl restart named
```

單純到很哭邀


## 2. 下層 DNS 設定 (dns.wow.orz.com)

dns.wow.orz.com:

```sh
$# vim /etc/named.conf
zone "wow.orz.com" IN {
        type    master;
        file    "named.wow.orz.com";
};
# 只需要加入正解 zone 參數

$# vim /var/named/named.wow.orz.com
$TTL            600
@       IN      SOA     dns.wow.orz.com.        root.wow.orz.com. (
        2018122701 29 19 599 9 )
@       IN      NS      dns.wow.orz.com.    # wow.orz.com 領域的管理員
dns     IN      A       192.168.124.102     # wow.orz.com 領域的管理員
www     IN      A       192.168.124.104     # Web Server 正解

$# vim /var/named/named.192.168.124
$TTL            600
@       IN      SOA     dns.wow.orz.com.        root.wow.orz.com. (
        2018122701 29 19 599 9 )
@       IN      NS      dns.wow.orz.com.    # wow.orz.com 領域的管理員
102     IN      PTR     dns.wow.orz.com.    # wow.orz.com 領域的管理員 反解
104     IN      PTR     www.wow.orz.com.    # Web Server 反解

$# systemctl restart named
```

## 3. 子網域 Web Server (www.wow.orz.com)

www.wow.orz.com

1. 安裝完 `httpd`, 開防火牆~
2. 修改 nmcli DNS 位置如下
- IP4.DNS[1]:     192.168.124.102
- IP4.DNS[2]:     192.168.124.64
- IP4.DNS[3]:     192.168.2.115

```sh
# 弄一個假的測試網頁
$# echo '3Q3Q' > /var/www/html/index.html
$# systemctl restart httpd
$# curl http://www.wow.orz.com
3Q3Q
```

成功!!
