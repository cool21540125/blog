---
title: "快取機制"
subtitle: ""
date: 2024-05-05
tags: ["caching"]
draft: true
---

https://jakearchibald.com/2016/caching-best-practices/

<!-- more -->

Front-end 完成了以後, 對於靜態內容, 經常的向後端發起請求拿一堆早已經要過的東西, 是件非常沒有效率的事情, 因此, 善用 快取機制, 好處實在是太多了, 像是:
- 減少額外的請求, 加速響應, 改善使用者體驗
- 減少不必要的網路流量, 減少流量費用

比較好的 caching pattern, 則有底下 2 種:


# Pattern 1 - Immutable content + long max-age

像是對於一些 SPA 產生出來的這堆:

- main.a1eee424.css.map
- main.a1eee424.css
- 453.e5407da2.chunk.js
- main.de8c8d36.js.map

這些靜態文件的 requirement, 經常會出現在 index.html

每次 build 出來就會生成新的一批 css, js, map, ...

因此這些檔案非常適合做長期的快取:

```
Cache-Control: max-age=31536000
```


# Pattern 2 - Mutable content + always server-revalidated

另一種情況則像是:

- about.html
- root.css
- /posts
- /orders

為這一類的靜態資源配置快取, 都有可能造成 server 端資源更新了, 因而依舊拿到 old data

前端拿到後, 可以做保存供將來再繼續使用, 不過每次要使用時, 都需要問問 backend 是否有「newer data」


```
### 此並非叫前端真的不要快取, 而是每次使用時都要詢問是否有異動
Cache-Control: no-cache
```

如果要 client 真的不要快取的話, 應該用這個:

```
Cache-Control: no-store
```

在此種 Pattern 之下, Response 會使用 `ETag` 及 `Last-Modified` 兩個 Headers 來輔助