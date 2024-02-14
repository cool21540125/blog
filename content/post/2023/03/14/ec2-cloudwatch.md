---
title: "CloudWatch 監控 EC2 客製化指標"
subtitle: "某家公司的 AWS 面試考題"
date: 2023-03-14
tags: ["EC2", "CloudWatch", "ALB"]
draft: false
---

![alb-ec2-cw.png](/images/2023/03/alb-ec2-cw.png)

<!--more-->


# Abstract

最近面試, 有家公司要我做的一個 Lab 如上圖所示 (我有稍微修改了題目要求~)

需要開兩台 EC2, 上頭跑 Nginx, 然後前面要有 ALB 來將流量導入到可正常訪問的節點

而 EC2 上頭需要設定監控:

- EC2 的 CPU Usage > 80% 需要 restart
- EC2 的 Disk Usage > 50% 需要 alarm


# Solution

先稍微分析一下 AWS Solution 需要動到底下這些 AWS Resources:

1. EC2 Instance
2. Application Load Balancer
3. Target Group
4. Security Groups
5. IAM Role
6. CloudWatch Metrics
7. CloudWatch Alarms


## 1. EC2 Instance

首先, 開啟 2 台 EC2 Instances 以後, 上頭安裝 Nginx 並且啟動他們

就....懶得細說了

記得把 2 台 EC2 訪問到的 Nginx 改一下網頁內容, 讓兩台有所差異(後面才比較好驗收)


## 2. Application Load Balancer, ALB

建立一個 ALB, 因為需要讓全世界訪問, 因此需要選擇 Internet-facing.

而 ALB 座落的 VPC, 需要與 EC2 位於同樣地方, 而基於 HA 考量, 起碼需要選擇 2 個 AZs

而且這兩個 AZ 需要能夠 cover 剛剛建立的 2 台 EC2 Instances

ALB 使用的 Security Group, 需要允許 來自任何地方的 HTTP request

Listeners and routing 方面, 則是在 ALB 上頭設定他的路由規則

現在題目要求的很清楚, 收到 HTTP Request, 則要轉發給背後的 EC2 上頭的 Nginx

Forward to 需要填上 `等下後面會建立的 Target Group`

之後就把 ALB 建立起來吧

NOTE: ALB 的使用費用, 如果還在 Free tier 的話, 一個帳號可以免費建一個, 超過的話得課金


## 3. Target Group

Target Group 是個怎樣的概念呢~

因為我們知道 ALB 本身的主要功能之一, 便是 `負載均衡`

因此這個 Group 裡頭的東西基本上是一樣的 (壞掉了就是可以捨棄了的意思)

而此 Target Group 裡頭放的就是 EC2 Instances, 因此 `target type` 要選擇 `Instances`

Protocol 及 Port 則是 `HTTP` 及 `80`

VPC 則與 EC2 及 ALB 一樣

Protocol version 不用鳥他.... HTTP1 即可

**Health checks** 則會是概念重點~

我們知道 ALB 會把流量送往後端 `健康的節點`

而 Target Group 裏頭會有個 check 機制

像是為了避免 **流量跑到無法提供服務的節點**

![tg-health-check](/images/2023/03/tg-health-check.png)

直接依照上圖預設即可. 如果 Health check 需要檢查某個 `API Endpoint`

再去異動 `Health check path`. 其餘的時間頻率及門檻自行斟酌, 完成後 Next

上面便已完成 Create Target Group 的動作

之後再把 EC2 Instances 依照下圖 `註冊` 到 Target Group (為了省錢... 我只開一台 EC2)

![tg-register-targets](/images/2023/03/tg-register-targets.png)

看到 EC2 Instances 有出現在 `Review targets` 以後, 點選 `Create target group` 即可完成


## 4. Security Groups

回頭看一下架構圖~

基於各種考量, 我們應該讓用戶去訪問 ALB (防火牆需要設定 Allow all HTTP)

而躲在 ALB 背後的 EC2 不應該對外 (防火牆需要設定 須透過上面設定的防火牆 才能連入)

![sg-alb-sg-ec2](/images/2023/03/sg-alb-sg-ec2.png)

(重點是上頭右下角的 source)

也就是說, 訪問 EC2 的 HTTP 流量, 只能由 `sg-0d65ac04a4433602` 近來


## 5. IAM Role

因為我們稍後要在 EC2 Instances 上頭安裝 CloudWatch Agent

啟動 CloudWatch Agent 以後, 需要讓 EC2 能夠寫入 log 到 CloudWatch

因此需要 create 相關的 IAM Role, 並賦予給 EC2

![ec2-iam-cw.png](/images/2023/03/ec2-iam-cw.png)

之後再把 IAM Role 塞給 EC2~

![ec2-security-iam.png](/images/2023/03/ec2-security-iam.png)

替換成剛剛建好的 IAM Role 


## 6. CloudWatch Metrics

安裝 CloudWatch 可自行上網爬~

