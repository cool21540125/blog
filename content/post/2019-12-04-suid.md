+++
title = "Linux 檔案特殊權限 - suid"
date = 2019-12-04
tags = ["linux", "permission", "Go"]
draft = false
thumbnail = "images/2019/suid-passwd.png"
+++

常常看到某個檔案明明可以執行, 但是執行下去之後卻看到 `Permission denied`

但是我明明具有 x 的權限阿!?  若有此問題, 看看這篇吧!!

<!--more-->

## Prerequest

這邊使用 go 語言, 撰寫一支非常鳥的程式碼, 功能就是, 把一個檔案寫入 `/run/f1`

```go
package main

import (
        "fmt"
        "io/ioutil"
        "os/user"
)

func main() {
        d1 := []byte("Hello\n")
        err := ioutil.WriteFile("/run/f1", d1, 0644)
        user, err := user.Current()
        if err != nil {
                fmt.Println("我是 " + user.Name + ". 資料寫入到 /run/f1 發生錯誤!!")
        } else {
                fmt.Println("我是 " + user.Name + ". 資料已寫入 /run/f1")
        }
}
```

把腳本編譯之後, 丟到 `/bin/write_file_to_run`

或者

可以直接[下載此腳本](https://gitlab.com/cool21540125/cool21540125.gitlab.io/blob/master/attachs/write_file_to_run)

## Start

我們先來看看 `/run` 這個地方, 基本上他只是目前記憶體裡的資料罷了... ~~隨意搞破壞吧~~

這邊就不囉嗦, 直接看

```bash
$ ls -ld /run
drwxr-xr-x. 47 root root 1400 Nov 30 02:54 /run
#       ↑ 其他使用者不具備 w 權限
```

現在來執行看看

```bash
(root) $ /bin/write_file_to_run
我是 root. 資料已寫入 /run/f1

(root) $ ls -l /run/f1
-rw-r--r--. 1 root root 6 Nov 30 03:21 /run/f1
```

但如果你切換成其他使用者...

```bash
(tony) $ /bin/write_file_to_run
我是 tony. 資料寫入 /run/f1 發生錯誤!!
```

原因就是 `/run` 雖說阿貓阿狗們都可以進來, 但是並不代表大家可以在裡面 新增/修改 檔案

所以有必要做一些權限上的調整~ 好讓 **執行此程式的人, 資格都晉升成檔案擁有者的地位**

```bash
(root) $ chmod u+s /bin/write_file_to_run
(root) $ ls -l /bin/write_file_to_run
-rwsr-xr-x. 1 root root 2099213 Nov 30 03:36 /bin/write_file_to_run
#  ↑     ↑     ↑
#  |     雖然擁有者是 root, 但是其他人可以執行
#  |
#  一旦執行之後, 目前使用者 晉升為此 檔案擁有者 的地位

# 如此一來, 就可以正常執行了~
(tony) $ /bin/write_file_to_run
我是 tony. 資料已寫入 /run/f1
```

比較特別的就是那個 `s` 了.

這邊不多做介紹, 相信鳥哥已經寫得相當清楚了, 有興趣的人再去拜讀吧.

# Reference

- [鳥哥 - Linux 檔案與目錄管理 - SUID](http://linux.vbird.org/linux_basic/0220filemanager.php#suid)
- [Go by Example: Writing Files](https://gobyexample.com/writing-files)