---
title: 文檔系統 - Hugo
# subtitle: 文檔系統 - Hugo
date: 2019-08-21
tags: ["Gitlab Page", "SSG"]
draft: false
---

> 曾幾何時, 寫過前端又懂後端的我們, 都有種架設自己網站的美夢, 雖說這東西是不是會有人關心並不是重點, 但有自己純手工打造的東西就是"爽". 只是要全部自幹起來, 難免花些時間, 好在有類似 Hugo 這種 SSG, 讓廣大的 IT 宅們得以實現這可悲的美夢!!... 本文使用 BeautifulHugo Theme 來作基底

<!--more-->

# Prerequests

- 安裝 hugo
- 安裝 git


# Scripts

```bash
### 建立 hugo 專案
hugo new site blog

### 建立 theme
cd blog
git init
git submodule add https://github.com/halogenica/beautifulhugo.git themes/beautifulhugo

### 製作組態 (詳 config.toml 段落)
cp themes/beautifulhugo/exampleSite/config.toml .

### 產生靜態檔案
hugo

### 本地開發測試
hugo server -D      # -D 可以把 草稿文章也列出來 (draft: true)
```


# Structure

```bash
/archetypes/        #
/content/           # 文章放裡面
    /post/              # 文章們放裡面
        /*.md               # 文章們
    _index.md               # 首頁置頂的公告
/data/              #
/layouts/           #
/resources/         #
/static/            # 靜態文件放置區
    /img                # 放自己要 po 文連結的圖片
    /favicon.ico        # favicon
/themes/            # hugo theme 放裏頭
    /beautifulhugo/     # 此文選擇的風格
        /archetypes/        #
        /data/              #
        /exampleSite/       #
            /post/              #
            _index.md           #
            /layouts/           #
            /static/            #
            config.toml         # 把這個設定主檔範本複製出去改
        /i18n/              # 多語系翻譯檔
            /en.yaml            # i18n-英文
            /zh-TW.yaml         # i18n-繁體中文, 要使用的話「DefaultContentLanguage = "zh-tw"」
        /images/            #
        /layouts/           #
        /static/            #
        .gitattributes      #
        .gitignore          #
        LICENSE             #
        README.md           #
        theme.toml          #
.gitignore          #
.gitmodules         #
config.toml         # 從 themes 複製出來要修改的主要設定檔
```


# config.toml

```toml

### Navigator
[[menu.main]]
    name = "Archives"
    weight = 1
    url = "/"

[[menu.main]]
    name = "Tags"
    weight = 2
    url = "/tags"


### 最底下的連結
[Author]
    name = "Tony Chou"
    email = "mailto:cool21540125@gmail.com"
    facebook = "profile.php?id=100000009066426&ref=bookmarks"
    stackoverflow = "users/7751061/tony-chou"
    github = "cool21540125"
    gitlab = "cool21540125"

[Params]
    useHLJS = false     # Highlight.js 程式碼區塊高量
```


# Additional

花時間聊解一番之後, 才發現世界上有種叫做 WordPress 的東西, 比 Hugo 還要接近一般人...

原來, Hugo 也是邊緣人的玩具罷了



# Reference

- [用hugo构建个人博客](https://blog.moonlightming.top/post/2018-11-29-%E4%BD%BF%E7%94%A8hugo%E6%9E%84%E5%BB%BA%E4%B8%AA%E4%BA%BA%E5%8D%9A%E5%AE%A2/)
