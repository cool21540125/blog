---
title: Mail Server - 發送信件至公網域
# subtitle: Mail Server - 發送信件至公網域
date: 2019-01-05
tags: ["mail", "dns"]
draft: false
---

![MailServer](/images/2019/01/MailServer.png)

> 這篇要架個 Mail Server, 目的是能在 `公網域` 上收發信件. 但因為本文設定未完整, 發送的信件會被視為垃圾郵件!!! 如果有知識比較健全的朋友知道這是怎麼回事再麻煩告訴我...QQ

<!--more-->

# Story

想起高中的時候, 知道 Mail Server 是個很神祕的東西

它使用上就是如此的單純, 但細部的設定好像不是那麼簡單

會去搞這個的, 若不是很強大的高高手, 肯定是個沒朋友的邊緣人

至於我是哪種, 請容許我保持沉默....

今天來架設偉大的 Mail Server 吧!!

# Prerequest

- 已經懂 [DNS - 基礎實作](/post/2018-12-25-dns_basic) 的概念
- 有個 Public IP 及 Public DNS (Mail Server 相當依賴 DNS Server)
- 懂 [Mail Server 基本運作原理](http://linux.vbird.org/linux_server/0380mail.php)
- 你的好友人數 < 10, 飯局總是最後才被邀約 or 被遺忘的那位

如果上述條件未達標, 底下別浪費您的時間了~


# Implementation

本文以 aws ec2 架設 postfix 為例

實作方向分為:

1. EIP
2. DNS Server 設定
3. Mail Server 設定
4. Security Group (Firewall)


## 1. EIP

幫你的 ec2 申請固定 IP


## 2. DNS Resource Record

Name                               | type | Value             | TTL
---------------------------------- | ---- | ----------------  | ---
tony.com.                          | MX   | 10 mail.tony.com. | 60
mail.tony.com.                     | A    | 3.112.18.154      | 60
154.18.112.3.in-addr.arpa.tony.com | PTR  | mail.tony.com.    | 60

- *MX  : `tony.com` 這個領域的郵局名稱叫做 `mail.tony.com`*
- *A   : `mail.tony.com` 的地址在 `3.112.18.154`*
- *PTR : DNS 名稱反解 (我這邊似乎有出錯)*
- *別問我 為啥 Value 裏頭會有個 10, 我不懂!*


## 3. Postfix 設定

```sh
### CentOS7 預設已經安裝並啟用 postfix 了, 所以直接改設定檔
$# postconf -e 'myhostname = mail.tony.com' # Mail Server 的 FQDN
$# postconf -e 'mydomain = tony.com'        # (不解釋)
$# postconf -e 'myorigin = $mydomain'       # 對方收到信件時, 「@」 後面的那堆 (ie: user@tony.com)
$# postconf -e 'mydestination = $mydomain'  # DNS MX 指向的位置, 一定要在這裡頭
$# postconf -e 'inet_protocols = ipv4'      # 只等候 IPv4 請求, 或用 all (IPv4 and IPv6)
$# postconf -e 'mynetworks = 127.0.0.0/8'   # 幫忙做 relay 的白名單
$# postconf -e 'relayhost = '               # 不幫忙作轉遞
$# postconf -e 'local_transport = local:$myhostname'    # (不懂...)

$# systemctl restart postfix
```


## 4. Security Group (Firewall)

### Inbound:

Type  | Protocol | Source
----- | -------- | ------------------------------
SMTP  | TCP      | `你的電腦 IP` 或是 `Any where`
IMAP  | TCP      | `你的電腦 IP` 或是 `Any where`
POP3  | TCP      | `你的電腦 IP` 或是 `Any where`

### Outbound:

Type  | Protocol | Source
----- | -------- | ------------------------------
SMTP  | TCP      | `你的電腦 IP` 或是 `Any where`


打開 Gmail, 寄信給 `root@tony.com`

就可以成功收到信囉!!


# Addition

此篇原本的目的, 是想弄個自己的 Mail Server

然後可以使用帳號密碼認證, 讓它可以像 Gmail 作收發信件(自己爽而已)

但是目前有點撞壁, 會被當成垃圾郵件, 似乎是 DNS PTR 反解設定錯誤

但我現在知識水平尚不足...

另因為還有其他東西得研究, 這邊就暫時先到這裡...

