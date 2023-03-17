---
title: "動手作 AWS VPC"
subtitle: ""
date: 2023-03-15
tags: ["VPC", "Subnet", "SecuityGroup"]
draft: false
---

本文要使用 AWS 來建立底下的架構

![VPC-hands-on.png](/images/2023/03/VPC-hands-on.png)

<!--more-->


# Murmur

很久很久以前, 如果想在 AWS 上頭建立 Resources, 第一道大魔王關卡就是得去弄個可以訪問外網的 VPC. 這把很多像我這樣的菜菜們拒於門外, 於是從某年某日開始, 每個 AWS 帳號底下的每個 Region 都會有個 `default VPC`. 任何實驗性質的 Resources, 直接塞進來就可以正常使用網路了. 

為啥要自己搞 VPC 哩? AWS 既然已經給你了 `default VPC` 了, 「免費的官方預設」不好嗎?

~~甚至有些團隊會把 prod 的環境塞在 `default VPC` 裏頭, 直接拿來用 超香的不是嗎~~

呃, 我剛剛有說什麼嗎? 

不過如果哪天服務多了, 為了做網路面的區隔, 遲早還是得面對 自幹VPC

那麼如何手動建立自己客製化的 VPC, 就是本文想要紀錄的

完成以後就可以知道, Private Subnet 與 Public Subnet 為了要與外界作互動, 需要配置那些東西


# Trivia

- 一個 Region, 只能建立 5 個 VPCs (軟性限制)
- 一個 VPC, 能建立 5 個 CIDRs
- CIDR 的切割, 只能限制在 `x.x.x.x/16 ~ x.x.x.x/28`


# Requirements

1. 團隊需要有個虛擬網路
2. 裏頭需要有 **可直接對外(公網段)** 以及 **需要透過 NAT 對外(私網段)** 的網段
3. MIS 跟你保證說, 網段內的 Resources 不會超過 200 個 Instances (也就是說, CIDR 的切分, 給 200 個 IPs 以上都可以)
4. **私網段** 的機器開放 22 port, 可藉由 **公網段** 的機器做為跳板, 使用 ssh 連入
5. **公網段** 的機器開放 80 及 22 port

那麼該怎麼用 AWS 開出上述的環境, 則是本文要說的(如同最一開始那張圖)


# Getting started...

概念流程大概是這樣的: 

- Create VPC (with CIDR)
- Create Subnets (with CIDRs)
    - PublicSubnetA `10.0.0.0/24`
    - PublicSubnetB `10.0.1.0/24`(將來擴充用)
    - PrivateSubnetA `10.0.16.0/20`
    - PrivateSubnetB `10.0.32.0/20`(將來擴充用)
- Create Internet Gateway
- Create NAT Gateway
- Create Route Table, 並將其納入上面的 Subnets 之中
- Create Security Group
- Create EC2


------------------------------------
## 1. VPC && Subnet

建立 VPC 空殼, 並且配置 CIDR, ex: `10.0.0.0/16`, 沒啥特別的...

建立 Subnets, 如下圖:

![vpc-hands-on_subnets.png](/images/2023/03/vpc-hands-on_subnets.png)

(上圖的 SubnetB 可忽略)

裏頭要留意 CIDRs 切的到不到位, 且 CIDRs 之間不要重疊!!

如果希望 Public Subnets 裏頭會自動分配一個 Public IP 的話, 則必須在此 Subnet 配置 **Enable auto-assign public IPv4 address**

---

目前完成階段如下:

![VPC-hands-on_01.png](/images/2023/03/VPC-hands-on_01.png)


------------------------------------
## 2. Internet Gateway

(如同字面上意思)

Create 完畢以後, 需要把 `Internet Gateway` 與 VPC 關聯起來

NOTE: `Internet Gateway` 與 VPC 僅能做一對一關聯

---

目前完成階段如下:

![VPC-hands-on_02.png](/images/2023/03/VPC-hands-on_02.png)