我有把指令寫在 [我的 Github](https://github.com/cool21540125/documentation-notes/blob/master/linux/install/installAmazonLinux2.md#install-cloudwatch-agent---deprecated)

`CloudWatch Agent`(OLD) 與 `unified CloudWatch agent`(NEW)

不過因為是考試.... 符合要求的前提下就隨便吧= =

安裝過程 [我參考了這個 YT](https://www.youtube.com/watch?v=1Ta1PMgMie0)

補充說明一下, CloudWatch Agent 不像是大多數 Linux 服務, 安裝完成後, 直接 `systemctl` 給他 start 及 enable

而是需要使用它自己的 CLI, 餵給它 `CloudWatch Agent Config(好像又稱為 Schema definition)` 才能啟動

再者需要留意的是, 如同 YT 提到的, 最後提供 config 的方式是來自 SSM 的話

則需要將前一個步驟的 `CloudWatchAgentServerPolicy` 替換成 `CloudWatchAgentAdminPolicy`

(這樣才能讓 EC2 有權限去訪問 SSM)

完成以後, CloudWatch > All metrics 就可以看到新鮮的 metrics(預設會搜集 Disk Usage)

![cloudwatch-metrics.png](/images/2023/03/cloudwatch-metrics.png)


## 7. CloudWatch Alarms

### 7a. CPU

進入 AWS CloudWatch > Alarms > All alarms > Create alarm > select metric

EC2 > Per-Instance Metrics > CPUUtilization (善用 ctrl+f) > (勾選你要監控的 metrics) > Select metric

![ec2-cw-alarm-cpu.png](/images/2023/03/ec2-cw-alarm-cpu.png)

底下的重點在於, 觸發門檻值以後, 需要做必要的 `EC2 action` > `Reboot this instance`

而下圖的上半部, 則是看有沒有需要發送通知到哪些地方, 需要的話再來研究吧

![ec2-cw-alarm-cpu-reboot.png](/images/2023/03/ec2-cw-alarm-cpu-reboot.png)

然後後面沒啥重要的... 最後的步驟就只是讓你幫 alarm 訂的名字

以及觸發 alarm 的時候, 希望看起來長怎樣 的外觀自訂


### 7b. Disk Usage

同上 Create Alarm > CWAgent(因為 Disk Usage 屬於 CloudWatch 蒐錄的, 不屬於原本 EC2 原有監控範圍) > 

![ec2-cw-alarm-disk.png](/images/2023/03/ec2-cw-alarm-disk.png)

`Specify metric and conditions` 這一頁沒難度(跳過)

然後找到我們要設定門檻讓他 alarm 的 metric, 後面動作很簡單... 就不說了

![ec2-cw-alarm-disk-alarm.png](/images/2023/03/ec2-cw-alarm-disk-alarm.png)

這個的意思是, 達到上一部所設定的門檻後, `CloudWatch Alarm` 會發送 message 到 `quiz-2023` 這個 SNS Topic

此外在設定一個訂閱對象~

完成後需要先去收信(確認說你同意這個訂閱), 之後就開始收告警信吧


## Final

最後就是搞破壞啦~~

直接連到其中一台 EC2

搞硬碟 (產生一個 5G 的檔案)

`dd if=/dev/zero of=/tmp/big_file bs=1M count=5000` (視情境改數字)

然後看看告警有沒有跳出來 (有沒有收到告警信)

搞 CPU (讓 CPU 跑一輪計算)

`head -n 5000000 /dev/urandom | md5sum` (可自行改數字)

(t2.mirco 大概跑 9 秒, 但確實可以讓 CPU 飆高一下)

數字記得改大一點, 我們需要確認~ CPU 連續飆高 > 50% 而且持續一段時間, 是否會觸發 Reboot

最後最後, 再去訪問 ALB 上頭的 DNS name, ex: `quiz-lb-331337451.eu-west-2.elb.amazonaws.com`

多按幾次重新整理, 你會發現 ALB 會用輪詢的方式, 將流量依次發給不同台後端

而如果剛剛提到的 CPU 飆高的 alarm 被觸發了, EC2 reboot, 此時 ALB 只會把流量發送到 能正常提供服務的機器


# Conclusion

修改 EC2 的 Security Group 那邊有個 AWS 的天坑...

原本可能是 allow 80 from 0.0.0.0 要改成 allow 80 from SG1

這個步驟無法直接使用修改的方式進行

需要把原本舊有的 rule 砍掉, 再建立新 rule 才行 (需要實際操作才知道這在說啥)

配置 ALB 及 CloudWatch Agent 那一段還蠻麻煩的=.=

哪天心血來潮再弄個 Ansible 或是 IaC 的方式來把它處理掉好了...


## What I think

我覺得比較可惜的是, 公司在面試時比較不適合出這樣類型的考題

這類型考題比較適合在面試者答應面試後

公司給對方做的 small lab, 面試時直接交作業(或是討論)

又或者, 可以改成另一種測驗提問方式, 例如說:

> 公司都在 EC2 上頭部署服務, 而服務時常不可靠, 該如何優化?

然後互動方式很自然而然的, 就會提到 ASG 註冊 Instances 的細節, Load Balancer 如何做分流, Security Group 如何配置, Instance 及 Service 該如何做監控及災難的因應等等

除非團隊的目標是, 要找出對 AWS 操作一直都很熟悉的人, 不然這樣很難鑑別一個人適不適任
