---
title: DNS - master/slave 架構
# subtitle: DNS - master/slave 架構
date: 2018-12-26
tags: ["dns"]
draft: false
---

![DNS-MA](/images/2018/12/dns_ma.png)

生意越做越大, 發現全世界都在問 `tonychoucc.com` 在哪裡了, 一台 DNS 太過勞碌, 需要多一點人手, 那就來弄個 DNS master/slave 架構吧~

<!--more-->

# Story

延續 [DNS - 基礎實作](/post/2018-12-25-dns_basic) 這篇, 希望能增加 2 個 slave, 好讓名稱查詢的任務不要太過集中

- DNS Slave1 : `192.168.124.102/24` (以下簡稱 slave1)
- DNS Slave2 : `192.168.124.104/24` (以下簡稱 slave2)
- DNS Master : `192.168.124.64/64`  (以下簡稱 dns7)
- DNS Client : `192.168.124.133/64` (以下簡稱 os7)


# Prerequest

- IPv4 Routing 基本概念
- DNS 查找機制的觀念
- 4 台同網段的實驗用 VM (底下範例我使用4台 CentOS7)
- 如果你跟我一樣適用 VM 在搞, 那 RAM 要夠大啊~~~


# Implementation

1. DNS master
2. DNS slave

## 1. DNS master

dns7:

假設剛剛服務都設定好了, 那 master DNS(dns7) 只需要作作修改就可以了

```sh
$# vim /etc/named.conf
zone "orz.com" IN {
    type master;
    file "named.orz.com";
    allow-transfer {
        192.168.124.102;    # 允許 slave1 從 master 這邊拿 RR 正解檔
        192.168.124.104;    # 允許 slave1 從 master 這邊拿 RR 反解檔
    };
};

zone "124.168.192.in-addr.arpa" IN {
    type master;
    file "named.192.168.124";
        allow-transfer {
        192.168.124.102;    # 允許 slave1 從 master 這邊拿 RR 正解檔
        192.168.124.104;    # 允許 slave1 從 master 這邊拿 RR 反解檔
    };
};
# 修改上面的部份即可

$# vim /var/named/named.orz.com
# 1. 修改 SOA 裡面的 Serial 部份(起碼要比之前的序號大)
# 2. 新增底下 4 筆資料
@           IN  NS      slave1.orz.com.
slave1      IN  A       192.168.124.102
@           IN  NS      slave2.orz.com.
slave2      IN  A       192.168.124.104

$# vim /var/named/named.192.168.124
# 1. 修改 SOA 裡面的 Serial 部份(起碼要比之前的序號大)
# 2. 新增底下 4 筆資料
@           IN  NS      slave1.orz.com.
102         IN  PTR     slave1.orz.com.
@           IN  NS      slave2.orz.com.
104         IN  PTR     slave2.orz.com.

$# systemctl restart named

# 然後檢查 log, 要有看到底下的東西
$# vim /var/log/messages
Dec 26 16:19:35 dns named[7100]: zone 124.168.192.in-addr.arpa/IN: sending notifies (serial 2018122603)
Dec 26 16:19:35 dns named[7100]: zone orz.com/IN: sending notifies (serial 2018122603)
# 要看到「sending notifies (serial xxxxxxxxxx)」, 最主要是 序號的部份!!
```

## 2. DNS slave

以下的動作, slave1 及 slave2 都要作

1. 安裝套件 (略)
2. 開防火牆 (略)
3. 修改設定主檔

```sh
$# scp 192.168.124.64:/etc/named.conf /etc/named.conf

$# vim /etc/named.conf
zone "orz.com" IN {
    type slave;     # DNS Slave
    file "slaves/named.orz.com";
    masters { 192.168.124.64; };    # 設定老大是誰, 注意有個 s 哦
};

zone "124.168.192.in-addr.arpa" IN {
    type slave;
    file "slaves/named.192.168.124";
    masters { 192.168.124.64; };
};
# 修改以上部份
```

4. 注意 SELinux 問題

```sh
$# ll -dZ /var/named/slaves
drwxrwx---. named named system_u:object_r:named_cache_t:s0 /var/named/slaves/
# 基本上, named 安裝時, 已經設定好此路徑下的 SELinux context 了
# 除非要換地方, 不然可不理

# 一切就緒後, 啟動服務
$# systemctl start named

# 保險一點, 檢查一下 Log, 看看 serial 有沒有跟 master 同步
$# grep 'serial 20181226.*' /var/log/messages
Dec 26 16:19:35 dns1 named[2449]: zone 124.168.192.in-addr.arpa/IN: transferred serial 2018122603
Dec 26 16:19:35 dns1 named[2449]: zone 124.168.192.in-addr.arpa/IN: sending notifies (serial 2018122603)
Dec 26 16:19:35 dns1 named[2449]: zone orz.com/IN: transferred serial 2018122603
Dec 26 16:19:35 dns1 named[2449]: zone orz.com/IN: sending notifies (serial 2018122603)
# 如果有同步到, 那就表示 DNS Slave 成功了!
```


# 後記

後續使用者就可以藉由 slave1, slave2 來作名稱解析了~

最後要注意的是, 將來 master 改完 zone file 或是 RR 之後, 一定要改 Serial 阿!!

不然 slave 不會作同步