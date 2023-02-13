---
title: Unix like - Shebang Line
date: 2020-03-10T00:00:00+08:00
tags: ["Linux", "CentOS7"]
draft: false
---

```py
#!/usr/bin/python
# 後續代碼
```

第一行, 稱之為 `shebang line`, 至於他在幹嘛? 進來看看唄

<!--more-->

## 直接看範例

假設有個檔案放在 `/home/tony/say_hello.py`

```py
#!/usr/bin/python
print 'Hello'
```

裡頭的第一行, 宣告了 `/home/tony/say_hello.py` 這個檔案的 **預設執行程式**

你懂 python 以及 linux 的話, 你一定看得懂下面這句

```bash
$ ls -l
-rw-r--r--   1 tony  staff    32  3  9 23:35 say_hello.py

# 使用 python 執行 say_hello.py
$ python say_hello.py
Hello
```

除了上述的方式執行以外, 你還可以透過下列方式來執行此腳本

```bash
$ chmod u+x say_hello.py
$ ls -l
-rwxr--r--   1 tony  staff    32  3  9 23:35 say_hello.py
#  ↑ 讓此腳本, 可被擁有者執行

# 使用檔案內的 shebang line(如果有定義的話), 執行此腳本
$ ./say_hello.py
Hello
```

再來看另一個範例

假設我們在 `/$HOME/demo_shebang/` 裡頭建立了 python3 虛擬環境...

```bash
$ cd ~
$ mkdir demo_shebang
$ cd demo_shebang
$ python3 -m venv venv
$ source venv/bin/activate

(venv)$ which python
/Users/tony/demo_shebang/venv/bin/python

(venv)$ vim say_hi.py
# ----- 內容如下 -----
#!/Users/tony/demo_shebang/venv/bin/python
print('This is python3 in virtual environment')
# ----- 內容如上 -----

# 執行方式1 - 需要進入此虛擬環境
(venv)$ python say_hi.py
This is python3 in virtual environment

# 執行方式2 - 使用絕對路徑方式
$ /Users/tony/demo_shebang/venv/bin/python say_hi.py
This is python3 in virtual environment

# 執行方式3 - 使用 shebang line 定義的方式來執行
$ chmod u+x say_hi.py
$ ./say_hi.py
This is python3 in virtual environment
```

看到這或許你有一點點感覺了

再來個 shell script 的範例

```bash
$ cd ~
$ vim demo_shell.sh
# ----- 內容如下 -----
#!/bin/bash
echo "$(whoami)" "$(whoami)" No 1
# ----- 內容如上 -----

# 執行方式1
$ bash demo_shell.sh
tony tony No 1

# 執行方式2 - 使用 預設執行程式(shebang line)
$ chmod u+x demo_shell.sh
$ ./demo_shell.sh
tony tony No 1
```

以上舉了三個範例, 應該懂了吧!!

如果哪天看到同事網路上超人家腳本, 明明你們用的是純 python3, 但他卻這樣超...

```py
#!/usr/bin/python
# 其他程式...(略)...
```

請從他後腦勺給他巴下去

寫第一行根本是沒有必要的, 而且嚴謹來說是錯誤的寫法


## 所以 shebang line 好處是?

自己想想囉, 你們公司可能會寫一堆 python3, shell script, 甚至其他直譯語言的腳本

你只要定義好每個腳本自己的 shebang line

日後只要直接輸入那份腳本的路徑就可以直接執行了


## 後記

shebang line 要放在第一行, 如果不寫的話, 也不會有錯

不要再亂超人家 Code 而不知道在超殺毀了

---