------------------------------------
## 3. NAT Gateway

`NAT Gateway` 必須放在 `Public Subnet` 裏頭~

![vpc-hands-on_natgw.png](/images/2023/03/vpc-hands-on_natgw.png)

---

目前完成階段如下:

![VPC-hands-on_03.png](/images/2023/03/VPC-hands-on_03.png)


------------------------------------
## 4. Route Table

Subnet 裏頭, 會依照 Route Table 的規則來轉發流量 (概念等同於配置 `default gateway`)


### 4-1. Public Subnet - Route Table

將未知的流量, 全部丟給 Internet Gateway

![vpc-hands-on_PublicRouteTable.png](/images/2023/03/vpc-hands-on_PublicRouteTable.png)


### 4-2. Public Subnet - Associations

將 Public Subnet 全部關聯過來~

![vpc-hands-on_PublicRouteTable-associations.png](/images/2023/03/vpc-hands-on_PublicRouteTable-associations.png)


### 4-3. Private Subnet - Route Table

將未知的流量, 全部丟給 NAT Gateway

![vpc-hands-on_privateRouteTable.png](/images/2023/03/vpc-hands-on_privateRouteTable.png)

### 4-4. Private Subnet - Associations

將 Private Subnet 全部關聯過來~

![vpc-hands-on_privateRouteTable-associations.png](/images/2023/03/vpc-hands-on_privateRouteTable-associations.png)

---

目前完成階段如下:

![VPC-hands-on_04.png](/images/2023/03/VPC-hands-on_04.png)

疑~ 等等! 上圖的 Router 是什麼挖歌? 

我思考過這個問題, 或許這只是用以區隔 Private Network 裏頭之間的流量都會藉由 Router

而如果要對外的話, 則需要一個 Internet Gateway 來作為統一對外

而這個 Router 其實我們不用去鳥它.... AWS 會幫我們處理好這個


------------------------------------
## 5. Security Group

由於計畫在 Public Subnet 與 Private Subnet 都放置一台 EC2 Instance

因此總共需要 2 個 Security Groups


### 5-1. Public SG

想來就來想走就走

![vpc-hands-on_public-sg.png](/images/2023/03/vpc-hands-on_public-sg.png)

### 5-2. Private SG

只允許由 Public Security Group 來訪問 22 port

![vpc-hands-on_private-sg.png](/images/2023/03/vpc-hands-on_private-sg.png)

---

目前完成階段如下:

![VPC-hands-on_05.png](/images/2023/03/VPC-hands-on_05.png)


------------------------------------
## 6. EC2

最後~ 開機器吧~~~


### 6-1. Public Subnet EC2

放在 Public Subnet 裏頭 (會自動 assign IPv4)

Security Group 記得套用 `soa-public` 的 Security Group

![vpc-hands-on_public-ec2.png](/images/2023/03/vpc-hands-on_public-ec2.png)


### 6-2. Private Subnet EC2

放在 Private Subnet, SG 選擇 `soa-private` 的 Security Group

![vpc-hands-on_private-ec2.png](/images/2023/03/vpc-hands-on_private-ec2.png)

下圖我們直接來實驗是否可由 Public Subnet 的 EC2 連入(把它當成 Jump Server), 再連入到 Private Subnet 的 EC2

![vpc-hands-on_access.png](/images/2023/03/vpc-hands-on_access.png)


------------------------------------
# Final

早期有個東西叫做 `NAT Instance`, 不過好像在 2020 年的時候就不再提供了, 改使用 `NAT Gateway`(需要課金)

好處是不用在自己維護一台 Instance, 也不用配置它的 Route Table & Security Group

VPC 算得上是整個 AWS 的基石~

有必要搞清楚整個網路元件之間的互動方式以及限制, 避免將來深陷不必要的泥淖當中....

最後~ 

既然要朝向偉大的 SRE 之路邁進

那麼把這架構寫成 IaC 也是將來的必要功課@@ (將來再來寫了)
