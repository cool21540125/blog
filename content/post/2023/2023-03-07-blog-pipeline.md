---
title: "CICD Pipeline of my Blog"
date: 2023-03-07
tags: ["CodeBuild", "CodeDeploy", "CodePipeline", "Lambda", "CloudFront", "Route53", "ACM"]
draft: false
---

架構示意圖

![hugo-blog-pipeline](/images/2023/03/hugo-blog-pipeline.drawio.png)

<!--more-->


# Abstract

CI/CD 的概念網路上太多人解說了, 就不多說

那為啥我會選擇用 AWS CI/CD 解決方案呢?

因為最近開始摸 AWS 服務, 開始考它的認證... 於是從原本的 GitlabCI + CloudFlare 搬過來

因此並不是 AWS 高大上....

> 免責聲明: 這篇並不是教學文件!! 裡面的說明會省略很多很多東西~~ 這頂多算是我的心得而已. 如果要找學習來源, 請洽其他地方....


# AWS Solution

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

藉由 AWS Console 建立 CodeBuild 時, 會自動幫忙創建該 Role


## CodeDeploy

我承認我自己做的 Pipeline 可能哪邊有問題

其實靜態文檔根本不需要用到 CodeDeploy... 可藉由 CodeBuild 的 Artifacts 來處理

然而我目前還不曉得為啥 CodePipeline 觸發 CodeBuild 時, Artifacts 並不會上到 S3...

因此這邊做了個假的 Deploy 階段, 如下圖

![code-build-service-role](/images/2023/03/blog-weird-pipeline01.png)

內部配置如下

![code-build-service-role](/images/2023/03/blog-weird-pipeline02.png)

這邊我做了個 "不必要的多餘" 步驟, 來讓 CodePipeline 能夠確實地將 Artifacts 上傳到 S3....

(日後再研究看是怎麼回事)


## CodePipeline

用來串整個 CICD Pipeline 的主要流程

前面已經貼過圖了, 這邊就不囉唆

然而, 既然走 AWS 的線路, 靜態文件的 Source 是 S3 (更新完了)

後續動作就是清除緩存了


## Lambda

很遺憾的事情是, 至今(2023Q1) CodePipeline 還沒有整合 CloudFront...

所以得透過 Lambda 來執行清除緩存, 底下藉由 Python SDK 來實作

```py
import json
import boto3

code_pipeline = boto3.client("codepipeline")
cloud_front = boto3.client("cloudfront")

def lambda_handler(event, context):
    job_id = event["CodePipeline.job"]["id"]
    try:
        user_params = json.loads(
            event["CodePipeline.job"]
                 ["data"]
                 ["actionConfiguration"]
                 ["configuration"]
                 ["UserParameters"]
        )
        dist_id = user_params["distributionId"]
        obj_path = user_params["objectPaths"]
        cloud_front.create_invalidation(
            DistributionId=dist_id,
            InvalidationBatch={
                "Paths": {
                    "Quantity": len(obj_path),
                    "Items": obj_path,
                },
                "CallerReference": job_id,
            },
        )
    except Exception as e:
        code_pipeline.put_job_failure_result(
            jobId=job_id,
            failureDetails={
                "type": "JobFailed",
                "message": str(e),
            },
        )
    else:
        code_pipeline.put_job_success_result(
            jobId=job_id,
        )
```

而此 Lambda 必須要有能夠具備底下動作的 Execution Role

```jsonc
{
  "Version": "2012-10-17",
    "Statement": [
      // 略...
        {
          "Effect": "Allow",
            "Action": [
              "codepipeline:PutJobFailureResult",
                "codepipeline:PutJobSuccessResult",
                "cloudfront:CreateInvalidation"
            ],
            "Resource": "*"
        }
    ]
}
```

如此才能讓 Lambda 去操作 CloudFront

![CodePipelineCreateInvalidation](/images/2023/03/pipeline-invalidation.png)

而紅紅的 `distributionId` 又是什麼呢? 我們先來看看 S3


## S3

因為我的域名為 `blog.tonychoucc.com`

因為偷懶, 並沒打算走 OAI, OAC...

因此直接將 S3 開 publicly access (請確保沒有把重要東西上傳)

將此 S3 設定 `website hosting`, 並且賦予必要的 Bucket Policy:

![BlogBucketPolicy](/images/2023/03/blogBucketPolicy.png)

至於 BucketName 能否與 DomainName 不一樣呢..... 不想惹麻煩的話, 設定一樣吧

而此 S3 就是 CDN 的 origin 了, 接著繼續看 CDN(CloudFront) 的部分


## CloudFront

Create distribution 的時候, `Origin domain` 選擇 S3

`Default cache behavior`, `Function associations` 留預設即可

如果想要全部走 HTTPS, 記得修改 `Viewer protocol policy` 以及 `Custom SSL certificate`(等下會提到)

`Settings` 裡頭的 `Alternate domain name (CNAME)`, 輸入到時候解析要訪問的域名

ex: `blog.tonychoucc.com`


## Certificate Manager

服務如其名, 不過唯一讓我最訝異的是, 要把域名證書放到 `us-east-1`, 才能讓 CloudFront 使用

這大概是唯一的坑了吧!!

再者, AWS ACM 也支援 wild-card domain

![blogACM](/images/2023/03/blogACM.png)

將來 ACM 就直接幫忙託管證書了


## Route 53

最後的解析, 怎麼用 Route 53 自己查吧~

如果要走 CloudFront, 直接設定一筆 A record

`blog.tonychoucc.com` A (alias) `DISTRIBUTION_ID`

如果不打算走 CDN

`blog.tonychoucc.com` A (alias) `S3(要設定為 website hosting)` 


# Conslusion

之前使用 Gitlab CI 及 CloudFlare CDN... 搬過來 AWS 暫時沒辦法適應

~~學習障礙大增, 要不是為了考試做環境炫耀自己也有在用 AWS, 誰會想用這鳥東西~~

然而仍有幾個地方可能要優化, 像是 CloudFront 回源的時候, 應該要透過 OAC 或 OAI

而不是讓他直接 Public Access 回 S3

再者, 如上面所說的, CodeBuild 單獨執行可以成功更新 Artifacts

然而藉由 CodePipeline 所觸發執行的 CodeBuild, 雖說看起來正常跑完, Log 也沒毛病

但偏偏 Artifacts 卻無動於衷... 這個可能還有得讓我燒腦了
