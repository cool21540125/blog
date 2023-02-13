---
title: "DNS - 基礎實作"
date: 2018-12-25
tags: ["dns"]
draft: false
---

![DNS-Basic](/images/2018/12/dns.png)

想在辦公室裏頭架設一個區域網路, 然後作一個實驗用的 `快取 DNS`, 怎麼搞?

<!--more-->

# Story

確保 實驗用機器(VM Machine) 及 等下要設定的 DNS Server 在同一個網段, 且可以 ping 得到彼此, 且都可以連接到公網段(ping 8.8.8.8)

- VM Machine : `192.168.124.133/24` (以下簡稱 os7)
- DNS Server : `192.168.124.64/24` (以下簡稱 dns7)

此外, 網段內原本就在使用的 DNS:

- DNS Server : `192.168.2.115` (以下簡稱 dns0)


# Prerequest

- IPv4 Routing 基本概念
- DNS 查找機制的觀念
- 2 台同網段的實驗用 VM (底下範例我使用2台 CentOS7)

*Note: 把 DNS Server 與 DNS Client 架設在同網段未必是個好主意!!*


# Implementation

實作目標:

1. 快取 DNS
2. 領域管轄 DNS

## 1. 快取 DNS

dns7:

```sh
### packages && firewall && service
$# yum install -y bind bind-chroot bind-utils
$# firewall-cmd --add-service=dns
$# systemctl start named

$# vim /etc/named.conf
options {
    listen-on port 53 { any; };     # 提供來自所有網路介面的請求作查詢
    allow-query     { any; };       # 誰可以對我作查詢
    recursion yes;                  # DNS Client 向 DNS Server 查詢的模式
    forward only;                   # 我的 DNS 僅作 forward (如此以來就不會用到「.」了)
    forwarders {                    # 設定 「forward only」後, 要前往查詢的位置
        192.168.2.115;              # 上層查找的 Name Server (區網用的 Caching DNS)
        168.95.1.1;                 # 上層查找的 Name Server (中華電信的 Caching DNS)
    };
};
# ↑ 僅節錄部分

$# systemctl restart named


### 向 dns0 詢問 google.com 的 A 紀錄
$# dig google.com A

; <<<>> DiG 9.9.4-RedHat-9.9.4-72.el7 <<<>> google.com A
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<<- opcode: QUERY, status: NOERROR, id: 54356
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1280
;; QUESTION SECTION:        # 向 DNS Server 提出的查詢
;google.com.                    IN      A

;; ANSWER SECTION:          # DNS Server 回答
google.com.             55      IN      A       216.58.200.46

;; Query time: 2 msec
;; SERVER: 192.168.2.115#53(192.168.2.115)  # 透過 dns0 來查詢到的
;; WHEN: Tue Dec 25 16:59:49 CST 2018
;; MSG SIZE  rcvd: 55


### 向 Local DNS Server(dns7) 詢問 google.com 的 A 紀錄
$# dig @localhost google.com A

; <<<>> DiG 9.9.4-RedHat-9.9.4-72.el7 <<<>> @localhost google.com A
; (2 servers found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<<- opcode: QUERY, status: NOERROR, id: 57245
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:        # 向 DNS Server 提出的查詢
;google.com.                    IN      A

;; ANSWER SECTION:          # DNS Server 回答
google.com.             299     IN      A       216.58.200.46

;; Query time: 493 msec
;; SERVER: ::1#53(::1)      # 透過 ::1 來查詢到的
;; WHEN: Tue Dec 25 17:00:46 CST 2018
;; MSG SIZE  rcvd: 55
```


os7:

```sh
### 向 dns0 藉由 dns 那台 來查詢 google.com 的 A 紀錄
$# dig google.com A

; <<<>> DiG 9.9.4-RedHat-9.9.4-61.el7 <<<>> google.com A
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<<- opcode: QUERY, status: NOERROR, id: 39201
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;google.com.                    IN      A

;; ANSWER SECTION:
google.com.             80      IN      A       216.58.200.46

;; Query time: 1 msec
;; SERVER: 192.168.124.64#53(192.168.124.64)    # 透過 dns0 來查詢到的
;; WHEN: Tue Dec 25 17:04:25 CST 2018
;; MSG SIZE  rcvd: 55


### 向 dns7 詢問, dns7 代為跑腿去問 dns0 那台來查詢 google.com 的 A 紀錄
$# dig @192.168.124.64 google.com A

; <<<>> DiG 9.9.4-RedHat-9.9.4-61.el7 <<<>> @192.168.124.64 google.com A
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<<- opcode: QUERY, status: NOERROR, id: 34288
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;google.com.                    IN      A

;; ANSWER SECTION:
google.com.             103     IN      A       216.58.200.46

;; Query time: 1 msec
;; SERVER: 192.168.124.64#53(192.168.124.64)    # 透過 dns7 來查詢到的
;; WHEN: Tue Dec 25 17:15:12 CST 2018
;; MSG SIZE  rcvd: 55
```

以上, 快取 DNS Server 完成!!

