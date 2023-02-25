---
title: "關於 syntaxhighlighting"
subtitle: 語法高亮的一些備註...
date: 2019-11-12T01:10:00+08:00
tags: ["highlight"]
draft: true
---

`本文沒有任何參考價值.` 這只是紀錄自己學習 Syntax High Light 的一些使用過程...

<!--more-->

{{< youtube RvkpMRKIFLQ >}}

---

{{< highlight html >}}
<section id="main">
  <div>
   <h1 id="title">{{ .Title }}</h1>
    {{ range .Pages }}
        {{ .Render "summary"}}
    {{ end }}
  </div>
</section>
{{< /highlight >}}

---

{{< gist spf13 7896402 >}}

---

{{< gist spf13 7896402 "img.html" >}}

---

{{< highlight LaTeX "linenos=inline">}}
\documentclass[11pt,usenames,dvipsnames]{beamer}
\usetheme{CambridgeUS}
\usecolortheme{dolphin}
{{< / highlight >}}


## Reference

- [Syntax Highlighting](https://gohugo.io/content-management/syntax-highlighting/)
- [Use Hugo’s Built-in Shortcodes](https://gohugo.io/content-management/shortcodes/)
