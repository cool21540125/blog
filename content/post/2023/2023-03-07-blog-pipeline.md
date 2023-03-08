---
title: "CICD Pipeline of my Blog"
subtitle: "這篇主要是要來說明 我這個 Blog 如何實作 CICD Pipeline (全部走 AWS)"
date: 2023-03-07
tags: ["CodeBuild", "CodeDeploy", "CodePipeline", "Lambda", "CloudFront", "Route53"]
draft: true
---

架構示意圖

![hugo-blog-pipeline](/images/2023/03/hugo-blog-pipeline.drawio.png)

<!--more-->


# Abstract

CI/CD 的概念網路上太多人解說了, 就不多說

那為啥我會選擇用 AWS CI/CD 解決方案呢?

因為最近開始摸 AWS 服務, 開始考它的認證... 於是從原本的 GitlabCI + CloudFlare 搬過來

因此並不是 AWS 高大上....


# AWS Services

為啥要搞得像上面那張圖那樣那麼複雜?

GitlabCI 不好嗎? 他很棒!! 不過 AWS 把許多服務盡可能拆解成 '功能單一'

一開始將 Source Code(我使用 Hugo) push 到 Git Repository(我使用 CodeCommit)


## CodeBuild

CodeBuild 會因為觸發了 CodeCommit main Branch push Event, 便開始他的建置流程~

CodeBuild 預設會去找 `buildspec.yml` (類似於 `.gitlab-ci.yml`)

```yaml
version: 0.2

phases:
  install: 
    runtime-versions:
      python: 3.9
    commands:
      - echo "------ Installing hugo ------"
      - curl -L -o hugo.deb https://github.com/gohugoio/hugo/releases/download/v0.110.0/hugo_0.110.0_linux-amd64.deb
      - dpkg -i hugo.deb
  pre_build:
    commands:
      - echo "--- submodules ------------"
      - git submodule init
      - git submodule update --recursive
      - echo "==========================="
      - echo "In pre_build phase.."
      - echo "Current directory is ${CODEBUILD_SRC_DIR}"
      - echo "****** prd URL ******"
      - echo "$(head -n 1 config.toml)"
      - echo "==========================="
  build:
    commands:
      - echo "-----------------"
      - hugo -v
      - ls -alh
artifacts:
  files:
    - "**/*"
  base-directory: public
```

首先, 有人一定會覺得奇怪, 為啥我要用 python image(Debin based) 來做 build artifacts??

首先, 我需要的 image 裡面最好是要有 `hugo` 及 `git`

這個 image 只需要下載 hugo binary 即可 build artifacts

此外我還需要做 pull submodule(也就是我的 templates), 因此才需要 git

我不打算把 template 也混雜到我的 Blog 之中

`hugo -v` 會將 artifacts 產出到預設的 `/public/` 裏頭

Artifacts 我把它們通通丟到 S3


## S3

為了要讓 CodeBuild 放置 Artifacts 到 S3, 需要配置相應的 IAM Role 給 CodeBuild

![code-build-service-role](/images/2023/03/CodeBuildServiceRole.png)

藉由 AWS Console 建立 CodeBuild 時, 會自動幫忙創建該 Role (但建議自行命名, 方便將來管理)


## CodeDeploy



## CodePipeline



## Lambda



## S3



## CloudFront



## Route 53



## Certificate Manager



# Conslusion