這樣有啥好處!? 我目前只知道方便管控對外連線的名稱解析... 詳情請可參考 [鳥哥DNS](http://linux.vbird.org/linux_server/0350dns.php)


## 2. 領域管轄 DNS

目的: 擁有自己的名稱領域, Ex: `tony.com`

將來我的機器們都可以註冊在這之下, 我就可以有一系列的 `mail.tony.com`, `www.tony.com`, `blog.tony.com`, ...

dns7:

```sh
$# vim /etc/named.conf
# 找到 「zone "." IN { ... }; 」下一行, 增加領域資源紀錄
zone "orz.com" IN {             # 此 DNS 來託管 「orz.com」這個領域
    type master;                # 設定此 DNS 為 master
    file "named.orz.com";       # 此領域的資源紀錄細節, 紀錄在 /var/named/named.orz.com
};

### 增加領域資源紀錄
$# vim /var/named/named.orz.com
$TTL    10      # 來查詢的 DNS 可快取的時間 (秒)
@           IN  SOA     dns7.orz.com.   root.orz.com. (     # Domain 的 管理者 dns7.orz.com. ; 信箱在 root@orz.com.
    2018122501      # Serial
    30              # Refresh
    20              # Retry
    600             # Expire
    10              # Min TTL
)
@           IN  NS      dns7.orz.com.       # @ 是 Domain 的意思; 此領域的管理者(FQDN)為 dns7.orz.com.
dns7        IN  A       192.168.124.64      # dns7(hostname) 這台電腦位於 192.168.124.64
os7         IN  A       192.168.124.133     # os7(hostname)  這台電腦位於 192.168.124.133
master      IN  CNAME   os7.orz.com.        # master(Canonical name) 這別名是指 os7

# 修改完組態之後, 重啟 Server, 沒打錯字應該就沒問題啦!!
$# systemctl restart named

##### --------------------- 好了, 以上把 DNS 正解的部分搞定了! ---------------------
##### 底下要開始做反解~ 如果要架設 Validate Mail Server, 則這是必須的~

### 設定主檔
$# vim /etc/named.conf
# 在 「zone "orz.com" IN { ... };」 底下, 再新增一筆資源紀錄
zone "124.168.192.in-addr.arpa" IN {
    type    master;
    file    "named.192.168.124";            # 資源紀錄資料庫位於 /var/named/named.192.168.124
};

### 反解資源紀錄
$# vim /var/named/named.192.168.124
$TTL    10
@           IN  SOA     dns7.orz.com.   root.orz.com. (
    2018122502          # Serial 如果有作成 master/slave 架構, 記得更新版號
    30
    20
    600
    10
)
@           IN  NS      dns7.orz.com.
64          IN  PTR     dns7.orz.com.   # A 紀錄改為 PTR
133         IN  PTR     os7.orz.com.    # A 紀錄改為 PTR
# 以上, 幾乎都與 「/var/named/named.orz.com」一樣, 但僅把 A 紀錄, 改成 PTR 紀錄
# 另外, CNAME 別設定反解, 總之, FQDN01->IP 然後 IP-> FQDN02, FQDN01 == FQDN02, 則表示反解成功

$# systemctl restart named
# 鳥哥有說, 如果 service 可以正常啟動, 未必表示有成功執行, 保險一點, 去檢查 Log 吧

$# vim /var/log/messages
Dec 25 19:45:57 dns named[47919]: loading configuration from '/etc/named.conf'
# 中間 PASS 30 多行...
Dec 25 19:45:57 dns named[47919]: zone 124.168.192.in-addr.arpa/IN: loaded serial 2018122502Dec 25 19:45:57 dns named[47919]: zone
Dec 25 19:45:57 dns named[47919]: zone orz.com/IN: loaded serial 2018122502
# 上面兩行, 表示有分別載入 124.168.192.in-addr.arpa 及 orz.com 的資源紀錄資料庫
# 後面 PASS...
```

os7:

```sh
### 客戶端反查
$# dig -x 192.168.124.133

; <<<>> DiG 9.9.4-RedHat-9.9.4-61.el7 <<<>> -x 192.168.124.133
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<<- opcode: QUERY, status: NOERROR, id: 17666
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;133.124.168.192.in-addr.arpa.  IN      PTR

;; ANSWER SECTION:
133.124.168.192.in-addr.arpa. 10 IN     PTR     os7.orz.com.    # 查到自己這台的 PTR

;; AUTHORITY SECTION:
124.168.192.in-addr.arpa. 10    IN      NS      dns7.orz.com.

;; ADDITIONAL SECTION:
dns7.orz.com.           10      IN      A       192.168.124.64

;; Query time: 10 msec
;; SERVER: 192.168.124.64#53(192.168.124.64)    # 由 dns7 回應
;; WHEN: Tue Dec 25 20:44:27 CST 2018
;; MSG SIZE  rcvd: 117
```

之後不管是 dns7 或是 os7, 都可以經由 dns7 來詢問到 `dns7.orz.com`, `os7.orz.com`, `master.orz.com`

領域管轄 DNS, 完成!!
